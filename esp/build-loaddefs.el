(eval-when-compile (require 'cl))

(defun build-loaddefs (&optional dir loaddefs)
  (unless dir
    (setq dir (pwd))
    (string-match "^Directory \\(.*\\)/" dir)
    (setq dir (match-string 1 dir)))
  (unless loaddefs
    (setq loaddefs (concat dir "/" (file-name-nondirectory dir) "-loaddefs.el")))
  (let ((loaddefs-buf (find-file-noselect loaddefs))
	(tmp-buf (get-buffer-create "*build-loaddefs*"))
	base fun)
    (save-excursion
      (set-buffer loaddefs-buf)
      (erase-buffer)
      (insert ";; Warning: This file was autogenerated.\n")

      (loop for file in (directory-files dir t "^[^._].*\.el$") do
	    (set-buffer loaddefs-buf)
	    (insert "\n; " (file-name-nondirectory file) "\n")
	    (set-buffer tmp-buf)
	    (insert-file-contents file nil nil nil t)
	    (setq base (file-name-nondirectory (file-name-sans-extension file)))
	    ;; The \; is so we do not match this autoload
	    (while (search-forward ";\;;###autoload" nil t)
	      (end-of-line) (forward-char)
	      (when (looking-at "^(def\\(un\\|alias\\|var\\) '?\\([A-Za-z0-9-]+\\)")
		(setq fun (match-string 2))

		;; Add to autoloads
		(set-buffer loaddefs-buf)
		(insert "(autoload '" fun " \"" base "\")\n")
		(set-buffer tmp-buf))))

      (set-buffer loaddefs-buf)
      (save-buffer))))
