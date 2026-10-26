;;; BIGCS.lsp - BIGCS loader for Carlson / IntelliCAD.
;;; (c) 2026 BIGCS Software. All rights reserved.
;;; APPLOAD this file (add it to the Startup Suite to load BIGCS every time). It:
;;;   1. finds the BIGCS install folder (the path written at install time, else the folder this file is in),
;;;   2. points the BIGCS commands at the installed engine (install folder\app\bigcs.bat, bundled Python),
;;;   3. loads the BIGCS commands and the BIGCS toolbar; BIGCS.mnu is loaded with MENULOAD only when the
;;;      BIGCS menu group is not loaded yet. Other menus are never changed. No -TOOLBAR.

(setq *bigcs-home-installed* "@HOME@")

(defun bigcs:slashes (s / i r c)
  (setq i 1 r "")
  (while (<= i (strlen s))
    (setq c (substr s i 1) r (strcat r (if (= c "/") "\\" c)) i (1+ i)))
  r)

(defun bigcs:folder (p / i)
  (setq p (bigcs:slashes p) i (strlen p))
  (while (and (> i 0) (/= (substr p i 1) "\\")) (setq i (1- i)))
  (if (> i 1) (substr p 1 (1- i)) p))

;; a folder is the BIGCS home when it holds app\bigcs.bat and app\cad\gis2cad.lsp
(defun bigcs:home-p (d)
  (if (and (= (type d) 'STR) (> (strlen d) 1)
           (findfile (strcat d "\\app\\bigcs.bat")) (findfile (strcat d "\\app\\cad\\gis2cad.lsp")))
    d))

(defun bigcs:find-home (/ f r)
  ;; each test keeps the folder in r: (and ...) only returns T, never the folder itself
  (cond
    ((setq r (bigcs:home-p *bigcs-home-installed*)) r)
    ((and (setq f (findfile "BIGCS.lsp")) (setq r (bigcs:home-p (bigcs:folder f)))) r)
    ((setq f (getfiled "Find BIGCS.lsp in the BIGCS install folder" "" "lsp" 0))
     (bigcs:home-p (bigcs:folder f)))))

(defun bigcs:load (/ home)
  (setq home (bigcs:find-home))
  (if (/= (type home) 'STR) (setq home nil))
  (if (not home)
    (princ "\nBIGCS: install folder not found. Reinstall BIGCS, then APPLOAD BIGCS.lsp from its install folder.")
    (progn
      (setq *bigcs-home* home)
      (setq *g2c-exe* (strcat home "\\app\\bigcs.bat"))
      (setq *bcs-menu-lsp* (strcat home "\\app\\cad\\BIGCS_menu.lsp"))
      (load (strcat home "\\app\\cad\\gis2cad.lsp"))
      (setq *g2c-exe* (strcat home "\\app\\bigcs.bat"))
      (princ (strcat "\nBIGCS loaded from " home ". Type BCS to start, BCSLIC to activate your license."))))
  (princ))

(bigcs:load)
(princ)
