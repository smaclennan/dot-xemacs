;; XEmacs setup -*- Mode:emacs-lisp -*-
;; This file should work with XEmacs 2x.x

;; Assumes at least the following packages:
;;	xemacs-base, edit-utils, cc-mode, pc

;;{{{ Configuration variables / functions

(defvar running-windoze (eq system-type 'windows-nt))

(defvar running-gtk-xemacs (fboundp 'default-gtk-device))

(defvar running-as-root (string= (user-login-name) "root"))

(setq inhibit-default-init t)

;; With the new package system, there is a greater chance a
;; package may be missing. Instead of an error, just add the
;; package to a list of missing packages and move on.
;; Note: returns non-nil if package exists.

(defvar would-have-liked-list nil
  "List of features that `would-like' and `packagep' could not find.")

(defun would-like (feature &optional no-list)
  "A less strident `require'."
  (condition-case nil
      (require feature)
    (error
     (unless no-list (add-to-list 'would-have-liked-list feature))
     nil)))

(defun packagep (package &optional no-list)
  (if (assq package packages-package-list)
      t
    (unless no-list (add-to-list 'would-have-liked-list package))
    nil))

(defvar have-sound nil)

;;}}}

;;{{{ Basic Customization

(setq debug-on-error t
      track-eol t
      kill-whole-line t
      next-line-add-newlines nil
      delete-key-deletes-forward t
      find-file-compare-truenames t
      signal-error-on-buffer-boundary nil)

(when (file-exists-p (setq custom-file "~/.xemacs/custom.el"))
  (load-file custom-file))

(put 'narrow-to-region 'disabled nil)
(fset 'yes-or-no-p 'y-or-n-p)
(add-hook 'text-mode-hook 'turn-on-auto-fill)

(when (not (emacs-version>= 21 2))
  (setq temp-buffer-shrink-to-fit t))

(would-like 'redo) ;; edit-utils
(would-like 'uncompress) ;; os-utils

;; Needed by ediff - exists in `efs'
(or (boundp 'allow-remote-paths) (setq allow-remote-paths nil))

;; Turn off some modes/functions if they are missing
(mapc '(lambda (func) (or (fboundp func) (fset func 'ignore)))
      (list 'sh-mode 'html-mode))

;; Always turn this mode off
(fset 'xrdb-mode 'ignore)

(paren-set-mode 'paren t)

;; This is defined in apel - here is a simple version
(unless (fboundp 'exec-installed-p)
  (defun exec-installed-p (file)
    "Return absolute-path of FILE if FILE is executable."
    (and running-windoze
	 (not (file-name-extension file))
	 (setq file (concat file ".exe")))
    (if (file-exists-p file)
	t
      (catch 'found
	(dolist (path exec-path)
	  (when (file-exists-p (concat path file))
	    (throw 'found (concat path file))))))))

;; Split the system-name up into host and domain name.
(defvar host-name nil)
(defvar domain-name nil)
(let ((system-name (system-name)))
  (if (string-match "^\\([^.]+\\)\\.\\(.*\\)" system-name)
      ;; fully qualified system-name
      (setq host-name (match-string 1 system-name)
	    domain-name (match-string 2 system-name))
  ;; system-name is host-name
  (setq host-name system-name
	domain-name (getenv "DOMAINNAME"))))

(add-to-list 'paths-default-info-directories "/home/xemacs/packages/info")
(add-to-list 'paths-default-info-directories "~/.xemacs/packages/info")

;; These are missing
(unless (boundp 'lpr-command)
  (setq lpr-command "lpr"
	lpr-switches nil))

(defun uname (&optional arg)
  "`uname arg' as a list. arg defaults to -a"
  (unless arg (setq arg "-a"))
  (let ((uname (exec-to-string (concat "uname " arg)))
	list)
    (while (string-match "\\([^ \n]+\\) ?" uname)
      (setq list (cons (match-string 1 uname) list))
      (setq uname (substring uname (match-end 0))))
    (nreverse list)))

(when (would-like 'http)
  ;; Setup http to use curl rather than wget
  (setq http-wget-program "curl")
  (setq http-wget-options '("-i")))

(defun my-expand-dir-name (name &optional default-dir)
  "Convert directory NAME to absolute, and canonicalize it.
This is guaranteed not to have a / at the end."
  (setq name (expand-file-name name)) ;; this does the bulk of the work
  (when (string-match "/+$" name)
    (setq name (replace-match "" nil nil name)))
  (while (string-match "//+" name)
    (setq name (replace-match "/" nil nil name)))
  name)

;;}}}

;;{{{ Windowing System Customization

(when window-system
  (setq use-dialog-box nil)

  ;; ---------------------------------------------
  ;; Colour
  ;;XEmacs*background: #d0ccb8
  ;;XEmacs*menubar.background: #607860
  ;;XEmacs*menubar.foreground: #d0ccb8
  (when nil
    (set-face-background 'default "#d0ccb8")
    (set-face-background 'gui-button-face "#d0ccb8")
    (set-face-background 'zmacs-region "#cec180")
    ;;(set-face-background 'modeline "#ccc088")
    )
  ;; ---------------------------------------------

  ;; Performance optimizations
  ;; Use C-Insert and Shift-Insert for clipboard
  (setq interprogram-cut-function nil
	interprogram-paste-function nil)

  ;; 21.2.? and up
  (if (boundp 'shifted-motion-keys-select-region)
      (progn
	(setq shifted-motion-keys-select-region t)
	(when (would-like 'pending-del)
	  (setq pending-delete-modeline-string "")
	  (turn-on-pending-delete)))
    ;; use pc-select
    (when (would-like 'pc-select)
      (pc-select-mode t)
      (setq pc-select-modeline-string ""
	    pending-delete-modeline-string ""
	    pc-select-keep-regions t)))

  ;; -------
  ;; Title bar - almost every window system supports a title bar
  (if t
      ;; hostname
      (setq frame-title-format
	    '("XEmacs " emacs-program-version "  " host-name ":"
	      (buffer-file-name "%f" "%b")))
    ;; no hostname
    (setq frame-title-format
	  '("XEmacs " emacs-program-version "  "
	    (buffer-file-name "%f" "%b"))))


  ;; for pwm - add host name to buffers with file names
  (defconst full-host-name (concat host-name ": "))
  (setq frame-icon-title-format
	'((buffer-file-name full-host-name "") "%b"))

  ;; -------
  ;; Menubar
  ;; -------
  (if nil
      ;; Menubar - turn it off to save space
      (set-specifier menubar-visible-p nil)

    (setq menu-accelerator-enabled 'menu-fallback
	  menu-accelerator-modifiers '(alt))

    ;; popup gnus ala toolbar
    (if (packagep 'gnus t)
	(add-menu-item '("Apps") "Usenet News" 'toolbar-gnus t))

    ;; add speedbar
    (when (packagep 'speedbar t)
      (add-menu-button '("Tools")
		       ["Speedbar" speedbar-frame-mode
			:style toggle
			:selected (and (boundp 'speedbar-frame)
				       (frame-live-p speedbar-frame)
				       (frame-visible-p speedbar-frame))]
		       "--")))

  ;; -------
  ;; Toolbar
  (if t
      (set-specifier default-toolbar-visible-p nil)
    (set-default-toolbar-position 'left)
    (when (emacs-version>= 21 5)
      (set-specifier default-toolbar-border-width 1))
    (custom-set-variables '(toolbar-mail-reader (quote vm)))
    (unless running-gtk-xemacs
      (set-specifier toolbar-buttons-captioned-p nil)
      (when (and nil (fboundp 'init-fancy-toolbar))
	;;(init-fancy-toolbar nil)
	;;(init-fancy-toolbar 'color)
	(init-fancy-toolbar 'next)
	))
    )

  ;; -------
  ;; Gutter - turn it off
  ;; Old way
  (when (and (boundp 'default-gutter-visible-p) nil)
    (set-specifier default-gutter-visible-p nil))
  ;; New way
  (when (boundp 'gutter-buffers-tab-enabled)
    (setq gutter-buffers-tab-enabled nil))

  ;; -------
  ;; Pointer used during garbage collection.
  ;; .xbm not supported under windoze
  (let ((img  (locate-data-file "recycle-image.xbm"))
	(mask (locate-data-file "recycle-mask.xbm")))
    (if (and (file-exists-p img) (file-exists-p mask)
	     (not running-windoze))
	(set-glyph-image gc-pointer-glyph
			 (vector 'xbm
				 :file img
				 :mask-file mask
				 :foreground "black"
				 :background "chartreuse1"))
      (set-glyph-image gc-pointer-glyph "recycle2.xpm")))

  ;; -------
  ;; I consider sound to be a "windows" thing
  (when nil
    (load-default-sounds)
    (add-to-list 'default-sound-directory-list "~/sounds")
    (setq have-sound t)
    )

  ;; -------
  ;; MISC

  ;; Handy functions that where hard to work out
  (defun my-get-face-foreground (face)
    (cdr (specifier-specs (face-foreground face) 'global)))
  (defun my-get-face-background (face)
    (cdr (specifier-specs (face-background face) 'global)))
  ;; (my-get-face-background 'default)
  );; window-system

;; Do this *after* setting the modeline colours
(when (fboundp 'display-time)
  (setq display-time-mail-file (expand-file-name "~/Mail/NewLog"))
  (display-time))

;;}}}


;;{{{ Keys

(unless (fboundp 'find-tag-at-point)
  ;; Mimics version from XEmacs 21.2
  (defun find-tag-at-point ()
    "*Find tag whose name contains TAGNAME.
Identical to `find-tag' but does not prompt for tag when called interactively;
instead, uses tag around or before point."
    (interactive)
    (find-tag (if current-prefix-arg
		  (find-tag-tag "Find tag: "))
	      (find-tag (find-tag-default)))))

(defun my-buffer-file-name ()
  (interactive)
  (message "%s:%s" host-name
	   (if buffer-file-name buffer-file-name (buffer-name))))

;; This should always do the right thing?
(global-set-key [(return)] 'newline-and-indent)
(global-set-key [(linefeed)] 'newline)

(defun global-set-keys (keys func)
  (loop for key in keys do
    (global-set-key key func)))

(defun my-toggle-case-search ()
  (interactive)
  (setq case-fold-search (not case-fold-search))
  (when (interactive-p)
    (message "Case sensitive search %s." (if case-fold-search "off" "on"))))

;;;; Function keys. Only f1 is bound in XEmacs. We move to shift-f1.
(global-set-keys '([(shift f1)] [XF86_Switch_VT_1]) (global-key-binding [f1]))
(global-set-key [f1]            'find-file)
(global-set-key [f2] 		'undo)
(global-set-keys '([(shift f2)]	[XF86_Switch_VT_2]) 'redo)
(global-set-key [f3]		'isearch-repeat-forward)
(global-set-keys '([(shift f3)] [XF86_Switch_VT_3]) 'isearch-repeat-backward)
(global-set-key [f4]		'next-error)
(global-set-key [f5]		'query-replace)
(global-set-keys '([(shift f5)] [XF86_Switch_VT_5]) 'query-replace-regexp)
(global-set-key [f6]		'ff-find-other-file)
(global-set-keys '([(shift f6)] XF86_Switch_VT_6) 'my-buffer-file-name)
(global-set-key [f7]		'compile)
(global-set-keys '([(shift f7)] [XF86_Switch_VT_7]) 'make-clean)
(global-set-key [(control f7)]	'my-set-compile)
(global-set-key [f8]		'grep)
(global-set-key [f9]		'my-isearch-word-forward)
(global-set-keys '([(shift f9)] [XF86_Switch_VT_9]) 'my-toggle-case-search)
(global-set-key [f10]		'find-tag-at-point)
(global-set-keys '([(shift f10)] [XF86_Switch_VT_10]) 'pop-tag-mark)
(global-set-key [(control f10)]	'lxr-at-point)
;; I keep f11 free for temporary bindings
(global-set-key [f12]		'revert-buffer)

;; iswitchb
(iswitchb-default-keybindings)
(global-set-key "\C-x\C-b"	'iswitchb-buffer)
(global-set-key "\C-x\C-l"	'list-buffers)

(global-set-key "\C-x\C-k"	'kill-buffer)

;; Hyper-apropos bindings
(define-key global-map [(control h) a] 'hyper-apropos)
(define-key global-map [(control h) c] 'hyper-describe-key-briefly)
(define-key global-map [(control h) f] 'hyper-describe-function)
(define-key global-map [(control h) k] 'hyper-describe-key)
(define-key global-map [(control h) v] 'hyper-describe-variable)
(define-key global-map [(control h) w] 'hyper-where-is)

;; Add some standard directory bindings
(defvar linux-dir (concat "/usr/src/linux-" (car (uname "-r")) "/"))

(define-key read-file-name-map [f1]
  '(lambda () (interactive) (insert linux-dir)))
(define-key read-file-name-map [f2]
  '(lambda () (interactive) (insert linux-dir "include/linux/")))
(define-key read-file-name-map [f3]
  '(lambda () (interactive) (insert linux-dir "include/asm/")))

(if (fboundp 'mwheel-install)
    (progn
      (mwheel-install)
      (setq mwheel-follow-mouse t))
  (would-like 'intellimouse))

;; -------------------------------------------------------
;; The standard blows away emacs just a little to easily
(defun my-save-buffers-kill-emacs ()
  (interactive)
  (when (or (not window-system) (y-or-n-p "Do you have to go? "))
    (save-buffers-kill-emacs)))

(global-set-key "\C-x\C-c"	'my-save-buffers-kill-emacs)
(global-set-key "\C-xw" 	'what-line)

;;(global-set-key "\C-cd"		'dup-line)
(global-set-key "\M-#"		'my-calc)

(global-set-key [(iso-left-tab)] 'tab-to-tab-stop)

;;}}}

;;{{{ Programming Packages

;;; -------------------------------------------------------------------------
;; FONT LOCK
;; See font-lock.el for a description of why it is called font lock.

;; Load it now so we can modify the fonts
(require 'font-lock)

;; Maximum colour but minimum chatter
(setq-default font-lock-maximum-decoration t
	      font-lock-verbose nil
	      font-lock-maximum-size nil)

;; Change a couple of faces
(make-face-bold 'font-lock-function-name-face)
(set-face-foreground 'font-lock-function-name-face "blue")
;; Um, this is the default
;(set-face-foreground 'font-lock-string-face "green4")
(if window-system
    (set-face-foreground 'font-lock-comment-face "FireBrick")
  ;; Consoles have less colors to play with
  (set-face-foreground 'font-lock-comment-face "red")
  (set-face-foreground 'font-lock-string-face "green")
  (set-face-foreground 'font-lock-keyword-face "blue")
  (add-hook 'ediff-load-hook 'my-ediff-colours)
  )

(defun my-set-face (face fg bg &optional prop)
  (set-face-foreground face fg)
  (set-face-background face bg)
  (when prop
    (set-face-property face prop t))
  )

(defun my-ediff-colours ()
  ;; Ediff is really bad
  (my-set-face 'ediff-current-diff-A "black" "yellow")
  (my-set-face 'ediff-current-diff-B "black" "yellow")
  (my-set-face 'ediff-current-diff-C "black" "yellow")
  (my-set-face 'ediff-fine-diff-A    "red"   "yellow")
  (my-set-face 'ediff-fine-diff-B    "red"   "yellow")
  (my-set-face 'ediff-fine-diff-C    "red"   "yellow")
  (my-set-face 'ediff-odd-diff-A     "black" "white" 'highlight)
  (my-set-face 'ediff-odd-diff-B     "black" "white" 'highlight)
  (my-set-face 'ediff-even-diff-A    "black" "white" 'highlight)
  (my-set-face 'ediff-even-diff-B    "black" "white" 'highlight)
  )

;; SAM (add-hook 'font-lock-mode-hook 'turn-on-lazy-shot)

;; Of all the modes, font-lock *least* needs a modeline
;; indicator. If the buffer is colourful, font-lock is on.
;; The only thing you lose is the ability to toggle it.
(let ((el (assq 'font-lock-mode minor-mode-alist)))
  (if el (setcdr el '(""))))

;; -------------------------------------------------------------------------
;; font-lock-extras
;; I want all comments with my initials (SAM) at the start to be very bold
(when (would-like 'font-lock-extras)
  (defun my-font-lock-extras-hook ()
    (cond ((eq major-mode 'emacs-lisp-mode)
	   (setq font-lock-comment-warn-regexp "; ?\\<SAM\\>"))
	  ((or (eq major-mode 'makefile-mode)
	       (eq major-mode 'sh-mode))
	   (setq font-lock-comment-warn-regexp "# ?\\<SAM\\>"))
	  (t ;; cc-modes
	   (setq font-lock-comment-warn-regexp "\\(/\\*\\|//\\) ?\\<SAM\\>")))
    (make-local-variable 'font-lock-fontify-region-function)
    (setq font-lock-fontify-region-function
	  'my-font-lock-fontify-region))
  (add-hook 'emacs-lisp-mode-hook 'my-font-lock-extras-hook)
  (add-hook 'makefile-mode-hook   'my-font-lock-extras-hook)
  (add-hook 'sh-mode-hook         'my-font-lock-extras-hook)
  (add-hook 'c-mode-common-hook   'my-font-lock-extras-hook)

  ;; Perl, as always, is different :-)
  ;; Only do this once!
  (defun my-cperl-mode-hook ()
    (unless cperl-faces-init
      (cperl-init-faces))
    (setq perl-font-lock-keywords-2
	  (append
	   '(("^# ?SAM .*$" 0 font-lock-comment-warn-face t))
	   perl-font-lock-keywords-2))
    (remove-hook 'cperl-mode-hook 'my-cperl-mode-hook))

  (add-hook 'cperl-mode-hook 'my-cperl-mode-hook))

;;; -------------------------------------------------------------------------
;; CC-MODE
;; Customizations for c-mode, c++-mode, java-mode, etc.

;; This hook is run once when cc-mode initializes
(defun my-c-initialization-hook ()
  ;; my style - linux with a smaller tab size
  (c-add-style "sam" '("linux" (c-basic-offset . 4)))
  )
(add-hook 'c-initialization-hook 'my-c-initialization-hook)

;; This hook is run for all the modes handled by cc-mode
(defun my-c-mode-common-hook ()
  (c-set-style "sam")
  (c-toggle-hungry-state 1)  ;; hungry delete
  (setq c-tab-always-indent 'other) ;; real tabs in strings and comments
  (setq tab-width 4)	;; this must match `c-basic-offset'
  (setq case-fold-search nil) ;; C is case sensitive
  )
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

(defun linux-style (&optional dir arg)
  (interactive)
  (c-set-style "linux")
  (setq tab-width 8))

;;; -------------------------------------------------------------------------

(defvar my-compile-dir-linux
  '(;; 2.6 kernels just work
    ("/usr/src/git-2.6/" nil linux-style)
    ("/usr/src/linux-2.6[^/]*/" nil linux-style)
    ;; 2.4 kernels need bzImage and modules for drivers
    ("/usr/src/linux-2.4[^/]*/" "bzImage modules" linux-style)
    ;; Assume /usr/src/linux is 2.4
    ("/usr/src/linux/" "bzImage modules" linux-style)
    )
  "My default Linux directories.")

;; WARNING: Completely overridden in work.el
(defvar my-compile-dir-list my-compile-dir-linux
  "A list of directory matches used by `my-compile-command' to set
the compile command.

Each match is a list. The first, and only required, element is a
regexp for the directory. The second element is an optional target to
pass to make. The third element is an optional lisp function to
call. The lisp function will be passed the directory matched and the
target as parameters.

Only the first match is used so order is important.")


(defun my-compile-command ()
  "Set the compile command for the current file.
Go through the 'my-compile-dir-list' looking for a match.
If we match, the second element is an optional target and the
third argument is an optional function to call. The optional
function will be called after the compile command is set."
  (interactive)
  (let ((list (string-match-list default-directory my-compile-dir-list))
	dir arg func)
    (when list
      (setq dir  (nth 0 list)
	    arg  (nth 1 list)
	    func (nth 2 list))
      (set (make-local-variable 'compile-command)
	   (concat "make -C " dir " " arg))
      (when (fboundp func) (funcall func dir arg)))))
;; Make sure we are *after* my-c-mode-common-hook
(add-hook 'c-mode-common-hook 'my-compile-command 'append)

(defun linux-lxr (dir &optional arg)
  "Things to do in a linux directory"
  ;; lxr
  (set (make-local-variable 'lxr-url) "http://lxr.linux.no/source/")
  (set (make-local-variable 'lxr-base) dir)
  (set (make-local-variable 'lxr-version) nil)
  (set (make-local-variable 'lxr-arch) nil)
  )

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

(defvar include-list '("stdio.h" "stdlib.h" "string.h" "unistd.h" "fcntl.h" "errno.h"))

(defun c-template ()
  (interactive)
  (goto-char (point-min))
  (dolist (include include-list)
    (insert (concat "#include <" include ">\n")))
  (insert "\n\nint main(int argc, char *argv[])\n{\n\t")
  (let ((mark (point)))
    (insert "\n\treturn 0;\n}\n")
    (goto-char mark))
  (add-local-compile-command))

(when (would-like 'smerge)
  (setq smerge-diff-excludes
	'("*.o" "*.obj" "*.a" "*.lib" "*~" ".#*" "CVS" ".svn" ".git"
	  "*.cmd" "*.lo" "*.ko" ".tmp_versions" "*.Plo" "modules.order"))
  (setq smerge-diff-options "-w"))

;;; -------------------------------------------------------------------------
(defvar local-compile-command "gcc -O3 -Wall")

(defun add-local-compile-command ()
  (interactive)
  ;; Currently only for C modes
  (unless (or (eq major-mode 'c-mode) (eq major-mode 'c++-mode))
    (error "Unsupported mode %S" major-mode))
  (save-excursion
    (save-restriction
      ;; Make sure local variables do not exist
      (let* ((case-fold-search t)
	     (file-name (file-name-nondirectory (buffer-file-name)))
	     (cmd (concat local-compile-command " " file-name " -o "
			  (file-name-sans-extension file-name))))
	(when (search-forward "Local Variables:" nil t)
	  (error "Local variables already exist."))
	;; Add it
	(widen)
	(goto-char (point-max))
	(insert "\n/*\n * Local Variables:\n * compile-command: \"" cmd
		"\"\n * End:\n */\n")
	(set (make-local-variable 'compile-command) cmd)
	))))

(defun set-local-compile-command ()
  (interactive)
  (let ((cmd (read-string "Compile: " compile-command)))
    (set (make-local-variable 'compile-command) cmd)))

;;; -------------------------------------------------------------------------
(when (would-like 'vc)
  (setq vc-diff-switches "-u")
  (when (would-like 'vc-ediff)
    (vc-ediff-menubar-init)))

;; -------------------------------------------------------------------------
;; LISP MODE

(defun my-byte-compile-buffer ()
  "Byte compile and load the current buffer.
If `compilation-ask-about-save' is nil, saves the file without asking."
  (interactive)
  (save-some-buffers (not compilation-ask-about-save))
  (emacs-lisp-byte-compile-and-load))

(defun my-emacs-lisp-mode-hook ()
  ;; greedy-delete
  (when (would-like 'greedy-delete)
    (setq gd-indicator-string nil)
    (gd-add-to-mode))
  ;; Redefine compile
  (define-key emacs-lisp-mode-map [f7] 'my-byte-compile-buffer)
  )
(add-hook 'emacs-lisp-mode-hook 'my-emacs-lisp-mode-hook)

;;; -------------------------------------------------------------------------
;; compile variables
(setq compilation-read-command   nil
      compilation-ask-about-save nil
      compilation-window-height  10
      compilation-error-regexp-systems-list (list 'gnu)
      compile-command "make ")

;; This gives the compilation buffer its own frame
;;(push "*compilation*" special-display-buffer-names)

(defun my-set-compile ()
  (interactive)
  (require 'compile)
  (let ((cmd (read-string "Compile Command: " compile-command)))
    (make-local-variable 'compile-command)
    (setq compile-command cmd)
    (save-some-buffers (not compilation-ask-about-save) nil)
    (compile-internal compile-command "No more errors")))


;;; -------------------------------------------------------------------------
;; Audible compilation completion
(defvar loud-compile t "* If t, `ding' when compile finished.")
(defvar compile-ok     nil "*Sound for compile ok")
(defvar compile-failed nil "*Sound for compile failed")

(when have-sound
  (condition-case nil
      (progn
	(load-sound-file "Snicker" 'compile-failed)
	(load-sound-file "YouTheMan" 'compile-ok))
    (error
     (push "Sound" would-have-liked-list))))

(defun loud-finish (buff, exit)
  "If `loud-compile', `ding'. Assign to `compilation-finish-function'."
  (when loud-compile
    (if (string= exit "finished\n")
	(ding nil 'compile-ok)
      (ding nil 'compile-failed))))

(setq compilation-finish-function 'loud-finish)

;;----------------------------------------------------------------
(defvar make-clean-command "make clean all"
  "*Command used by the `make-clean' function.")

(defun make-clean (&optional arg)
  "Run a make clean."
  (interactive "P")
  (require 'compile) ;; needed for compile-internal
  (if arg
      (setq make-clean-command (read-string "Command: " make-clean-command)))
  (save-some-buffers (not compilation-ask-about-save) nil)
  (compile-internal make-clean-command "No more errors"))

;;; -------------------------------------------------------------------------
;; hide-copyleft
;; If you're sure you're not gonna get sued, you can do something like this
;; in your .emacs file:
(when (would-like 'hide-copyleft)
  (add-to-list
   'copylefts-to-hide
   ;; Apache
   '(" \\* The Apache Software License, Version 1\\.1" . " \\*/")
   )
  (add-hook 'emacs-lisp-mode-hook 'hide-copyleft-region)
  (add-hook 'c-mode-common-hook 'hide-copyleft-region))

;;; -------------------------------------------------------------------------
;; tags
(setq tags-build-completion-table nil ;; too slow
      tags-auto-read-changed-tag-files t)

;;; -------------------------------------------------------------------------
;; c macro expansion

(defun c-macro-expand-at-point (subst)
  (interactive "P")
  (let (start end)
    (if (region-exists-p)
	(setq start (region-beginning)
	      end (region-end))
      ;; symbol-near-point from 21.2-b45
      (save-excursion
	(if (or (bobp) (not (memq (char-syntax (char-before)) '(?w ?_))))
	    (while (not (looking-at "\\sw\\|\\s_\\|\\'"))
	      (forward-char 1)))
	(while (looking-at "\\sw\\|\\s_")
	  (forward-char 1))
	(when (re-search-backward "\\sw\\|\\s_" nil t)
	  (forward-char 1)
	  (setq end (point))
	  (forward-sexp -1)
	  (while (looking-at "\\s'")
	    (forward-char 1))
	  (setq start (point)))))
    ;; end of symbol-near-point
    (c-macro-expand start end subst)))

;;; -------------------------------------------------------------------------
(unless running-windoze (would-like 'svn))

(defvar signed-off-by-sig (concat user-full-name " <" user-mail-address ">")
  "* Signature used by `signed-off-by' function.")

(defun signed-off-by ()
  (interactive)
  (save-excursion
    (beginning-of-line)
    (insert (concat "Signed-off-by: " signed-off-by-sig "\n---\n\n"))))

;;}}}

;;{{{ Handy Dandy(tm) Functions

(defun uptime ()
  (interactive)
  (let* ((upminutes (/ (truncate (caddr (current-process-time))) 60))
	 (minutes (% upminutes 60))
	 (hours   (% (/ upminutes 60) 24))
	 (days  (/ upminutes 1440)))
    (message
     (concat "up"
	     (cond ((> days 1) (format " %d days" days))
		   ((= days 1) " 1 day"))
	     (and (> days 0) (> hours 0) ",")
	     (cond ((> hours 1) (format " %d hours" hours))
		   ((= hours 1) (format " 1 hour")))
	     (and (> hours 0) (> minutes 0) " and")
	     (cond ((> minutes 1) (format " %d minutes" minutes))
		   ((= minutes 1) (format " 1 minute")))
	     (and (= upminutes 0) " seconds")
	     ))))

(defun append-to-list (list-var element)
  "Append to the value of LIST-VAR the element ELEMENT if it isn't there yet.
The test for presence of ELEMENT is done with `equal'."
  (or (member element (symbol-value list-var))
      (set list-var (nconc (symbol-value list-var) (list element)))))

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

;;; -------------------------------------------------------------------------
;;  isearch "stuff"

;;  I don't like the way isearch-yank-word defines word, so I rolled my own
(defun my-isearch-yank-word ()
  "Pull current word from buffer into search string.
Use region if it exists. My replacement for isearch-yank-word."
  (interactive)
  (let ((word (if (region-exists-p)
		  (buffer-substring (region-beginning) (region-end))
		(current-word))))
    (forward-char 1) ;; make sure we are not on first char of word
    (isearch-yank word)))

;; Warning: If you change this binding, change `my-isearch-word-forward'
(define-key isearch-mode-map "\C-w"		'my-isearch-yank-word)

(define-key isearch-mode-map [f3]		'isearch-repeat-forward)
(define-key isearch-mode-map [(shift f3)]	'isearch-repeat-backward)
(define-key isearch-mode-map "\C-t"		'isearch-toggle-case-fold)

(defun my-isearch-word-forward (&optional regexp-p)
  "Search for current word. Region is used if set."
  (interactive "_P")
  ;; Push the C-w and call 'isearch-forward'
  (setq unread-command-events
	(list (make-event 'key-press '(key ?w modifiers (control)))))
  (isearch-mode t (not (null regexp-p)) nil (not (interactive-p))))

;;; -------------------------------------------------------------------------
(when (packagep 'igrep running-windoze)
  ;;(igrep-insinuate)
  (global-set-key [f8] 'igrep)
  (global-set-key [(shift f8)] 'igrep-find)
  (setq igrep-verbose-prompts nil)
  (put 'igrep-files-default 'c-mode (lambda () "*.[ch]"))
  (put 'igrep-files-default 'emacs-lisp-mode (lambda () "*.el")))

;; For ispell
(setq ispell-silently-savep t
      ispell-extra-args '("-W" "3"))

;; For aspell
(when (exec-installed-p "aspell")
  (setq-default ispell-program-name "aspell"))

;;; -------------------------------------------------------------------------
;; For when you need a good excuse...

(defvar excuse-phrase-file
  (or (locate-data-file "excuses.lines")
      (expand-file-name "~/.xemacs/excuses.lines"))
  "*File containing excuses")

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

;;; -------------------------------------------------------------------------
(defun dup-line (&optional arg)
  "Duplicate the current line.
A negative arg comments out the `new' line[s]."
  (interactive "*p")
  (let ((line (buffer-substring
	       (progn (end-of-line) (point))
	       (progn (beginning-of-line) (point)))))
    ;; The above leaves the point at the start of the current line
    (dotimes (iter arg) (insert line) (newline))))

;;}}}

;;{{{ Packages

;; C-h =
(would-like 'introspector)

;; SAM For some reason this causes a compile window to pop up.
;;     I don't use it, so just leave it off.
;; (when (would-like 'folding) (folding-mode nil t))

(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward)

(when (would-like 'ediff-hook)
  ;;(ediff-toggle-use-toolbar)
  )

(when (would-like 'browse-kill-ring)
  (global-set-key (kbd "C-c k") 'browse-kill-ring))

;; SAM (when (would-like 'tramp)
;; SAM  (setq tramp-default-method "sm")
;; SAM  )

;; tramp needs this
;; (subtract-time '(13818 19266) '(13818 19145))
;; => (0 121)
(unless (fboundp 'subtract-time)
  ;; This is just time-sub from comics.el
  (defun subtract-time (t1 t2)
    "Subtact two lisp time values.
The time values are stored as a list of three 16-bit numbers.
We ignore the 3rd number."
  (let ((t1-lo (cadr t1))
	(t1-hi (car t1))
	(t2-lo (cadr t2))
	(t2-hi (car t2)))
    (when (> t2-lo t1-lo)
	(setq t1-hi (- t1-hi 1))
	(setq t1-lo (+ t1-lo 65536)))
    (list (- t1-hi t2-hi) (- t1-lo t2-lo)))))

;; -------------------
;; Hack to put the ediff control in the window (rather than off it)
;; Needed for window manager like PWM that do not honor the window move
;; request. The window will look strange until XEmacs updates it.
(defvar ediff-control-frame-position (list (cons 'top 10) (cons 'left 10))
  "* Where to put the control frame on the screen.")

(defun ediff-control-frame-hack ()
  (setq ediff-control-frame-parameters
	(remassq 'left
		 (remassq 'top ediff-control-frame-parameters)))
  (setq ediff-control-frame-parameters
	(nconc ediff-control-frame-parameters ediff-control-frame-position)))

(add-hook 'ediff-load-hook 'ediff-control-frame-hack)
;; -------------------

;; So ftp will work
(when (would-like 'efs)
  (setq efs-ftp-program-args (append efs-ftp-program-args '("-p"))))

;; for pui-list-packages
;;(if t
;;    ;; remote
;;    (setq package-get-remote '(("ftp.xemacs.org" "/pub/xemacs/packages")))
;;  ;; local
;;  (setq package-get-remote '((nil "~/.xemacs"))))
;;(setq package-get-remote '(("ftp.xemacs.org" "/pub/xemacs/beta/experimental")))
(setq package-get-require-signed-base-updates nil)
;; Turn off the automatic ftp of missing packages
;;(fset 'package-get-package-provider 'ignore)

;;; -------------------------------------------------------------------------
;; The auto-save.el and backup.el packages collect files in one place
;; I added the following to my crontab:
;; # Cleanup the autosave and backup directories (24 * 7 = 168)
;; 0 4 * * * /usr/sbin/tmpwatch 168 $HOME/.autosave $HOME/.backup

(when (would-like 'auto-save)
  (setq auto-save-directory "~/.autosave/")
  ;; Now that we have auto-save-timeout, let's crank this up
  ;; for better interactive response.
  (setq auto-save-interval 2000))

(would-like 'backup)

;;; -------------------------------------------------------------------------
;;; Filladapt is a syntax-highlighting package.  When it is enabled it
;;; makes filling (e.g. using M-q) much much smarter about paragraphs
;;; that are indented and/or are set off with semicolons, dashes, etc.

(when (would-like 'filladapt)
  (add-hook 'text-mode-hook 'turn-on-filladapt-mode)
  (add-hook 'mail-mode-hook 'turn-on-filladapt-mode))

;;; ----------------------------------------------
;; Calendar

;; Where in the world is Ottawa?
;; Source: http://www.infoplease.com/ipa/A0001796.html
(setq calendar-location-name "Ottawa, ON"
      calendar-latitude  '[45 24 north]
      calendar-longitude '[75 43 west])

(setq christian-holidays nil
      hebrew-holidays nil
      islamic-holidays nil
      oriental-holidays nil)

;; Use the function holiday-easter-etc to get easter monday
;; Look at `holiday-easter-etc' to see why I don't calculate by hand.
(defun easter-monday ()
  (if (or (< displayed-month 3) (> displayed-month 5))
      nil
    (let* ((all-christian-calendar-holidays nil)
	   (date (holiday-easter-etc)))
      (while (cdr date) (setq date (cdr date))) ;; find easter sunday
      (list (list (list 4 (+ (nth 1 (caar date)) 1) displayed-year)
		  "Easter Monday")))))

;; Standard holidays too UScentric
(setq general-holidays
      '((holiday-fixed  1  1	"New Year's Day")
	(holiday-fixed  2  2	"Groundhog Day")
	(holiday-fixed  2 14	"Valentine's Day")
	(holiday-fixed  3 17	"St. Patrick's Day")
	(holiday-fixed  4  1	"April Fools' Day")
	(easter-monday)
	(holiday-float  5  0  2	"Mother's Day")
	(holiday-float  5  1 -1	"Victoria Day" 24)
	(holiday-float  6  0  3	"Father's Day")
	(holiday-fixed  7  1	"Canada Day")
	(holiday-fixed  7 17    "Slackware 1.00 1993")
	(holiday-float  8  1  1 "Civic Holiday")
	(holiday-fixed  8 16    "Debian 1993")
	(holiday-fixed  8 18    "Jeanine's Birthday")
	(holiday-float  9  1  1	"Labour Day")
	(holiday-fixed  9 17	"Linux 0.01 1991")
	(holiday-float 10  1  2	"Thanksgiving")
	(holiday-fixed 10 31	"Halloween")
	(holiday-fixed 11  3    "Unix V1 1971")
	(holiday-fixed 11 11	"Rememberance Day")
	(holiday-fixed 12 25	"Christmas")
	(holiday-fixed 12 26	"Boxing Day")
	))

(setq mark-holidays-in-calendar t)

;; Show today as '**'
;;(add-hook 'today-visible-calendar-hook 'calendar-star-date)

;; Diary stuff
(setq diary-file "~/.dear-diary")

;;; ------------------------------------------------------------
;; Start the server program
(unless (or running-windoze running-as-root)
  (gnuserv-start)
  (setq gnuserv-frame (selected-frame)))

;;; ----------------------------------------------
;; Whitespace mode handy for tabs - ignore spaces
;; From text-modes
(setq whitespace-chars 'tabs)
(setq whitespace-install-submenu t)

;; folding-mode
;; Folding mode does not work with isearch
(when nil
(when (would-like 'folding)
  (setq folding-mode-menu-name "Fold")
  (folding-mode-add-find-file-hook)
  (fold-add-to-marks-list 'makefile-mode "# {{{ " "# }}}" nil t))
)

(setq dired-no-confirm '(kill-file-buffer))

;;; ----------------------------------------------
;; These come from the site-lisp directory

;; ws-trim-mode
(when (would-like 'ws-trim)
  (global-ws-trim-mode t)
  (setq ws-trim-mode-line-string nil)
  (set-default 'ws-trim-level 1))

(when nil
(when (packagep 'dired-extras)
  (add-hook 'dired-load-hook 'dired-extras-init)
  (setq dired-listing-switches "-l"))
)

;;; ----------------------------------------------
;; oo-browser

(defun oo-browser-start ()
  (interactive)
  (unless (packagep 'oo-browser) (error "oo-browser not installed"))
  (dolist (path load-path)
    (if (string-match "/oo-browser/$" path)
	(append-to-list 'load-path (concat path "hypb/"))))
  (require 'br-start)
  (global-set-key "\C-c\C-o" 'oo-browser)
  (oo-browser))

(global-set-key "\C-c\C-o" 'oo-browser-start)

;;}}}

;;{{{ Mail/News/Web

;; Most of this is in .vm and .gnus.el
;; However, this is done up front so things like `build-report' will work
;; Authorization in .authrc

(require 'smtpmail)
(setq send-mail-function 'smtpmail-send-it) ; for `sendmail' (vm)
(setq message-send-mail-function 'smtpmail-send-it) ; for `message' (gnus)
(setq user-mail-address (concat (user-login-name) "@" domain-name))
(setq smtpmail-smtp-server "mail.dsl.ca")
(setq smtpmail-local-domain domain-name)
;;(setq smtpmail-debug-info t)

;; Domain specific mail
(let ((domain-specific-init (concat "~/.xemacs/mail-" domain-name)))
  (when (file-exists-p domain-specific-init)
    (load domain-specific-init)))

;; Move the .vm init file to .xemacs
(setq vm-init-file "~/.xemacs/vm-init.el"
      vm-folders-summary-database "~/.xemacs/.vm.folders.db")

;; browse-url and vm-url-browser
(cond
 ((exec-installed-p "firefox")
  (setq browse-url-browser-function 'browse-url-firefox
	vm-url-browser 'vm-mouse-send-url-to-mozilla))
 ((exec-installed-p "mozilla")
  (setq browse-url-browser-function 'browse-url-mozilla
	vm-url-browser 'vm-mouse-send-url-to-mozilla))
 ((exec-installed-p "netscape")
  (setq browse-url-browser-function 'browse-url-netscape
	vm-url-browser 'vm-mouse-send-url-to-netscape))
 ((exec-installed-p "opera")
  (setq browse-url-browser-function 'browse-url-opera))
 ((packagep 'w3 t)
    (setq browse-url-browser-function 'browse-url-w3))
 ((exec-installed-p "lynx")
  (setq browse-url-browser-function 'browse-url-lynx-emacs)))

;; GNUS
(setq gnus-init-file "~/.xemacs/gnus.el")

;; html
;;(defcustom html-helper-htmldtd-version "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n"

;;}}}

(when running-windoze
  (load "~/.xemacs/windoze" t))

;; For work
(load "~/.xemacs/work" t)

;; I use a common init.el across many machines. The `user-init' file
;; allows for user/machine specific initialization.
;; Load the login user name in case of sudo xemacs.
(load (concat "~" (user-login-name) "/.xemacs/user-init") t)

;;{{{ Final results

(setq debug-on-error nil)

(if would-have-liked-list
    ;; Warn that some features not found
    (progn (ding) (message "Features not found: %S" would-have-liked-list))
  ;; Else display a friendly message
  (let ((hour (nth 2 (decode-time))))
    (message "Good %s %s"
	     (cond ((< hour 12) "morning")
		   ((< hour 18) "afternoon")
		   (t           "evening"))
	     (user-full-name))))

(setq initial-scratch-message
      ";; This buffer is for goofing around in.
;; All data will be destroyed on exit.

")

;;}}}

;; Local variables:
;; folded-file: nil
;; folding-internal-margins: nil
;; end:

;; end of .emacs "May the `(' be with `)'"
