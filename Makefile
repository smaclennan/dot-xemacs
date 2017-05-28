.PHONY: all elcs clean

# When building inside of Emacs it seems EMACS=t
ifeq ($(EMACS),t)
EMACS=
endif

ifeq ($(EMACS),)
BASE=$(shell basename $(PWD))
ifeq ($(BASE),.sxemacs)
EMACS := sxemacs
else ifeq ($(BASE),.xemacs)
EMACS := xemacs
else
EMACS := emacs
endif
endif

all:
	@echo $(MAKE) $(EMACS) ...
ifeq ($(EMACS),emacs)
	$(MAKE) EMACS=$(EMACS) -C esp
	$(MAKE) EMACS=$(EMACS) -C site-packages/lisp
else
	$(MAKE) EMACS=$(EMACS) -C site-packages/lisp
endif

elcs:
	$(MAKE) EMACS=$(EMACS) -C site-packages/lisp elcs

clean:
	@echo Clean $(EMACS) ...
	rm -f *.elc
	$(MAKE) -C site-packages/lisp EMACS=$(EMACS) clean
	$(MAKE) -C esp EMACS=$(EMACS) clean

clean-sam:
	$(MAKE) -C site-packages/lisp/sam clean
