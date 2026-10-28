;;; gis2cad.lsp - AutoCAD / Civil 3D / Carlson-on-AutoCAD loader for the gis2cad engine.
;;; APPLOAD this file (or add it to the Startup Suite), then type GIS2CAD.
;;;   GIS2CAD   - Single / Adjoiners / Radius / Window; pick a point in the drawing (active drawing EPSG from config.json, default 6543), type
;;;               lat/lon, or type State Plane Northing/Easting; runs the engine, then entmakes the parcel + owner text at true coords.
;;;   GIS2CADSTYLE - open the label style editor (per-company label format); GIS2CAD uses the active style.
;;;   BCSBLDG   - building footprints (NC, SC, GA, VA, TN) in a window or around a selected parcel (+ buffer, default 50 ft) (also G2CBLDG).
;;;   GIS2CADBOUNDS - opens the Map Layers window (also BCSMAP, BCSBND, G2CBND): draw a state border, a county border (+ neighbors) or all counties,
;;;               in the chosen drawing coordinate system. Borders are never drawn by GIS2CAD.
;;;   GIS2CADLOAD - load an already-generated <job>.lsp from the engine's CLI (batch runs).
;;;   BCSLIC    - license: status, enter key, recheck, change counties, subscription portal, or release the seat (also BCSLICENSE, G2CLIC).
;;; Set *g2c-exe* to gis2cad.exe (PyInstaller build) or to "python -m gis2cad".
(vl-load-com)
;; *g2c-exe* is set by BIGCS.lsp (install folder\app\bigcs.bat) before this file loads.
(if (not (and (= (type *g2c-exe*) (quote STR)) (findfile *g2c-exe*)))
  (princ "\nBIGCS: APPLOAD BIGCS.lsp from the BIGCS install folder; it sets the engine path."))
(if (not *g2c-out*) (setq *g2c-out* (strcat (getenv "TEMP") "\\gis2cad_last")))

;; Directory of gis2cad.bat (*g2c-exe*) and active drawing EPSG from config.json (shared parcels/bounds setting).
(defun g2c:root (/ p i)
  (setq p *g2c-exe* i (strlen p))
  (while (and (> i 0) (/= (substr p i 1) "\\") (/= (substr p i 1) "/")) (setq i (1- i)))
  (substr p 1 i))

;; rc13 (2026-10-25): each drawing remembers its own coordinate system (xrecord BIGCS_CRS in the named object
;; dictionary, saved with the DWG). Picking a state or county never changes it; data from any state is converted into it.
(defun g2c:dwg-epsg (/ d n)
  (if (setq d (dictsearch (namedobjdict) "BIGCS_CRS")) (setq n (cdr (assoc 90 d))))
  (if (and n (> n 0)) n))
(defun g2c:dwg-epsg-put (n / x)
  (if (and n (> n 0) (/= n (g2c:dwg-epsg)))
    (progn
      (dictremove (namedobjdict) "BIGCS_CRS")
      (if (setq x (entmakex (list '(0 . "XRECORD") '(100 . "AcDbXrecord") (cons 90 n))))
        (dictadd (namedobjdict) "BIGCS_CRS" x))
      (princ (strcat "\nBIGCS: this drawing's coordinate system is EPSG " (itoa n) "."))))
  n)
;; The drawing's own EPSG, else config.json (last used), else 6543.
(defun g2c:epsg () (cond ((g2c:dwg-epsg)) ((g2c:cfg-epsg))))
;; Read the first number in a small text file (Map Layers writes <out>.crs = the EPSG used for that draw).
(defun g2c:readnum (fn / h s)
  (if (and (findfile fn) (setq h (open fn "r"))) (progn (setq s (read-line h)) (close h) (if s (atoi s)))))

(defun g2c:cfg-epsg (/ f s p n c)
  ;; Read config.json "drawing_epsg"; default 6543 (NAD83(2011) NC SP US ft). 2264 remains selectable via bounds GUI / CLI.
  (setq n 6543 f (findfile (strcat (g2c:root) "config.json")))
  (if (and f (setq f (open f "r")))
    (progn
      (while (setq s (read-line f))
        (setq p (vl-string-search "\"drawing_epsg\"" s))
        (if (and p (not (vl-string-search "drawing_epsg_note" s)))
          (progn
            (setq s (substr s (+ p 16)))
            (while (and (> (strlen s) 0)
                        (or (= (substr s 1 1) ":") (= (substr s 1 1) " ")
                            (= (substr s 1 1) "\t") (= (substr s 1 1) ",")))
              (setq s (substr s 2)))
            (setq c "")
            (while (and (> (strlen s) 0) (<= 48 (ascii (substr s 1 1)) 57))
              (setq c (strcat c (substr s 1 1)) s (substr s 2)))
            (if (/= c "") (setq n (atoi c))))))
      (close f)))
  n)

(defun g2c:epsg-s () (itoa (g2c:epsg)))

(defun g2c:shell-wait (cmd / sh rc)
  (setq sh (vlax-create-object "WScript.Shell"))
  ;; rc13: every engine run gets this drawing's coordinate system (BIGCS_DRAWING_EPSG), so data lands in the drawing's system.
  (setq rc (vlax-invoke-method sh 'Run (strcat "cmd /c \"set BIGCS_DRAWING_EPSG=" (g2c:epsg-s) "&& " cmd "\"") 0 :vlax-true))   ; outer quotes: exe paths with spaces
  (vlax-release-object sh)
  rc)

;; CAD main-frame HWND for centering Tk dialogs: no longer read through COM. IntelliCAD 12.1 (Carlson 2025)
;; printed "too few arguments :error#0" from the HWND property call even inside vl-catch-all-apply.
;; The Python side finds the CAD window itself (foreground window at launch / process name), so pass nothing.
(defun g2c:hwnd () "")

(defun g2c:ll (lbl / lat lon)
  (setq lat (getreal (strcat "\n" lbl "Latitude: ")) lon (getreal (strcat "\n" lbl "Longitude: ")))
  (if (and lat lon) (list lat lon)))

(defun g2c:loc (how lbl flag / p)
  ;; returns CLI args for one location, e.g. " --x 123 --y 456" (flag = "" or "1"/"2")
  (cond
    ((= how "LatLon")
     (if (setq p (g2c:ll lbl))
       (strcat " --lat" flag " " (rtos (car p) 2 8) " --lon" flag " " (rtos (cadr p) 2 8))))
    ((= how "StatePlane")
     (if (setq p (g2c:ne lbl))
       (strcat " --x" flag " " (rtos (cadr p) 2 4) " --y" flag " " (rtos (car p) 2 4))))
    (T
     (if (setq p (getpoint (strcat "\n" lbl "Pick a point (drawing must be in EPSG " (g2c:epsg-s) " ft): ")))
       (strcat " --x" flag " " (rtos (car p) 2 4) " --y" flag " " (rtos (cadr p) 2 4))))))

(defun g2c:ne (lbl / n e)
  ;; typed State Plane in the active drawing EPSG (US survey ft): returns (northing easting)
  (setq n (getreal (strcat "\n" lbl "Northing (EPSG " (g2c:epsg-s) " US ft): ")))
  (if n (setq e (getreal (strcat "\n" lbl "Easting (EPSG " (g2c:epsg-s) " US ft): "))))
  (if (and n e) (list n e)))

;; rc19b: echo trial lines (countdown, low-use warning, refusals) from an engine log to the command line.
;; Only lines containing "BIGCS trial" are shown; paid / beta runs never write such lines.
(defun g2c:trialmsg (log / f s)
  (if (and log (setq f (open log "r")))
    (progn (while (setq s (read-line f)) (if (wcmatch s "*BIGCS trial*") (princ (strcat "\n" (g2c:unbigcs s))))) (close f)))
  (princ))
(defun g2c:unbigcs (s) (if (wcmatch s "`[fail`] *") (setq s (substr s 8))) (if (wcmatch s "BIGCS*,Your BIGCS*") s (strcat "BIGCS: " s)))
(defun g2c:lastfail (/ f s m p)
  ;; echo the engine's [fail] reason so it shows on the command line
  (if (setq f (open (strcat *g2c-out* ".log") "r"))
    (progn
      (while (setq s (read-line f))
        (if (and (or (vl-string-search "[fail]" s) (wcmatch s "BIGCS*,Your BIGCS*,*isn't on this license*")) (not (wcmatch s "*BIGCS trial*"))) (setq m s)))
      (close f)
      (if m
        (progn
          (setq p (vl-string-search "}: " m))
          (princ (strcat "\nBIGCS: " (if p (substr m (+ p 4)) m))))))))

;; Duplicate check for every BIGCS draw (parcels, Map Layers items, buildings, job files). Plain AutoLISP (LT-safe).
;; Loads a generated .lsp, then removes each new entity that matches one already in the drawing on the same layer:
;; same type, same vertices (0.01 drawing units), same text / block name / radius. Matching geometry is the identity,
;; so items drawn before this check (no ID) are caught too. Repeats inside one run (e.g. stacked condo parcels) stay.
(defun g2c:sig (ed / n sx sy f l s q c x y)
  (setq n 0 sx 0.0 sy 0.0 s "")
  (foreach p ed
    (setq c (car p))
    (cond
      ((and (member c '(10 11)) (listp (cdr p)) (numberp (cadr p)))
       (setq x (atof (rtos (cadr p) 2 2)) y (atof (rtos (caddr p) 2 2))
             q (strcat (rtos x 2 2) "," (rtos y 2 2)) n (1+ n) sx (+ sx x) sy (+ sy y))
       (if (not f) (setq f q)) (setq l q))
      ((and (member c '(1 2 3)) (= (type (cdr p)) 'STR)) (setq s (strcat s "|" (cdr p))))
      ((and (= c 40) (numberp (cdr p))) (setq s (strcat s "|r" (rtos (cdr p) 2 3))))))
  (strcat (cdr (assoc 0 ed)) "|" (itoa n) "|" (if f f "") "|" (if l l "") "|" (rtos sx 2 2) "|" (rtos sy 2 2) s))

(defun g2c:main-p (ed) (not (member (cdr (assoc 0 ed)) '("ATTRIB" "SEQEND" "VERTEX"))))

(defun g2c:cntlay (lays m / e n)
  ;; rc12: entities already in the drawing (up to marker m) on the layers just drawn on.
  (setq e (entnext) n 0)
  (while e
    (if (member (cdr (assoc 8 (entget e))) lays) (setq n (1+ n)))
    (setq e (if (equal e m) nil (entnext e))))
  n)
(defun g2c:load-dedupe (f / m e ed new lays bk lay nd ns)
  (if (not (g2c:dwg-epsg)) (g2c:dwg-epsg-put (g2c:epsg)))   ; rc13: first data drawn -> the drawing keeps this system
  (setq m (entlast))
  (load f)
  (setq e (if m (entnext m) (entnext)) nd 0 ns 0)
  (while e
    (setq ed (entget e))
    (if (g2c:main-p ed)
      (progn (setq new (cons (cons e ed) new) lay (cdr (assoc 8 ed)))
             (if (not (member lay lays)) (setq lays (cons lay lays)))))
    (setq e (entnext e)))
  (if (and m new (> (* (float (length new)) (g2c:cntlay lays m)) 4.0e7))
    (progn (setq nd (length new) m nil)
           (princ "\nBIGCS: large drawing - duplicate check skipped (use OVERKILL if the same area was drawn twice).")))
  (if (and m new)
    (progn
      ;; signatures of the entities that were there before, on the layers just drawn on
      (setq e (entnext))
      (while e
        (setq ed (entget e) lay (cdr (assoc 8 ed)))
        (if (and (member lay lays) (g2c:main-p ed))
          (setq bk (cons (strcat lay "\t" (g2c:sig ed)) bk)))
        (setq e (if (equal e m) nil (entnext e))))
      (foreach x (reverse new)
        (if (member (strcat (cdr (assoc 8 (cdr x))) "\t" (g2c:sig (cdr x))) bk)
          (progn (entdel (car x)) (setq ns (1+ ns)))
          (setq nd (1+ nd)))))
    (setq nd (length new)))
  (princ (strcat "\nBIGCS: " (itoa nd) " drawn, " (itoa ns) " already in drawing (not drawn)."))
  (princ))

;; Address / PIN search: typed text (+ optional county; Enter = last county used in BCSBND) -> "find" CLI args.
;; Several matches -> the engine shows a pick list window. Click-pick and every other method are unchanged.
(defun g2c:find (how mode / txt cty d a)
  (setq txt (getstring T (if (= how "PIN") "\nParcel ID / PIN (exact): " "\nSite address (part is OK, e.g. 2112 MORGAN MILL): ")))
  (setq cty (getstring T "\nCounty <last used in BCSBND>: "))
  (if (and txt (/= txt ""))
    (progn
      (setq txt (vl-string-translate "\"" "'" txt))
      (setq a (strcat "find --by " (if (= how "PIN") "pid" "address") " --text \"" txt "\""
                      (if (and cty (/= cty "")) (strcat " --county \"" cty "\"") "")
                      " --mode " (strcase mode T)))
      (if (= mode "Radius")
        (progn (initget 7) (setq d (getdist "\nRadius distance in feet: "))
               (setq a (strcat a " --dist " (rtos d 2 2)))))
      a)))

(defun c:GIS2CAD (/ how mode a1 a2 d args rc f)
  (princ (strcat "\nBIGCS: coordinate system EPSG " (g2c:epsg-s) (if (g2c:dwg-epsg) " (this drawing)" " (last used)")
                 " - parcels from any state are converted into it (BCSCRS to change)."))
  (initget "Pick LatLon StatePlane Address PIN")
  (setq how (getkword "\nLocate by [Pick/LatLon/StatePlane/Address/PIN] <Pick>: "))
  (if (not how) (setq how "Pick"))
  (if (member how '("Address" "PIN"))
    (progn (initget "Single Adjoiners Radius")
           (setq mode (getkword "\nMode [Single/Adjoiners/Radius] <Single>: ")))
    (progn (initget "Single Adjoiners Radius Window")
           (setq mode (getkword "\nMode [Single/Adjoiners/Radius/Window] <Single>: "))))
  (if (not mode) (setq mode "Single"))
  (cond
    ((member how '("Address" "PIN"))
     (setq args (g2c:find how mode)))
    ((= mode "Single")
     (if (setq a1 (g2c:loc how "Inside the parcel - " "")) (setq args (strcat "point" a1))))
    ((= mode "Adjoiners")
     (if (setq a1 (g2c:loc how "Inside the subject parcel - " "")) (setq args (strcat "adjoiners" a1))))
    ((= mode "Radius")
     (if (setq a1 (g2c:loc how "Center - " ""))
       (progn (initget 7) (setq d (getdist "\nRadius distance in feet: "))
              (setq args (strcat "radius" a1 " --dist " (rtos d 2 2))))))
    ((= mode "Window")
     (if (/= how "Pick")
       (if (and (setq a1 (g2c:loc how "First corner - " "1")) (setq a2 (g2c:loc how "Opposite corner - " "2")))
         (setq args (strcat "rect" a1 a2)))
       (if (setq a1 (getpoint "\nFirst corner: "))
         (if (setq a2 (getcorner a1 "\nOpposite corner: "))
           (setq args (strcat "rect --x1 " (rtos (car a1) 2 4) " --y1 " (rtos (cadr a1) 2 4)
                              " --x2 " (rtos (car a2) 2 4) " --y2 " (rtos (cadr a2) 2 4))))))))
  (if (not args)
    (princ "\nBIGCS: cancelled.")
    (progn
      (if (/= mode "Single") (princ "\nBIGCS: querying county GIS, this can take up to a minute for big areas..."))
      (setq rc (g2c:shell-wait (strcat "\"" *g2c-exe* "\"" (if *g2c-txt* " --boundary no " " ") args " -o \"" *g2c-out* "\" > \"" *g2c-out* ".log\" 2>&1")))
      (setq f (strcat *g2c-out* ".lsp"))
      (g2c:trialmsg (strcat *g2c-out* ".log"))
      (if (findfile f)
        (progn (g2c:load-dedupe f) (vl-file-delete f))
        (progn (g2c:lastfail) (princ (strcat "\nBIGCS: no result - see " *g2c-out* ".log"))))))
  (princ))

(defun c:GIS2CADLOAD (/ f)
  (setq f (getfiled "BIGCS output" "" "lsp" 0))
  (if f (g2c:load-dedupe f))
  (princ))
;; Drawing's layer and text style names -> %TEMP%\gis2cad_dwg_tables.json for the style editor's dropdowns (nil if not written).
(defun g2c:tblnames (tb / r l n)
  (while (setq r (tblnext tb (not r)))
    (setq n (cdr (assoc 2 r)))
    (if (and n (/= n "") (not (wcmatch n "*|*,`**"))) (setq l (cons n l))))
  (reverse l))
(defun g2c:jstr (s / o i c)
  (setq o "" i 1)
  (while (<= i (strlen s))
    (setq c (substr s i 1) o (strcat o (if (or (= c "\\") (= c "\"")) (strcat "\\" c) c)) i (1+ i)))
  (strcat "\"" o "\""))
(defun g2c:jlist (l / o) (setq o "") (foreach n l (setq o (strcat o (if (= o "") "" ",") (g2c:jstr n)))) (strcat "[" o "]"))
(defun g2c:dwgtables (/ p f)
  (setq p (strcat (getenv "TEMP") "\\gis2cad_dwg_tables.json"))
  (if (setq f (open p "w"))
    (progn
      (write-line (strcat "{\"layers\":" (g2c:jlist (g2c:tblnames "LAYER")) ",\"styles\":" (g2c:jlist (g2c:tblnames "STYLE")) ",\"ltypes\":" (g2c:jlist (g2c:tblnames "LTYPE"))
                          ",\"clayer\":" (g2c:jstr (getvar "CLAYER")) ",\"textstyle\":" (g2c:jstr (getvar "TEXTSTYLE")) "}") f)
      (close f)
      p)))

(defun c:GIS2CADSTYLE (/ sh h tj)
  ;; opens the label style editor (lines, wording, name format, layers) with a live preview;
  ;; GIS2CAD always uses the style marked Active there. Passes CAD HWND so the window opens over the drawing.
  ;; Also passes this drawing's layer / text style names so the editor's layer and style fields are dropdowns.
  (setq h (g2c:hwnd))
  (setq tj (vl-catch-all-apply 'g2c:dwgtables nil))
  (if (vl-catch-all-error-p tj) (setq tj nil))
  (setq sh (vlax-create-object "WScript.Shell"))
  (vlax-invoke-method sh 'Run (if tj (strcat "cmd /c \"\"" *g2c-exe* "\" style edit" h " --dwg-tables \"" tj "\"\"")
                                     (strcat "cmd /c \"" *g2c-exe* "\" style edit" h)) 0 :vlax-false)
  (vlax-release-object sh)
  (princ "\nBIGCS: opening the label style editor...")
  (princ))

(defun c:GIS2CADBOUNDS (/ o f h)
  ;; opens the Map Layers window and waits; a Draw button writes <o>.lsp and closes the window, then we load it.
  (setq o (strcat (getenv "TEMP") "\\gis2cad_bounds"))
  (foreach x '(".lsp" ".crs") (if (findfile (strcat o x)) (vl-file-delete (strcat o x))))
  (setq h (g2c:hwnd))
  (princ (strcat "\nBIGCS: coordinate system EPSG " (g2c:epsg-s) (if (g2c:dwg-epsg) " (this drawing)" " (last used)") "."))
  (princ "\nBIGCS: Map Layers window open - pick a state/county and click a Draw button...")
  (g2c:shell-wait (strcat "\"" *g2c-exe* "\"" " bounds gui -o \"" o "\"" h " > \"" o ".log\" 2>&1"))
  (g2c:trialmsg (strcat o ".log"))
  (if (findfile (strcat o ".pick")) (g2c:pickarea o))
  (setq f (strcat o ".lsp"))
  (if (findfile f)
    (progn (g2c:dwg-epsg-put (g2c:readnum (strcat o ".crs")))   ; rc13: the system chosen in Map Layers becomes the drawing's
           (g2c:load-dedupe f) (vl-file-delete f)
           (foreach x '(".json" ".dxf") (if (findfile (strcat o x)) (vl-file-delete (strcat o x)))))
    (princ "\nBIGCS: nothing drawn (window closed or pick cancelled)."))
  (if (findfile (strcat o ".crs")) (vl-file-delete (strcat o ".crs")))
  (princ))

(defun g2c:bigmsg (log / f s m)
  ;; rc12: the engine counts before a large pull; "[confirm] <warning>" in the log = it stopped and wants a Yes.
  (if (setq f (open log "r"))
    (progn (while (setq s (read-line f)) (if (wcmatch s "`[confirm`] *") (setq m (substr s 11)))) (close f)))
  m)
(defun g2c:yesno (m / k)
  ;; Yes/No with No as the default (Enter, Esc or anything but Yes = No).
  (princ (strcat "\nBIGCS: " m))
  (initget "Yes No")
  (setq k (getkword "\nDownload anyway? [Yes/No] <No>: "))
  (= k "Yes"))
(defun g2c:area-run (cmd o / m)
  ;; Run "bounds area"; if the engine asks (large window), confirm Yes/No <No> and rerun with --yes. T = rerun declined.
  (g2c:shell-wait (strcat cmd " > \"" o ".log\" 2>&1"))
  (if (setq m (g2c:bigmsg (strcat o ".log")))
    (if (g2c:yesno m)
      (progn (princ "\nBIGCS: downloading (capped; this can take a while)...")
             (g2c:shell-wait (strcat cmd " --yes > \"" o ".log\" 2>&1")) (g2c:trialmsg (strcat o ".log")) nil)
      (progn (princ "\nBIGCS: large download cancelled. Pick a smaller area.") T))
    (progn (g2c:trialmsg (strcat o ".log")) nil)))

(defun g2c:pickarea (o / fh args k p1 p2 d e mn mx ob)
  ;; Map Layers window scope "Pick area in drawing": <o>.pick holds CLI args (--what/--state/--epsg).
  ;; Window = two corners; Point = point + buffer; Object = a parcel/polyline's extents + buffer. Default buffer 500.
  (setq fh (open (strcat o ".pick") "r") args (read-line fh)) (close fh) (vl-file-delete (strcat o ".pick"))
  (initget "Window Point Object")
  (setq k (getkword "\nBIGCS area [Window/Point/Object(parcel)] <Window>: "))
  (if (not k) (setq k "Window"))
  (cond
    ((= k "Window")
     (if (setq p1 (getpoint "\nFirst corner: ")) (setq p2 (getcorner p1 "\nOpposite corner: "))))
    ((= k "Point")
     (if (setq p1 (getpoint "\nCenter point: "))
       (progn (initget 6) (setq d (getdist p1 "\nBuffer distance in drawing units (ft) <500>: "))
              (if (not d) (setq d 500.0))
              (setq p2 (list (+ (car p1) d) (+ (cadr p1) d)) p1 (list (- (car p1) d) (- (cadr p1) d))))))
    ((= k "Object")
     (if (setq e (entsel "\nSelect the parcel line/polyline: "))
       (progn (initget 4) (setq d (getdist "\nBuffer distance in drawing units (ft) <500>: "))
              (if (not d) (setq d 500.0))
              (setq ob (vlax-ename->vla-object (car e)))
              (vla-getboundingbox ob 'mn 'mx)
              (setq mn (vlax-safearray->list mn) mx (vlax-safearray->list mx)
                    p1 (list (- (car mn) d) (- (cadr mn) d)) p2 (list (+ (car mx) d) (+ (cadr mx) d)))))))
  (if (and p1 p2)
    (progn
      (princ "\nBIGCS: querying the picked area...")
      (g2c:area-run (strcat "\"" *g2c-exe* "\"" " bounds area " args
                            " --x1 " (rtos (car p1) 2 4) " --y1 " (rtos (cadr p1) 2 4)
                            " --x2 " (rtos (car p2) 2 4) " --y2 " (rtos (cadr p2) 2 4)
                            " -o \"" o "\"") o))
    (princ "\nBIGCS: pick cancelled.")))

;; Short aliases
;; Adjoiner table: subject by Pick/LatLon/StatePlane/Address/PIN -> table at a picked point + CSV beside the drawing.
(defun c:GIS2CADADJ (/ how a1 args p rc f csv dst)
  (initget "Pick LatLon StatePlane Address PIN")
  (setq how (getkword "\nAdjoiner table - locate subject by [Pick/LatLon/StatePlane/Address/PIN] <Pick>: "))
  (if (not how) (setq how "Pick"))
  (if (member how '("Address" "PIN"))
    (setq args (g2c:find how "Adjoiners"))
    (if (setq a1 (g2c:loc how "Inside the subject parcel - " "")) (setq args (strcat "adjoiners" a1))))
  (if (and args (setq p (getpoint "\nTable top-left corner: ")))
    (progn
      (princ "\nBIGCS: querying county GIS for adjoiners...")
      (setq rc (g2c:shell-wait (strcat "\"" *g2c-exe* "\" --table " (rtos (car p) 2 4) "," (rtos (cadr p) 2 4) " " args
                                       " -o \"" *g2c-out* "_adj\" > \"" *g2c-out* "_adj.log\" 2>&1")))
      (setq f (strcat *g2c-out* "_adj.lsp") csv (strcat *g2c-out* "_adj.csv"))
      (g2c:trialmsg (strcat *g2c-out* "_adj.log"))
      (if (findfile f)
        (progn (load f) (vl-file-delete f)
               (setq dst (strcat (getvar "DWGPREFIX") (vl-filename-base (getvar "DWGNAME")) "_adjoiners.csv"))
               (if (findfile dst) (vl-file-delete dst))
               (if (vl-file-copy csv dst) (princ (strcat "\nBIGCS: CSV saved to " dst)) (princ (strcat "\nBIGCS: CSV at " csv))))
        (princ (strcat "\nBIGCS: no result - see " *g2c-out* "_adj.log"))))
    (princ "\nBIGCS: cancelled."))
  (princ))
(defun c:G2CADJ () (c:GIS2CADADJ))
(defun c:BCSADJ () (c:GIS2CADADJ))

;; Refresh: re-pull every BIGCS label (MTEXT with BIGCS_PCL xdata) by its stored PIN; update text + stamp; CSV of changes.
(defun g2c:xv (xd k / r) (foreach p xd (if (and (= (car p) 1000) (= (substr (cdr p) 1 (1+ (strlen k))) (strcat k "="))) (setq r (substr (cdr p) (+ 2 (strlen k)))))) (if r r ""))
(defun c:GIS2CADREF (/ ss i e xd fl f n rc csv dst)
  (setq ss (ssget "X" '((0 . "MTEXT") (-3 ("BIGCS_PCL")))))
  (if (not ss)
    (princ "\nBIGCS: no BIGCS labels with stored PINs in this drawing (labels inserted before this update have none).")
    (progn
      (setq fl (strcat *g2c-out* "_ref.txt") f (open fl "w") i 0 n (sslength ss))
      (while (< i n)
        (setq e (ssname ss i) xd (cdr (car (cdr (assoc -3 (entget e '("BIGCS_PCL")))))))
        (write-line (strcat (cdr (assoc 5 (entget e))) "\t" (g2c:xv xd "STATE") "\t" (g2c:xv xd "COUNTY") "\t" (g2c:xv xd "PID") "\t"
                            (g2c:xv xd "OWNER") "\t" (g2c:xv xd "DEED")) f)
        (setq i (1+ i)))
      (close f)
      (princ (strcat "\nBIGCS: refreshing " (itoa n) " label(s) from county GIS..."))
      (setq rc (g2c:shell-wait (strcat "\"" *g2c-exe* "\" refresh --list \"" fl "\" -o \"" *g2c-out* "_ref\" > \"" *g2c-out* "_ref.log\" 2>&1")))
      (g2c:trialmsg (strcat *g2c-out* "_ref.log"))
      (if (findfile (strcat *g2c-out* "_ref.lsp"))
        (progn
          (g2c:showlog (strcat *g2c-out* "_ref.log") "[changed]")
          (load (strcat *g2c-out* "_ref.lsp")) (vl-file-delete (strcat *g2c-out* "_ref.lsp"))
          (setq csv (strcat *g2c-out* "_ref.csv") dst (strcat (getvar "DWGPREFIX") (vl-filename-base (getvar "DWGNAME")) "_refresh.csv"))
          (if (findfile dst) (vl-file-delete dst))
          (if (vl-file-copy csv dst) (princ (strcat "\nBIGCS: change list saved to " dst)) (princ (strcat "\nBIGCS: change list at " csv))))
        (princ (strcat "\nBIGCS: refresh failed - see " *g2c-out* "_ref.log")))))
  (princ))
(defun g2c:showlog (fn pre / f s) (if (setq f (open fn "r")) (progn (while (setq s (read-line f)) (if (wcmatch s (strcat pre "*")) (princ (strcat "\n  " s)))) (close f))))
(defun c:G2CREF () (c:GIS2CADREF))
(defun c:BCSREF () (c:GIS2CADREF))

;; BIGCS Letters: standalone window (does not block CAD); opens the newest <drawing>_adjoiners.csv in the drawing folder.
(defun c:GIS2CADLTR (/ sh)
  (setq sh (vlax-create-object "WScript.Shell"))
  (vlax-invoke-method sh 'Run (strcat "cmd /c \"\"" *g2c-exe* "\" letters gui --folder \"" (vl-string-right-trim "\\" (getvar "DWGPREFIX")) "\"\"") 0 :vlax-false)
  (vlax-release-object sh)
  (princ "\nBIGCS: opening BIGCS Letters...")
  (princ))
(defun c:G2CLTR () (c:GIS2CADLTR))
(defun c:BCSLTR () (c:GIS2CADLTR))

;; Text only: same prompts, same label point, no parcel boundary polyline (style setting is left alone).
(defun c:GIS2CADTXT (/ *error*)
  (defun *error* (m) (setq *g2c-txt* nil) (if (not (wcmatch (strcase m) "*CANCEL*,*QUIT*")) (princ (strcat "\nBIGCS: " m))) (princ))
  (princ "\nBIGCS: TEXT ONLY - owner labels without parcel boundaries.")
  (setq *g2c-txt* T) (c:GIS2CAD) (setq *g2c-txt* nil) (princ))
(defun c:G2C () (c:GIS2CAD))
(defun c:G2CTXT () (c:GIS2CADTXT))
(defun c:G2CBND () (c:GIS2CADBOUNDS))
(defun c:G2CST () (c:GIS2CADSTYLE))
(defun c:G2CLOAD () (c:GIS2CADLOAD))
;; BIGCS product aliases (Boundary Intelligence for GIS, CAD & Survey)
(defun c:BCS () (c:GIS2CAD))
(defun c:BCSTXT () (c:GIS2CADTXT))
(defun c:BCSBND () (c:GIS2CADBOUNDS))
(defun c:BCSMAP () (c:GIS2CADBOUNDS))
;; BCSLINK: pick BIGCS objects (parcel line, owner label, monument) and open each one's hyperlink (PE_URL) in the
;; default browser; the link description (DB/PG, datasheet) is printed. Read-only: nothing is added or changed.
(defun g2c:url (e / xd u d)
  ;; (url . description) from the object's PE_URL xdata, or nil
  (if (setq xd (cdr (car (cdr (assoc -3 (entget e '("PE_URL")))))))
    (progn
      (foreach p xd
        (if (= (car p) 1000)
          (cond ((not u) (setq u (cdr p))) ((not d) (setq d (cdr p))))))
      (if (and u (/= u "")) (cons u (if d d ""))))))

(defun g2c:openurl (u / sh r)
  ;; WScript.Shell Run hands the quoted URL to the default browser (no cmd.exe, so & and spaces are safe)
  (if vlax-create-object (setq sh (vl-catch-all-apply 'vlax-create-object '("WScript.Shell"))))
  (if (and sh (not (vl-catch-all-error-p sh)))
    (progn
      (setq r (vl-catch-all-apply 'vlax-invoke-method (list sh 'Run (strcat "\"" u "\"") 1 :vlax-false)))
      (vlax-release-object sh)
      (not (vl-catch-all-error-p r)))
    (progn (command "_.BROWSER" u) T)))

(defun c:BCSLINK (/ s l)
  (while (setq s (entsel "\nPick a parcel line, owner label or monument to open its link <done>: "))
    (if (setq l (g2c:url (car s)))
      (progn
        (princ (strcat "\nBIGCS: " (if (/= (cdr l) "") (strcat (cdr l) " - ") "") (car l)))
        (if (not (g2c:openurl (car l))) (princ "\nBIGCS: could not open the browser.")))
      (princ "\nNo link on that object")))
  (princ))
(defun c:G2CLINK () (c:BCSLINK))

(defun c:BCSST () (c:GIS2CADSTYLE))
(defun c:BCSLOAD () (c:GIS2CADLOAD))

(princ "\nBIGCS - Boundary Intelligence for GIS, CAD & Survey - loaded. Commands: BCS (parcels), BCSTXT (labels only, no boundary), BCSADJ (adjoiner table + CSV), BCSREF (refresh labels), BCSLTR (letters), BCSMAP or BCSBND (map layers: borders, monuments, roads, flood, buildings), BCSST (label style), BCSLINK (open an object's deed / datasheet link), BCSLOAD (reload). Also G2C/G2CTXT/G2CBND/G2CST/G2CLOAD and GIS2CAD/GIS2CADBOUNDS/GIS2CADSTYLE/GIS2CADLOAD.")
(princ)

;; BIGCS toolbar: load BIGCS_menu.lsp from this cad folder if it exists (every step guarded).
;; License: status / computer ID / enter key / deactivate. The engine does the checking; this only shows the result.
(defun g2c:echolog (f / h s)
  (if (setq h (open f "r"))
    (progn (while (setq s (read-line h)) (princ (strcat "\n" s))) (close h))))

(defun g2c:lic (args / lg)
  (setq lg (strcat *g2c-out* "_license.log"))
  (g2c:shell-wait (strcat "\"" *g2c-exe* "\" license " args " > \"" lg "\" 2>&1"))
  (g2c:echolog lg))

(defun c:BCSLIC (/ act k kf h)
  (initget "Status Enter Recheck Counties Portal Deactivate")
  (setq act (getkword "\nBIGCS license [Status/Enter key/Recheck/Counties/Portal/Deactivate] <Status>: "))
  (cond
    ((= act "Enter")
     (setq k (getstring T "\nPaste your license key: "))
     (if (and k (/= (setq k (vl-string-trim " \t\"" k)) ""))
       (progn
         (setq kf (strcat *g2c-out* "_key.txt"))
         (if (setq h (open kf "w")) (progn (write-line k h) (close h)))
         (g2c:lic (strcat "enter --file \"" kf "\""))
         (vl-file-delete kf))
       (princ "\nBIGCS: cancelled.")))
    ((= act "Recheck") (g2c:lic "recheck"))
    ((= act "Counties") (g2c:lic "counties"))
    ((= act "Portal") (g2c:lic "portal"))
    ((= act "Deactivate")
     (initget "Yes No")
     (if (= (getkword "\nRelease this computer's seat so it can be used on another computer? [Yes/No] <No>: ") "Yes")
       (g2c:lic "deactivate")
       (princ "\nBIGCS: cancelled.")))
    (T (g2c:lic "show")))
  (princ))
(defun c:BCSLICENSE () (c:BCSLIC))
(defun c:G2CLIC () (c:BCSLIC))

;; BIGCS toolbar: load BIGCS_menu.lsp from this cad folder if it exists (every step guarded).
;; The toolbar loader sits next to this file (install folder\app\cad\BIGCS_menu.lsp).
(progn
  (defun bcs:menu-lsp-path () (if (= (type *g2c-exe*) (quote STR)) (findfile (strcat (g2c:root) "cad\\BIGCS_menu.lsp"))))
  (defun bcs:menu-lsp-load (/ f) (if (setq f (bcs:menu-lsp-path)) (progn (setq *bcs-menu-lsp* f) (load f))) (princ))
  (if vl-catch-all-apply
    (vl-catch-all-apply (quote bcs:menu-lsp-load) nil)
    ((lambda (/ *error*) (defun *error* (m) (princ (strcat "\nBIGCS: toolbar not loaded (" (if (= (type m) (quote STR)) m "?") ").")) (princ)) (bcs:menu-lsp-load))))
  (princ))

;; State last picked in BCSBND (bnd_last.json next to gis2cad.bat, e.g. {"state":"SC",...}); nil if none.
;; BCSBLDG sends it as --state; with no bnd_last.json the CLI infers the state from the drawing EPSG, then the license.
(defun g2c:bndstate (/ f h s p q r)
  (if (and (setq f (findfile (strcat (g2c:root) "bnd_last.json"))) (setq h (open f "r")))
    (progn
      (while (and (not r) (setq s (read-line h)))
        (if (setq p (vl-string-search "\"state\"" s))
          (progn
            (setq s (substr s (+ p 8)) q (vl-string-search "\"" s))
            (if q (setq s (substr s (+ q 2)) q (vl-string-search "\"" s)))
            (if (and q (> q 0)) (setq r (strcase (substr s 1 q)))))))
      (close h)))
  r)

;; Building footprints (any state whose county file records a source): window corners or a selected parcel's extents + buffer (default 50 ft).
;; Runs "bounds area --what bldg" in the drawing's EPSG, loads the result (layer BIGCS-BLDG), then deletes the temp files.
(defun c:BCSBLDG (/ o k p1 p2 e ob mn mx d buf f h s)
  (setq o (strcat (getenv "TEMP") "\\bigcs_bldg") buf 0.0)
  (foreach x '(".lsp" ".json" ".dxf" ".log") (if (findfile (strcat o x)) (vl-file-delete (strcat o x))))
  (initget "Window Parcel")
  (setq k (getkword "\nBIGCS building footprints [Window/Parcel] <Window>: "))
  (if (not k) (setq k "Window"))
  (cond
    ((= k "Window")
     (if (setq p1 (getpoint "\nFirst corner: ")) (setq p2 (getcorner p1 "\nOpposite corner: "))))
    ((= k "Parcel")
     (if (setq e (entsel "\nSelect the parcel line/polyline: "))
       (progn (initget 4) (setq d (getdist "\nBuffer around the parcel in drawing units (ft) <50>: "))
              (setq buf (if d d 50.0))
              (setq ob (vlax-ename->vla-object (car e)))
              (vla-getboundingbox ob 'mn 'mx)
              (setq p1 (vlax-safearray->list mn) p2 (vlax-safearray->list mx))))))
  (if (and p1 p2)
    (progn
      (princ (strcat "\nBIGCS: downloading building footprints (EPSG " (g2c:epsg-s) ")..."))
      (g2c:area-run (strcat "\"" *g2c-exe* "\"" " bounds area --what bldg" (if (g2c:bndstate) (strcat " --state " (g2c:bndstate)) "") " --epsg " (g2c:epsg-s)
                            " --x1 " (rtos (min (car p1) (car p2)) 2 4) " --y1 " (rtos (min (cadr p1) (cadr p2)) 2 4)
                            " --x2 " (rtos (max (car p1) (car p2)) 2 4) " --y2 " (rtos (max (cadr p1) (cadr p2)) 2 4)
                            (if (> buf 0) (strcat " --buffer " (rtos buf 2 2)) "")
                            " -o \"" o "\"") o)
      (setq f (strcat o ".lsp"))
      (if (findfile f)
        (progn (g2c:load-dedupe f) (vl-file-delete f)
               (foreach x '(".json" ".dxf") (if (findfile (strcat o x)) (vl-file-delete (strcat o x)))))
        (progn (princ "\nBIGCS: no building footprints drawn. Details:") (if (setq h (open (strcat o ".log") "r")) (progn (while (setq s (read-line h)) (if (not (wcmatch s "*BIGCS trial*")) (princ (strcat "\n" s)))) (close h))))))
    (princ "\nBIGCS: pick cancelled."))
  (princ))
(defun c:G2CBLDG () (c:BCSBLDG))
;; rc13: BCSCRS - show / set this drawing's coordinate system. A number = that EPSG; a state code (NC, SC, GA, VA, TN...) = that
;; state's own State Plane zone. Enter keeps it. The choice is saved in the drawing and as the default for new drawings.
(defun c:BCSCRS (/ cur v lg n)
  (setq cur (g2c:epsg-s) lg (strcat (getenv "TEMP") "\\bigcs_crs.log"))
  (princ (strcat "\nBIGCS: this drawing's coordinate system is EPSG " cur (if (g2c:dwg-epsg) "." " (not saved in this drawing yet).")))
  (setq v (getstring (strcat "\nCoordinate system - EPSG number, or a state code for its State Plane zone <" cur ">: ")))
  (if (or (not v) (= v "")) (setq v cur))
  (setq v (vl-string-trim " " v))
  (g2c:shell-wait (strcat "\"" *g2c-exe* "\"" " bounds epsg " v " > \"" lg "\" 2>&1"))
  (setq n (g2c:cfg-epsg))
  (if (g2c:logok lg)
    (progn (g2c:dwg-epsg-put n) (g2c:echolog lg))
    (progn (princ (strcat "\nBIGCS: not changed - " v " is not a known EPSG number or state code.")) (g2c:echolog lg)))
  (princ))
(defun g2c:logok (lg / h s ok)
  (if (setq h (open lg "r")) (progn (while (setq s (read-line h)) (if (wcmatch s "drawing_epsg: *") (setq ok T))) (close h)))
  ok)
(defun c:G2CCRS () (c:BCSCRS))
;; rc16 #6 option A (manual): BCSROT - pick a line or polyline segment, then the labels (MTEXT) to turn to its angle.
;; Plain AutoLISP only (entsel / entget / angle / ssget / entmod; no vlax-curve) so it runs in IntelliCAD hosts too.
(defun bcs:rd (a) (while (> a (+ (/ pi 2.0) 1e-9)) (setq a (- a pi))) (while (<= a (- 1e-9 (/ pi 2.0))) (setq a (+ a pi))) a)
(defun bcs:sd (p a b / vx vy l2 u) (setq vx (- (car b) (car a)) vy (- (cadr b) (cadr a)) l2 (+ (* vx vx) (* vy vy)))
  (setq u (if (= l2 0.0) 0.0 (max 0.0 (min 1.0 (/ (+ (* (- (car p) (car a)) vx) (* (- (cadr p) (cadr a)) vy)) l2)))))
  (distance (list (car p) (cadr p)) (list (+ (car a) (* u vx)) (+ (cadr a) (* u vy)))))
(defun bcs:lineang (s / ed ty p pts a b best d r g)
  (setq ed (entget (car s)) ty (cdr (assoc 0 ed)) p (cadr s))
  (cond ((= ty "LINE") (setq r (bcs:rd (angle (cdr (assoc 10 ed)) (cdr (assoc 11 ed))))))
        ((= ty "LWPOLYLINE")
         (foreach g ed (if (= (car g) 10) (setq pts (cons (cdr g) pts)))) (setq pts (reverse pts))
         (if (= 1 (logand 1 (cdr (assoc 70 ed)))) (setq pts (append pts (list (car pts)))))
         (while (cdr pts) (setq a (car pts) b (cadr pts) pts (cdr pts))
           (setq d (bcs:sd p a b))
           (if (and (not (equal a b 1e-9)) (or (not best) (< d best))) (setq best d r (bcs:rd (angle a b)))))))
  r)
(defun c:BCSROT (/ s r ss i e ed n)
  (setq n 0)
  (if (and (setq s (entsel "\nBIGCS: pick the line to align labels to: ")) (setq r (bcs:lineang s)))
    (progn (princ "\nBIGCS: select the labels to rotate: ")
      (if (setq ss (ssget '((0 . "MTEXT"))))
        (progn (setq i 0)
          (while (< i (sslength ss)) (setq e (ssname ss i) ed (entget e) i (1+ i))
            (setq ed (if (assoc 50 ed) (subst (cons 50 r) (assoc 50 ed) ed) (append ed (list (cons 50 r)))))
            (if (assoc 11 ed) (setq ed (subst (list 11 (cos r) (sin r) 0.0) (assoc 11 ed) ed)))   ; MTEXT direction vector wins over 50 when both are present
            (if (entmod ed) (setq n (1+ n))))
          (princ (strcat "\nBIGCS: rotated " (itoa n) " label(s) to " (angtos r 0 4) " degrees.")))))
    (if s (princ "\nBIGCS: that is not a line or polyline.")))
  (princ))
(princ)
