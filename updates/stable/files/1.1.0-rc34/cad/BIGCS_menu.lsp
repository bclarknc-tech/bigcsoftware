;;; BIGCS_menu.lsp - BIGCS toolbar and pull-down menu loader (v1.3).
;;; (c) 2026 BIGCS Software. All rights reserved.
;;; Loads BIGCS.mnu one time (only when the BIGCS menu group is not loaded yet) and adds:
;;;   BCSTOOLBAR - show the BIGCS toolbar again (loads the menu first if needed).
;;; BIGCS.mnu is looked for in: the folder this file was loaded from (*bcs-menu-lsp*), the CAD
;;; support / search path, %LOCALAPPDATA%\Programs\BIGCS\app\cad\, the BIGCS home folder, and
;;; the BIGCS program folder next to the engine.
;;; Carlson / IntelliCAD: plain AutoLISP plus MENULOAD (tried even if the menugroup function is
;;; missing). After a confirmed load, a guarded show of the BIGCS toolbar only; if that does not
;;; work, the user is told to right-click any toolbar and check BIGCS.
;;; AutoCAD: the same, plus guarded ActiveX calls for the support path, menu load, menu bar and toolbar.
;;; Nothing else in BIGCS changes.

;; AutoCAD needs this for its ActiveX calls; skipped where it does not exist
(if vl-load-com (vl-load-com))

;; (f args) guarded: vl-catch-all-apply when the CAD has it, otherwise a plain call
(defun bcs:try (f a / r)
  (if vl-catch-all-apply
    (progn (setq r (vl-catch-all-apply f a))
           (if (and vl-catch-all-error-p (vl-catch-all-error-p r)) nil r))
    (apply f a)))

;; Not AutoCAD (Carlson / IntelliCAD): AutoCAD and Civil 3D report PROGRAM = "acad"; anything else, or
;; a SRCHPATH variable (IntelliCAD only), means no ActiveX calls are made.
(defun bcs:icad-p (/ p)
  (setq p (getvar "PROGRAM"))
  (or (= (type (getvar "SRCHPATH")) 'STR)
      (not (and (= (type p) 'STR) (= (strcase p) "ACAD")))))

;; plain string helpers (no vl- functions)
(defun bcs:slashes (s / i r c)
  (setq i 1 r "")
  (while (<= i (strlen s))
    (setq c (substr s i 1) r (strcat r (if (= c "/") "\\" c)) i (1+ i)))
  r)

(defun bcs:has (needle hay / n i hit)
  (setq n (strlen needle) i 1)
  (while (and (not hit) (<= (+ i n -1) (strlen hay)))
    (if (= (substr hay i n) needle) (setq hit T))
    (setq i (1+ i)))
  hit)

(defun bcs:trim-end (s ch)
  (while (and (> (strlen s) 0) (= (substr s (strlen s) 1) ch)) (setq s (substr s 1 (1- (strlen s)))))
  s)

;; folder of a file path, without the trailing backslash
(defun bcs:folder (p / i)
  (setq p (bcs:slashes p) i (strlen p))
  (while (and (> i 0) (/= (substr p i 1) "\\")) (setq i (1- i)))
  (if (> i 1) (substr p 1 (1- i)) p))

(defun bcs:cmd-clear (/ a)
  (setq a (getvar "CMDACTIVE"))
  (if (and (= (type a) 'INT) (> a 0)) (command)))

;; is the BIGCS menu group loaded? nil when the CAD has no menugroup function
(defun bcs:menu-loaded-p ()
  (if menugroup (if (menugroup "BIGCS") T nil) nil))

;; record this file's folder when the main loader did not already set it
(defun bcs:self-path (/ f)
  (if (/= (type *bcs-menu-lsp*) 'STR)
    (if (setq f (findfile "BIGCS_menu.lsp")) (setq *bcs-menu-lsp* f)))
  *bcs-menu-lsp*)

(defun bcs:find-mnu (/ e f)
  ;; each test keeps the path in f: (and ...) only returns T, never the path itself
  (bcs:self-path)
  (cond
    ((and (= (type *bcs-menu-lsp*) 'STR) (setq f (findfile (strcat (bcs:folder *bcs-menu-lsp*) "\\BIGCS.mnu")))) f)
    ((and (setq f (findfile "BIGCS_menu.lsp")) (setq f (findfile (strcat (bcs:folder f) "\\BIGCS.mnu")))) f)
    ((setq f (findfile "BIGCS.mnu")) f)
    ((and (setq e (getenv "LOCALAPPDATA")) (setq f (findfile (strcat e "\\Programs\\BIGCS\\app\\cad\\BIGCS.mnu")))) f)
    ((and (= (type *bigcs-home*) 'STR) (setq f (findfile (strcat *bigcs-home* "\\app\\cad\\BIGCS.mnu")))) f)
    ((and (= (type *bigcs-home-installed*) 'STR) (setq f (findfile (strcat *bigcs-home-installed* "\\app\\cad\\BIGCS.mnu")))) f)
    ((and (= (type *g2c-exe*) 'STR) g2c:root (setq f (findfile (strcat (g2c:root) "cad\\BIGCS.mnu")))) f)))

;; add the menu folder to the search path so CAD finds the button images
(defun bcs:in-path-p (dir sp)
  (bcs:has (strcat ";" (strcase dir) ";") (strcat ";" (strcase (bcs:slashes sp)) ";")))

(defun bcs:add-path (dir / sp)
  (if (bcs:icad-p)
    (progn
      (setq sp (getvar "SRCHPATH"))
      (if (/= (type sp) 'STR) (setq sp ""))
      (setq sp (bcs:trim-end sp ";"))
      (if (and (= (type (getvar "SRCHPATH")) 'STR) (not (bcs:in-path-p dir sp)))
        (bcs:try (function (lambda () (setvar "SRCHPATH" (if (= sp "") dir (strcat sp ";" dir))))) nil)))
    (if vlax-get-acad-object
      (bcs:try
        (function
          (lambda (/ fl sp)
            (setq fl (vla-get-files (vla-get-preferences (vlax-get-acad-object)))
                  sp (bcs:trim-end (vla-get-supportpath fl) ";"))
            (if (not (bcs:in-path-p dir sp))
              (vla-put-supportpath fl (if (= sp "") dir (strcat sp ";" dir))))))
        nil))))

;; AutoCAD only: put the BIGCS pull-down on the menu bar if it is not there (shows when MENUBAR is 1)
(defun bcs:menubar ()
  (if (and (not (bcs:icad-p)) vlax-get-acad-object)
    (bcs:try
      (function
        (lambda (/ acad pm)
          (setq acad (vlax-get-acad-object)
                pm (vla-item (vla-get-menus (vla-item (vla-get-menugroups acad) "BIGCS")) 0))
          (if (= (vla-get-onmenubar pm) :vlax-false)
            (vla-insertinmenubar pm (vla-get-count (vla-get-menubar acad))))))
      nil)))

;; AutoCAD only: load BIGCS.mnu through the menu group collection (no command during load)
(defun bcs:acad-menuload (mnu)
  (if (and (not (bcs:icad-p)) vlax-get-acad-object)
    (bcs:try
      (function
        (lambda ()
          (vla-load (vla-get-menugroups (vlax-get-acad-object)) mnu)
          T))
      nil)))

;; MENULOAD without relying on (command) during APPLOAD: prefer vl-cmdf, then MENULOAD, then _.MENULOAD
(defun bcs:cmd-menuload (mnu)
  (cond
    (vl-cmdf
     (or (bcs:try (function (lambda () (vl-cmdf "MENULOAD" mnu))) nil)
         (bcs:try (function (lambda () (vl-cmdf "_.MENULOAD" mnu))) nil))
     (bcs:cmd-clear))
    (T
     (or (bcs:try (function (lambda () (command "MENULOAD" mnu))) nil)
         (bcs:try (function (lambda () (command "_.MENULOAD" mnu))) nil))
     (bcs:cmd-clear))))

(defun bcs:load-menu (mnu / fd ce)
  (setq mnu (bcs:slashes mnu))
  (bcs:add-path (bcs:folder mnu))
  (setq fd (getvar "FILEDIA") ce (getvar "CMDECHO"))
  (setvar "FILEDIA" 0)
  (setvar "CMDECHO" 0)
  (if (not (bcs:menu-loaded-p))
    (progn
      (bcs:acad-menuload mnu)
      (if (not (bcs:menu-loaded-p)) (bcs:cmd-menuload mnu))))
  (bcs:cmd-clear)
  (if fd (setvar "FILEDIA" fd))
  (if ce (setvar "CMDECHO" ce))
  (if (or (bcs:menu-loaded-p) (not menugroup))
    (progn (bcs:menubar) (bcs:show-toolbar) T)))

;; Show the BIGCS toolbar only. AutoCAD: guarded ActiveX. Carlson / IntelliCAD: a guarded show of
;; the BIGCS toolbar only, and only after the BIGCS menu group is confirmed loaded. If that does
;; not work, the caller prints the right-click instruction. Other toolbars are never named.
(defun bcs:show-toolbar (/ ok)
  (cond
    ((and (not (bcs:icad-p)) vlax-get-acad-object)
     (bcs:try
       (function
         (lambda ()
           (vla-put-visible
             (vla-item (vla-get-toolbars (vla-item (vla-get-menugroups (vlax-get-acad-object)) "BIGCS")) "BIGCS")
             :vlax-true)
           T))
       nil))
    ((and (bcs:menu-loaded-p) vl-cmdf)
     (setq ok (bcs:try
                (function
                  (lambda ()
                    (and (vl-cmdf ".-TOOLBAR" "BIGCS" "_Show") T)))
                nil))
     (bcs:cmd-clear)
     ok)))

(defun c:BCSTOOLBAR (/ m)
  ;; loads BIGCS.mnu only when the BIGCS group is not loaded
  (if (not (bcs:menu-loaded-p))
    (progn
      (if (not (setq m (bcs:find-mnu)))
        (setq m (getfiled "Find BIGCS.mnu (BIGCS toolbar)" "" "mnu" 0)))
      (if m (progn (setq *bcs-menu-lsp* m) (bcs:load-menu m)))))
  (cond
    ((and (not (bcs:menu-loaded-p)) menugroup)
     (princ "\nBIGCS: the toolbar did not load. Type MENULOAD and pick BIGCS.mnu in %LOCALAPPDATA%\\Programs\\BIGCS\\app\\cad."))
    ((bcs:show-toolbar) (princ "\nBIGCS: toolbar shown."))
    (T (princ "\nBIGCS: right-click any toolbar and check BIGCS to show it.")))
  (princ))

;; Buttons for tools that are not in every BIGCS version give a plain message instead of "Unknown command".
;; A BIGCS version that has the tool replaces these when it loads.
(if (not c:BCSADJ) (defun c:BCSADJ () (princ "\nBIGCS: Adjoiner Table is not included in this BIGCS version.") (princ)))
(if (not c:BCSREF) (defun c:BCSREF () (princ "\nBIGCS: Refresh Labels is not included in this BIGCS version.") (princ)))
(if (not c:BCSLTR) (defun c:BCSLTR () (princ "\nBIGCS: Letters is not included in this BIGCS version.") (princ)))
(if (not c:BCSLIC) (defun c:BCSLIC () (princ "\nBIGCS: License is not included in this BIGCS version.") (princ)))

;; First load: find BIGCS.mnu and load it. Still tried when the CAD has no menugroup function.
(defun bcs:menu-autoload (/ m)
  (bcs:self-path)
  (cond
    ((bcs:menu-loaded-p) nil)
    ((setq m (bcs:find-mnu))
     (if (bcs:load-menu m)
       (princ "\nBIGCS: toolbar and BIGCS menu loaded. Type BCSTOOLBAR if you ever close the toolbar.")
       (princ "\nBIGCS: could not load the toolbar. Type BCSTOOLBAR to try again.")))
    (T (princ "\nBIGCS: toolbar files not found. Type BCSTOOLBAR and pick BIGCS.mnu."))))

(bcs:try 'bcs:menu-autoload nil)
(princ)
