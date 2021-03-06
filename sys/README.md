# System Specific Information

This directory is an attempt to put system and Emacs version specific
code in one place.

Currently supported: Linux, QNX, BSD, and Windows.

We try to support GNU Emacs >= 24. The basic strategy is to keep up to
date with the latest version and backport changes to previous
releases. We cannot guarantee that previous releases work fully.

## Basic variables

* sys-arch
  * always set
* sys-mem
  * filled in by sys-mem()
  * filled in by sys-nproc() on QNX
* sys-nproc
  * filled in by sys-nproc()
  * filled in by sys-mem() on QNX

## Basic functions

* sys-os
  * os (distro for Linux) and release
* sys-nproc
  * number of cpus (Linux definition of cpu)
* sys-mem
  * total, free, and available memory
  * only Linux provides available memory
* sys-cpuinfo
  * see below for output
  * BSD, QNX require cpuid installed
* sys-cpuflags
  * cpu flags
  * BSD, QNX, Windows require cpuid installed
* sys-is-guest
  * is the system a guest or virtual machine
  * does not work for arm Linux
  * BSD, QNX, Windows require cpuid installed
* sysctl
  * return sysctl arg as a number
  * not supported on Windows

### sys-cpuinfo

The output currently only works for x86 everywhere and arm Linux.

Sample x86_64 output: model_name, vendor, family, model, stepping

    ("Intel(R) Core(TM) i7-3630QM CPU @ 2.40GHz" "Intel" 6 58 9)

Sample arm output: model_name, vendor id, architecture, variant, part

    ("ARMv7 Processor rev 0 (v7l)" "ARM" 7 0 3081)
