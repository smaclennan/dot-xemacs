(setq-default compile-command "gmake ")
(setq make-clean-command "gmake clean all")

(setq local-compile-cc "cc -O2 -Wall")
(setq local-compile-c++ "c++ -O2 -Wall")

(defvar sys-page-size nil "Page size filled in by `sys-mem'.")

(load "cpuid" nil noninteractive)
(load "unix"  nil noninteractive)

;;;###autoload
(defun sys-nproc ()
  "Return number of cpus."
  (if sys-nproc
      sys-nproc
    (setq sys-nproc (sysctl "hw.ncpu"))))

;;;###autoload
(defun sys-mem ()
  "Return total and free memory."
  (if (file-exists-p "/proc/meminfo") ;; NetBSD
      (sys-meminfo)
    (unless sys-page-size (setq sys-page-size (sysctl "hw.pagesize")))
    (unless sys-mem (setq sys-mem (sysctl "hw.realmem")))
    (list sys-mem
	  (* (sysctl "vm.stats.vm.v_free_count") sys-page-size))))
