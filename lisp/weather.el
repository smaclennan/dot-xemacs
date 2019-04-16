(defvar weather-url "https://weather.gc.ca/city/pages/on-118_metric_e.html"
  "The url for the weather. Must be weather.gc.ca.")

;;;###autoload
(defun weather ()
  (interactive)
  (let (gif tempc tempf conditions giffile)
    (with-current-buffer (url-retrieve-synchronously weather-url t)
      (goto-char (point-min))
      (re-search-forward "src=\"/\\(weathericons/[0-9]+\\.gif\\)\" alt=\"\\([^\"]+\\)")
      (setq gif (match-string 1))
      (setq conditions (match-string 2))
      (re-search-forward "class=\"wxo-metric-hide\">\\([0-9]+\\)")
      (setq tempc (match-string 1))
      (re-search-forward "class=\"wxo-imperial-hide wxo-city-hidden\">\\([0-9]+\\)")
      (setq tempf (match-string 1)))

    ;; get the gif if necessary
    (setq giffile (concat "~/." gif))
    (unless (file-exists-p giffile)
      (let ((gifurl (concat "https://weather.gc.ca/" gif)))
	(with-current-buffer (url-retrieve-synchronously gifurl t)
	  (goto-char (point-min))
	  (let ((case-fold-search nil)) (search-forward "GIF"))
	  (delete-region (point-min) (match-beginning 0))
	  (write-file giffile))))

    (with-current-buffer (get-buffer-create "*weather*")
      (erase-buffer)
      (insert-image (create-image giffile))
      (insert " " conditions " " tempc "\u2103 " tempf "\u2109\n"))

    (display-buffer-at-bottom (get-buffer "*weather*") '((window-height . 6)))
    ))
