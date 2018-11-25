;; Handy Dandy(tm) Functions

(require 'sam-common)
(require 'dirfiles)

;;;###autoload
(defun unixtime (seconds)
  (interactive "sTime: ")
  ;; Force it to a float for 32-bit systems.
  (let ((time (string-to-number (concat seconds ".0"))))
    (message "%s"
	     (format-time-string
	      "%a %b %d %T %Z %Y"
	      ;; seconds-to-time from time-date.el in gnus
	      (list (floor time 65536)
		    (floor (mod time 65536))
		    (floor (* (- time (ffloor time)) 1000000)))
	      ))))

;;;###autoload
(defun my-x-colour (number)
  (interactive "sColour: ")
  (cond
   ;; Convert 'd d d' to `#xxxxxx'
   ((string-match "^\\([0-9]+\\)\\([ \t]+[0-9]+\\)\\([ \t]+[0-9]+\\)$" number)
    (message "#%02x%02x%02x"
	     (string-to-number (match-string 1 number))
	     (string-to-number (match-string 2 number))
	     (string-to-number (match-string 3 number))))
   ;; Convert `#xxxxxx' to `d d d'
   ((string-match (concat "^#"
			  "\\([0-9a-fA-F][0-9a-fA-F]\\)"
			  "\\([0-9a-fA-F][0-9a-fA-F]\\)"
			  "\\([0-9a-fA-F][0-9a-fA-F]\\)$") number)
    (message "%d %d %d"
	     (string-to-number (match-string 1 number) 16)
	     (string-to-number (match-string 2 number) 16)
	     (string-to-number (match-string 3 number) 16)))
   (t (error "Invalid"))))

;;;###autoload
(defun load-path-roots ()
  "Show only the root dirs in the `load-path'."
  (interactive)
  (let (dirs)
    (dolist (dir load-path)
      (when (string-match "/lisp/.*" dir)
	(setq dir (replace-match "" nil nil dir)))
      (add-to-list 'dirs dir))
    (if (my-interactive-p) (message "%S" dirs))
    dirs))

(defvar signed-off-by-sig nil
  "* Signature used by `signed-off-by' function.
If nil, defaults to \"`user-full-name' <`user-mail-address'>\".")

;;;###autoload
(defun signed-off-by ()
  (interactive)
  (let ((signed-by (if signed-off-by-sig
		       signed-off-by-sig
		     (concat user-full-name " <" user-mail-address ">"))))
    (save-excursion
      (beginning-of-line)
      (insert (concat "Signed-off-by: " signed-by "\n---\n")))))

;; For when you need a good excuse...
;; From BOHF
(defvar excuse-phrase-file (locate-data-file "excuses.lines")
  "*File containing excuses")

;;;###autoload
(defun excuse (&optional insert)
  "Return or display a random excuse.  With prefix arg, insert it."
  (interactive "P")
  (let ((case-fold-search nil)
	(excuse (concat (cookie excuse-phrase-file "I didn't" "do it"))))
    (if (string-match "^[^A-Z]" excuse)
	(setq excuse (concat "The problem is " excuse)))
    (if (string-match "[^.!?]$" excuse)
	(setq excuse (concat excuse ".")))
    (if insert
	(insert excuse)
      (message excuse))))

;;;###autoload
(defun dup-line (&optional arg)
  "Duplicate the current line.
A negative arg comments out the `new' line[s]."
  (interactive "*p")
  (let ((line (buffer-substring
	       (progn (end-of-line) (point))
	       (progn (beginning-of-line) (point)))))
    ;; The above leaves the point at the start of the current line
    (dotimes (iter arg) (insert line) (newline))))

;; This is a silly little Lisp function for people who don't care
;; exactly what time it is.

(defvar ft-time-strings
  '(("o'clock" t)
    ("quarter past")
    ("half past")
    ("quarter to"))) ;; quarter of

(defvar ft-hour-strings
  '("twelve"
    "one"
    "two"
    "three"
    "four"
    "five"
    "six"
    "seven"
    "eight"
    "nine"
    "ten"
    "eleven"))

(defvar ft-short-version nil
  "*If non-nil display short version of friendly time.
 e.g. 5:30 rather than half past five")

(defun ft-get-time (&optional time)
  "Calculate current hour and quarter of an hour. If `TIME' is nil,
uses current time. Returns (HOUR QUARTER)."
  (let* ((now (decode-time time))
	 (seconds (+ (nth 0 now) (* (nth 1 now) 60)))
	 (hour (nth 2 now))
	 quarter)
    (cond
     ((< seconds  450) (setq quarter 0))
     ((< seconds 1350) (setq quarter 1))
     ((< seconds 2250) (setq quarter 2))
     ((< seconds 3150) (setq quarter 3 hour (1+ hour)))
     (t (setq quarter 0 hour (1+ hour))))
    (if (>= hour 12) (setq hour (- hour 12)))
    (list hour quarter)))

;;;###autoload
(defun friendly-time (&optional show time short)
  "Display a friendly version of the time.
Shows the time to the nearest quarter of an hour."
  (interactive "p")
  (let* ((now (ft-get-time time))
	 (hour (nth 0 now))
	 (quarter (nth 1 now))
	 str)
    (if (or ft-short-version short)
	(setq str (format "%d:%02d" hour (* quarter 15)))
      (let ((ts (nth quarter ft-time-strings)))
	(if (nth 1 ts)
	    (setq str (concat (nth hour ft-hour-strings) " "
			      (nth 0 ts)))
	  (setq str (concat (nth 0 ts) " "
			    (nth hour ft-hour-strings))))))
    (if show (message "%s" str))
    str))

(defun mine (&optional all)
  "Return a list of all my .el files in `dot-dir'. If `all' is
non-nil, returns all .el files in `dot-dir'."
  (let* ((base (file-name-directory user-init-file))
	 (files (directory-files-recursive base ".*\.el$")))
    (unless all
      ;; misc not mine
      ;; also ignore symlinks
      (dolist (file files)
	(when (or (string-match ".*/misc/.*" file)
		  (file-symlink-p file))
	  (setq files (delete file files))))

      (dolist (file '(;; emacs files that are not mine
		      "emacs/rcfiles.el" "emacs/hide-copyleft.el"
		      "emacs/iswitchb.el"
		      ;; xemacs files that are not mine
		      "xemacs/frame-utils.el" "xemacs/introspector.el"
		      "xemacs/ksh-mode.el" "xemacs/time-date.el"
		      ;; generated files
		      "emacs/emacs-loaddefs.el" "lisp/lisp-loaddefs.el"
		      "lisp/auto-autoloads.el" "lisp/custom-load.el"
		      "xemacs/auto-autoloads.el" "xemacs/custom-load.el"
		      ;; ignore this to make comparisons
		      "user-init.el"
		      ))
	(setq files (delete (concat base file) files)))
      )
    files))

;;;###autoload
(defun count-defuns (&optional all)
  (interactive "P")
  (let ((files (mine all))
	(count 0) (lines 0))
    (with-temp-buffer
      (dolist (file files)
	(insert-file-contents-safe file))
      (goto-char (point-min))
      (while (re-search-forward "(\\(defun\\|defmacro\\|defalias\\) " nil t)
	(setq count (1+ count)))
      (goto-char (point-max))
      (setq lines (count-lines (point-min) (point-max))))
    (message "files %d lines %d count %d" (length files) lines count)))