;; From hide-copyleft.c
;; If you're sure you're not gonna get sued, you can do something like this
;; in your .emacs file.

(append copylefts-to-hide
	'((" \\* The Apache Software License, Version 1\\.1" . " \\*/")
	  (" \\* \\$QNXLicenseC:" . " \\* \\$")))
