;;; -------------------------------------------------------------------------
;; CC-MODE
;; Customizations for c-mode, c++-mode, java-mode, etc.

;; This hook is run once when cc-mode initializes
; (defun my-c-initialization-hook ()
  ;; Do this after cc-mode loaded for XEmacs
  (setup-font-lock-keywords)

  (let ((lxr-menu
	 `("----"
	   ["lxr" lxr-at-point lxr-url]
	   ["lxr defined" lxr-defined-at-point lxr-url]
	   ["lxr next" lxr-next-defined lxr-url])))

    (nconc c-c-menu lxr-menu)
    (nconc c-c++-menu lxr-menu)
    )
; )
; (add-hook 'c-initialization-hook 'my-c-initialization-hook)

;; This hook is run for all the modes handled by cc-mode
(defun my-c-mode-common-hook ()
  (c-set-style "linux")
  (c-toggle-hungry-state 1)  ;; hungry delete
  (setq c-tab-always-indent 'other) ;; real tabs in strings and comments
  (setq case-fold-search nil) ;; C is case sensitive

  ;; Let's try this...
  (setq c-enable-xemacs-performance-kludge-p t)

;  (easy-menu-add-item nil '("C") "----")
;  (easy-menu-add-item nil '("C") ["lxr" lxr-at-point lxr-url])
  )
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

;;; -------------------------------------------------------------------------

(defun my-go-mode-hook()
  (setup-font-lock-keywords)
  )
(add-hook 'go-mode-hook 'my-go-mode-hook)

;;; -------------------------------------------------------------------------

(defun string-match-list (match list &optional case-sensitive)
  "Lookup an element in a list using string-match.
If found, returns the matching list entry with the car of the list replaced
with the actual match.
Does the matches case insensitive unless `case-sensitive' is non-nil."
  (let ((case-fold-search (not case-sensitive)))
    (catch 'converted
      (dolist (entry list)
	(when (string-match (car entry) match)
	  (throw 'converted
		 (append (list (match-string 0 match)) (cdr entry))))))))

(defvar include-list
  '("stdio.h" "stdlib.h" "stdint.h" "string.h" "unistd.h" "fcntl.h" "ctype.h" "errno.h"))

(defun c-template (&optional getopt)
  (interactive "P")
  (goto-char (point-min))
  (dolist (include include-list)
    (insert (concat "#include <" include ">\n")))
  (when getopt (insert "\n\nstatic int verbose;\n"))
  (insert "\n\nint main(int argc, char *argv[])\n{\n\t")
  (when getopt
    (insert (concat
	     "int c;\n\n"
	     "\twhile ((c = getopt(argc, argv, \"v\")) != EOF)\n"
	     "\t\tswitch (c) {\n" "\t\tcase 'v':\n"
	     "\t\t\t++verbose;\n" "\t\t\tbreak;\n"
	     "\t\tdefault:\n" "\t\t\tputs(\"Sorry!\");\n"
	     "\t\t\texit(1);\n" "\t\t}\n" "\n\t")))
  (let ((mark (point)))
    (insert "\n\treturn 0;\n}\n")
    (goto-char mark))
  (add-local-compile-command nil))

(would-like 'my-c-tools)

;;; -------------------------------------------------------------------------
(defvar local-compile-cc "gcc -O3 -Wall")
(defvar local-compile-c++ "g++ -O3 -Wall")
(defvar local-compile-go "gccgo")
(defvar local-compile-offset 4)

(defun add-local-vars (block)
  "Local routine to actually add the block of vars to the file.
Will not overwrite current variables if they exist."
  (save-excursion
    (save-restriction
      (let ((case-fold-search t))

      ;; Make sure local variables do not exist
      (widen)
      (when (search-forward "Local Variables:" nil t)
	(error "Local variables already exist."))

      ;; Add it
      (goto-char (point-max))
      (insert block)))))

(defun add-local-compile-command (arg)
  (interactive "*P")
  (let ((file-name (file-name-nondirectory (buffer-file-name)))
	cmd)

    (cond
     ((eq major-mode 'c-mode)
      (setq cmd (concat local-compile-cc " " file-name " -o "
			(file-name-sans-extension file-name))))
     ((eq major-mode 'c++-mode)
      (setq cmd (concat local-compile-c++ " " file-name " -o "
			(file-name-sans-extension file-name))))
     ((eq major-mode 'go-mode)
      (setq cmd (concat local-compile-go " " file-name " -o "
			(file-name-sans-extension file-name))))
     (t (error "Unsupported mode %S" major-mode)))

    (add-local-vars
     (concat "\n/*\n * Local Variables:\n"
	     " * compile-command: \"" cmd "\"\n"
	     (when arg
	       (format (concat " * indent-tabs-mode: t\n"
			       " * c-basic-offset: %d\n"
			       " * tab-width: %d\n")
		       local-compile-offset local-compile-offset))
	     " * End:\n */\n"))
    (set (make-local-variable 'compile-command) cmd)))

(defun set-local-compile-command ()
  (interactive)
  (let ((cmd (read-string "Compile: " compile-command)))
    (set (make-local-variable 'compile-command) cmd)))

(defun add-local-c-vars (offset)
  "Add local variables to set tab width."
  (interactive "nOffset: ")
  ;; Currently only for C modes
  (unless (or (eq major-mode 'c-mode) (eq major-mode 'c++-mode))
    (error "Unsupported mode %S" major-mode))
  (setq offset (number-to-string offset))
  (add-local-vars
   (format (concat "\n"
		   "/*\n"
		   " * Local Variables:\n"
		   " * indent-tabs-mode: t\n"
		   " * c-basic-offset: %d\n"
		   " * tab-width: %d\n"
		   " * End:\n"
		   " */\n") offset offset)))

(require 'my-compile)