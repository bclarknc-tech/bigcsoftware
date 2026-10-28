;;; BIGCS_menu.lsp - BIGCS toolbar and pull-down menu loader (v1.2).
;;; (c) 2026 BIGCS Software. All rights reserved.
;;; Loads BIGCS.mnu one time (only when the BIGCS menu group is not loaded yet) and adds:
;;;   BCSTOOLBAR - show the BIGCS toolbar again (loads the menu first if needed).
;;; BIGCS.mnu is looked for in: the folder this file was loaded from (*bcs-menu-lsp*), the CAD
;;; support / search path, %LOCALAPPDATA%\BIGCS\app\cad\, and the BIGCS program folder.
;;; Carlson / IntelliCAD: only plain AutoLISP plus MENULOAD (only when the BIGCS group is missing). No -TOOLBAR.
;;; AutoCAD: the same, plus guarded ActiveX calls for the support path and menu bar.
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

;; is the BIGCS menu group loaded?
(defun bcs:menu-loaded-p ()
  (if menugroup (if (menugroup "BIGCS") T nil) nil))

(defun bcs:find-mnu (/ e f)
  ;; each test keeps the path in f: (and ...) only returns T, never the path itself
  (cond
    ((and (= (type *bcs-menu-lsp*) 'STR) (setq f (findfile (strcat (bcs:folder *bcs-menu-lsp*) "\\BIGCS.mnu")))) f)
    ((setq f (findfile "BIGCS.mnu")) f)
    ((and (setq e (getenv "LOCALAPPDATA")) (setq f (findfile (strcat e "\\BIGCS\\app\\cad\\BIGCS.mnu")))) f)
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

(defun bcs:load-menu (mnu / fd ce)
  (setq mnu (bcs:slashes mnu))
  (bcs:add-path (bcs:folder mnu))
  (setq fd (getvar "FILEDIA") ce (getvar "CMDECHO"))
  (setvar "FILEDIA" 0)
  (setvar "CMDECHO" 0)
  (bcs:try (function (lambda () (command "_.MENULOAD" mnu))) nil)
  (bcs:cmd-clear)
  (if fd (setvar "FILEDIA" fd))
  (if ce (setvar "CMDECHO" ce))
  (if (bcs:menu-loaded-p)
    (progn (bcs:menubar) T)))

;; Show the toolbar again. AutoCAD only (guarded ActiveX). Carlson / IntelliCAD: no command calls at all;
;; the user re-shows it from the toolbar right-click list.
(defun bcs:show-toolbar ()
  (if (and (not (bcs:icad-p)) vlax-get-acad-object)
    (bcs:try
      (function
        (lambda ()
          (vla-put-visible
            (vla-item (vla-get-toolbars (vla-item (vla-get-menugroups (vlax-get-acad-object)) "BIGCS")) "BIGCS")
            :vlax-true)
          T))
      nil)))

(defun c:BCSTOOLBAR (/ m)
  ;; loads BIGCS.mnu only when the BIGCS group is not loaded; never sends -TOOLBAR
  (if (not (bcs:menu-loaded-p))
    (progn
      (if (not (setq m (bcs:find-mnu)))
        (setq m (getfiled "Find BIGCS.mnu (BIGCS toolbar)" "" "mnu" 0)))
      (if m (progn (setq *bcs-menu-lsp* m) (bcs:load-menu m)))))
  (cond
    ((not (bcs:menu-loaded-p))
     (princ "\nBIGCS: the toolbar did not load. Type MENULOAD and pick BIGCS.mnu in the BIGCS cad folder."))
    ((bcs:icad-p)
     (princ "\nBIGCS: right-click any toolbar and check BIGCS to show it."))
    ((bcs:show-toolbar) (princ "\nBIGCS: toolbar shown."))
    (T (princ "\nBIGCS: right-click any toolbar and check BIGCS to show it.")))
  (princ))

;; Buttons for tools that are not in every BIGCS version give a plain message instead of "Unknown command".
;; A BIGCS version that has the tool replaces these when it loads.
(if (not c:BCSADJ) (defun c:BCSADJ () (princ "\nBIGCS: Adjoiner Table is not included in this BIGCS version.") (princ)))
(if (not c:BCSREF) (defun c:BCSREF () (princ "\nBIGCS: Refresh Labels is not included in this BIGCS version.") (princ)))
(if (not c:BCSLTR) (defun c:BCSLTR () (princ "\nBIGCS: Letters is not included in this BIGCS version.") (princ)))
(if (not c:BCSLIC) (defun c:BCSLIC () (princ "\nBIGCS: License is not included in this BIGCS version.") (princ)))

;; One-time load: only when the BIGCS menu group is missing.
(defun bcs:menu-autoload (/ m)
  (cond
    ((not menugroup) (princ "\nBIGCS: type MENULOAD and pick BIGCS.mnu to add the toolbar."))
    ((bcs:menu-loaded-p) nil)
    ((setq m (bcs:find-mnu))
     (if (bcs:load-menu m)
       (princ "\nBIGCS: toolbar and BIGCS menu loaded. Type BCSTOOLBAR if you ever close the toolbar.")
       (princ "\nBIGCS: could not load the toolbar. Type BCSTOOLBAR to try again.")))
    (T (princ "\nBIGCS: toolbar files not found. Type BCSTOOLBAR and pick BIGCS.mnu."))))

(bcs:try 'bcs:menu-autoload nil)
(princ)
