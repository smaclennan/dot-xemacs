(defvar kloc-args "-F short"
  "Args passed to kwcheck command. -pd is added automagically.")

(defvar kloc-cmd "kwcheck run %s -pd=%s %s"
  "Klocwork command. Passed in args, project dir, and
file. Requires -F short.")

(defvar kloc-dir nil
  "*Klocwork project directory. See also `kloc-dirs-list'.")

(defvar kloc-dirs-list nil
  "*A list of directories and their klocwork project. The
directory is a regular expression. The project can be an absolute
path or relative.

If `kloc-dir' is not set, `kloc-project-dir' will search this
list to try to find the kloc directory.")

(defvar kloc-remote "tigger"
  "The remote machine to use")

(defvar kloc-remote-cmd "~/Tools/kwinstall-18.2.0.1113-cmdline/bin/kwcheck"
  "The remote kwcheck command.")

;; Defined in rc/compile.el
(defvar make-clean-command nil)

(require 'compile)
(require 'git-diff)

;;;###autoload
(defun kloc-project-dir (file)
  "Try to find the project dir for FILE.
Checks `kloc-dir' and then `kloc-dirs-list'."
  (catch 'outer
    (let ((dir (file-name-directory (expand-file-name file)))
	  (kdir kloc-dir))
      ;; Try to lookup kdir
      (unless kdir
	(catch 'found
	  (dolist (one kloc-dirs-list)
	    (when (string-match (car one) dir)
	      (setq kdir (cadr one))
	      (throw 'found t)))
	    (throw 'outer nil)))
      ;; Absolute - make sure it exists
      (when (eq (string-to-char  kdir) ?/)
	(throw 'outer (if (file-exists-p kdir) kdir nil)))
      ;; Relative - walk up the directory tree
      (while (not (equal dir "/"))
	(when (file-exists-p (concat dir kdir))
	  (throw 'outer (concat dir kdir)))
	;; This removes the last directory
	(setq dir (file-name-directory (directory-file-name dir)))))))

(defun kloc-parse-one (file &optional no-parse-compile raw)
  (let ((start (point)))
    (unless raw
      ;; Delete the header
      (when (or (re-search-forward "Linking stage completed" nil t)
		(re-search-forward "up to date" nil t))
	(end-of-line) (forward-char))
      (kill-region start (point))

      ;; Fixup the lines for compilation
      (while (re-search-forward "^[^:\n]+:\\([0-9]+\\)" nil t)
	(replace-match (concat file ":" (match-string 1) ":1")))))

  ;; For the kloc-do-many list we want to parse even if no kdir.
  ;; Doesn't hurt in any case.
  (unless no-parse-compile
    (compilation-mode "kloc")
    (setq buffer-read-only nil)
    (compilation--parse-region (point-min) (point-max))))

(defun kloc-do-one (file &optional no-parse-compile raw edit)
  "Run kloc on FILE into the current buffer at the point.
If NO-PARSE-COMPILE is nil, also do a
`compilation--parse-region' on the entire buffer.

If RAW is non-nil, leave the raw output in the buffer.

If EDIT is non-nil, allow the command to be edited.

Returns the kloc project directory or nil."
  (let ((kdir (kloc-project-dir file)))
    (when kdir
      (let* ((args (if (file-exists-p "buildspec.out")
		       (concat kloc-args " -b buildspec.out")
		     kloc-args))
	     (cmd (format kloc-cmd args kdir file)))
	(when edit
	  (setq cmd (read-string "Cmd: " cmd)))
	(insert "# " cmd "\n")
	(save-excursion
	  (call-process-shell-command cmd nil '(t t) t)))

      (kloc-parse-one file no-parse-compile raw))
    kdir))

(defun kloc-do-list (flist)
  "Perform kloc on a list of files and put the results in one buffer."
    (with-current-buffer (get-buffer-create "*kloc*")
      (erase-buffer)
      (display-buffer "*kloc*")
      (while flist
	(goto-char (point-max))
	(insert "Analyzing " (car flist) "...\n")
	(unless (kloc-do-one (car flist) (cdr flist))
	  (insert "%s has no project directory" (car flist)))
	(setq flist (cdr flist)))))

;;;###autoload
(defun kloc (edit &optional raw)
  "Check the current buffer with klocwork.
Uses `kloc-project-dir' to find the project directory. Puts the
results in a compilation buffer.

A universal argument allows you to edit the command.

If RAW is non-nil, gives raw output. Next error will not work."
  (interactive "P")
  (let ((file buffer-file-name))
    (with-current-buffer (get-buffer-create "*kloc*")
      (erase-buffer)
      (display-buffer "*kloc*")
      (unless (kloc-do-one file nil raw edit)
	(error "No project directory found")))
    (message "kloc done.")))

;;;###autoload
(defun kloc-raw (edit)
  (interactive "P")
  (kloc edit t))

(defun kloc-run (cmd)
  "Trivial helper function."
  (message "%s" cmd)
  (shell-command cmd))

;;;###autoload
(defun kloc-add-local ()
  "Add the current buffers file to a kloc project locally.

Assumes that `compile-command' and `make-clean-command' are set
properly for the current buffer.

WARNING: This tends to mess up the project."
  (interactive)
  (let ((kdir (kloc-project-dir buffer-file-name)))
    (unless kdir (error "No klocwork project found"))
    (kloc-run (concat "kwinject -o buildspec.out " compile-command))
    (message "done")))

;;;###autoload
(defun kloc-git ()
  "Diff the branch against master and run klocwork on all the C
files... collecting the results in one buffer."
  (interactive)
  (with-temp-buffer
    ;; We must be rooted in the git dir
    (let ((default-directory (git-dir)) flist)
      ;; Collect the file names
      (erase-buffer)
      (shell-command "git diff master --stat" t)
      (goto-char (point-min))
      (while (re-search-forward "^ \\([^0-9][^ ]*\\.c\\)" nil t)
	(setq flist (append flist (list (expand-file-name (match-string 1))))))
      (if flist
	  (progn
	    (kloc-do-list flist)
	    (message "Kloc done"))
	(message "No diffs found")))))

;;;###autoload
(defun remote-kloc ()
  (interactive)
  (let* ((fname (if (string-match "^/data/" buffer-file-name)
		    (replace-match "/home/sam/" nil nil buffer-file-name)
		  buffer-file-name))
	 (remote-fname (concat kloc-remote ":" fname))
	 (kdir (kloc-project-dir fname)))

    ;; Send it to remote
    (message "Copy file...")
    (unless (eq 0 (call-process "scp" nil nil nil fname remote-fname))
      (error "scp failed"))

    ;; Do the kloc command
    (with-current-buffer (get-buffer-create "*kloc*")
      (erase-buffer)
      (display-buffer "*kloc*")
      (message "Calling klocwork...")
      (unless (eq 0 (call-process
		     "ssh" nil t nil kloc-remote
		     kloc-remote-cmd "run" "-Fshort" (concat "-pd=" kdir) fname))
	(error "ssh failed"))
      (message "klocwork done")

      ;; Parse the results
      (goto-char (point-min))
      (if (re-search-forward "Summary: 0 Local" nil t)
	  (message "No issues")
	(goto-char (point-min))
	(kloc-parse-one fname)))))

(provide 'kloc)
