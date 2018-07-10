.SUFFIXES: .el .elc
.PHONY: first-rule

first-rule: all

DIR := $(shell pwd)
SUBDIR := $(shell basename $(DIR))

# When building inside of Emacs it seems EMACS=t
ifeq ($(EMACS),t)
EMACS=
endif

ifeq ($(EMACS),)
ifneq ($(findstring .xemacs, $(DIR)),)
EMACS=xemacs
else
ifneq ($(findstring .sxemacs, $(DIR)),)
EMACS=sxemacs
else
EMACS=emacs
endif
endif
endif

ifeq ($(findstring xemacs,$(EMACS)),)
# GNU Emacs

HELPER := -l ~/.emacs.d/esp/esp

$(SUBDIR)-loaddefs.el:
	@echo Create $(EMACS) $(SUBDIR)-loaddefs.el ...
	@$(EMACS) -batch -q $(HELPER) -l build-loaddefs.el -f build-loaddefs

LOAD_FILES=$(SUBDIR)-loaddefs.el

else
# XEmacs

VERSION := $(shell $(EMACS) -V | cut -d' ' -f2)

auto-autoloads.el:
ifeq ($(EMACS),sxemacs)
	$(EMACS) -batch -f batch-create-autoloads .
else
  ifeq ($(VERSION),21.4)
	$(EMACS) -batch -q -no-site-file -l autoload \
		-f batch-update-directory .
  else
	$(EMACS) -batch -q -no-site-file -l autoload \
		-f batch-update-directory-autoloads $(SUBDIR) .
  endif
endif

custom-load.el: $(LISP)
	$(EMACS) -batch -vanilla -l cus-dep -f Custom-make-dependencies .

LOAD_FILES=auto-autoloads.el custom-load.el

endif

.el.elc:
	$(EMACS) -batch -q $(HELPER) -f batch-byte-compile $<
	@rm -f $(LOAD_FILES)