;; This is for Emacs pre 25.1

;;;###autoload
(defun xref-find-definitions (identifier)
  "Find tag (in current tags table) whose name contains IDENTIFIER.

This is not a correct implementation of xref-find-definitions. If
there are multiple definitions it always goes to the most exact
definition. I provide a `find-tag-next' to go to the next
definition."
  (interactive
   (list (let ((word (current-word)))
	   (if (or current-prefix-arg (not word))
	       (read-string (format "Identifier [%s]: " word) nil nil word)
	     word))))
  (find-tag identifier))

;;;###autoload
(defun find-tag-next ()
  (interactive)
  (find-tag last-tag t))

;;;###autoload
(defun xref-find-references (indentifier)
  (interactive)
  (error "Not supported"))

;;;###autoload
(defun xref-push-marker-stack ()
  (interactive)
  (ring-insert find-tag-marker-ring (point-marker)))