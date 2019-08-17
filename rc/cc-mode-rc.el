;;; -------------------------------------------------------------------------
;; CC-MODE
;; Customizations for c-mode, c++-mode, java-mode, etc.

;; Let's try making _ part of a "word"
(modify-syntax-entry ?_ "w" c-mode-syntax-table)
(modify-syntax-entry ?_ "w" c++-mode-syntax-table)

;; Same as Linux except 4 char tabs
(c-add-style "sam" '("linux" (c-basic-offset . 4) (tab-width . 4)))

;; This hook is run for all the modes handled by cc-mode
(defun my-c-mode-common-hook ()
  (c-set-style "sam")
  (c-toggle-hungry-state 1)  ;; hungry delete
  (c-toggle-electric-state 1) ;; auto-indent
  (setq c-tab-always-indent 'other) ;; real tabs in strings and comments
  (setq case-fold-search nil) ;; C is case sensitive

  (let ((tags (expand-file-name "TAGS")))
    (if (file-exists-p tags) (visit-tags-table tags t)))

  (my-compile-command)
  )
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

(require 'my-compile)

;; Turn off gcc colours
(setenv "GCC_COLORS" "")

;; Just allow compile commands
(put 'compile-command 'safe-local-variable #'stringp)

;; Bold SAM comments
(mapc (lambda (mode) (comment-warn mode "\\(/\\*\\|//\\) ?\\<SAM\\>.*"))
      '(c-mode c++-mode))

;; electric brace pairing

(defun insert-according-to-mode (&rest strs)
  (dolist (str strs)
    (insert str)
    (indent-according-to-mode)))

(defun electric-brace ()
  (interactive)
  (if (and (eolp)
	   ;; make sure we are not in string or comment
	   (not (nth 8 (syntax-ppss))))
      (progn
	(insert-according-to-mode "{" "\n" "\n}")
	(end-of-line 0))
    (self-insert-command 1)))

(define-key c-mode-map   "{" 'electric-brace)
(define-key c++-mode-map "{" 'electric-brace)
