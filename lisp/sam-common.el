;;; sam-common.el --- SAM's Common macros/functions

;; Copyright (C) 2011 Sean MacLennan

(eval-when-compile (require 'cl))

;; GNU emacs sets emacs
;; XEmacs sets xemacs
;; SXEmacs sets sxemacs and xemacs
(defmacro my-feature-cond (&rest clauses)
  "Test CLAUSES for feature, function, or variable at compile time.
Each clause is (FEATURE BODY...)."
  (dolist (x clauses)
    (let ((feature (car x))
	  (body (cdr x)))
      (when (or (eq feature t)
		(featurep feature)
		(fboundp feature)
		(boundp feature))
	(return (cons 'progn body))))))
(put 'my-feature-cond 'lisp-indent-hook 'defun)

(my-feature-cond
  (xemacs ;; Must be a defalias for my-isearch-word-forward
   (defalias 'my-interactive-p 'interactive-p)
   (defalias 'kill-whole-line 'kill-entire-line))
  (t ;; Must be a macro to work
   (defmacro my-interactive-p () `(called-interactively-p 'interactive))))

(defun my-do-compile (cmd)
  (save-some-buffers (not compilation-ask-about-save) nil)
  (my-feature-cond
    (xemacs (compile-internal cmd "No more errors"))
    (t (compilation-start cmd))))

(provide 'sam-common)