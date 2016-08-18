#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#

#
# Copyright 2014 (c) Joyent, Inc.  All rights reserved.
#

PYTHON =	python
MDPATH =	./support
MD = 		$(MDPATH)/markdown2.py
TOC =		./support/gentoc.sh

HEADER =	assets/header.html
TRAILER =	assets/trailer.html

BOOTSTRAP_MIN =		.min
BOOTSTRAP_TYPES =	css img js
BOOTSTRAP_FILES = \
	css/bootstrap$(BOOTSTRAP_MIN).css \
	img/glyphicons-halflings-white.png \
	img/glyphicons-halflings.png \
	js/bootstrap$(BOOTSTRAP_MIN).js

MDARGS = \
	--extras fenced-code-blocks \
	--extras wiki-tables \
	--extras link-patterns \
	--extras header-ids \
	--link-patterns-file support/link-patterns.txt

IMAGE_FILES = \
	illumos_phoenix_small.png

FILES = \
	intro \
	workflow \
	guidelines \
	layout \
	anatomy \
	debugging \
	integrating \
	help \
	glossary \
	license

OUTDIR =	output
BOOTSTRAP_OUTDIRS = \
	$(BOOTSTRAP_TYPES:%=$(OUTDIR)/bootstrap/%)

OUTFILES = \
	$(FILES:%=$(OUTDIR)/%.html) \
	$(IMAGE_FILES:%=$(OUTDIR)/img/%) \
	$(BOOTSTRAP_FILES:%=$(OUTDIR)/bootstrap/%)


all: $(OUTDIR) $(BOOTSTRAP_OUTDIRS) $(OUTFILES)

$(OUTDIR):
	mkdir -p "$@"

$(OUTDIR)/img:
	mkdir -p "$@"

$(BOOTSTRAP_OUTDIRS):
	mkdir -p "$@"

$(OUTDIR)/%.html: % $(HEADER) $(TRAILER) $(OUTDIR)
	sed '/<!-- vim:[^:]*: -->/d' $(HEADER) > $@
	$(TOC) $< $(FILES) >> $@
	$(PYTHON) $(MD) $(MDARGS) $< >> $@
	sed '/<!-- vim:[^:]*: -->/d' $(TRAILER) >> $@

$(OUTDIR)/img/%: assets/% $(OUTDIR)/img
	cp $< $@
	touch $@

$(OUTDIR)/bootstrap/%: assets/bootstrap/% $(BOOTSTRAP_OUTDIRS)
	cp $< $@
	touch $@

clean: clobber

clobber:
	rm -rf output

FRC:
