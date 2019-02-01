;; hmac.el - Hash-based Message Authentication Code
;; Copyright (C) 2013 Sean MacLennan <seanm@seanm.ca>
;; Based on RFC 2104
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 2 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this project; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

(defconst hmac-blocksize 64)

(defun hmac (key msg hash-func digest-length)
  "Given a key, a message, a hash function, and the hash digest length, return the HMAC of the message.
The output is in binary, use `encode-hex-string' to make it readable.
Note: The hash-func must be the binary version. (e.g. sha1-binary)."
  (let (o-pad i-pad (key-len (length key)))

    (if (> key-len hmac-blocksize)
	(setq key (concat (apply hash-func key nil)
			  (make-string (- hmac-blocksize digest-length) 0)))
      (setq key (concat key (make-string (- hmac-blocksize key-len) 0))))

    (setq o-pad (make-string hmac-blocksize 0))
    (setq i-pad (make-string hmac-blocksize 0))

    (cl-loop for i from 0 below hmac-blocksize do
      (aset o-pad i (logxor (aref key i) #x5c))
      (aset i-pad i (logxor (aref key i) #x36)))

    (apply hash-func (concat o-pad (apply hash-func (concat i-pad msg) nil)) nil)))

(defun hmac-sha1-binary (string) (sha1 string nil nil t))

;; Probably not the most efficient
(defun encode-hex-string (binary)
  (let ((len (length binary)) str)
    (cl-loop for i from 0 below len do
	  (setq str (concat str (format "%02x" (aref binary i)))))
    str))

; (encode-hex-string (hmac "key" "abc" 'hmac-sha1-binary 20))
; => "4fd0b215276ef12f2b3e4c8ecac2811498b656fc"

(provide 'hmac)
