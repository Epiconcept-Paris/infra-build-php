#
#	Pseudo-makefile for php_clean_sessions's man
#
TOPDIR=../top
MANDIR=$(TOPDIR)/usr/share/man

all: man

man: php_clean_sessions.8
	test -d $(MANDIR)/man8 || mkdir -p $(MANDIR)/man8
	cp -p php_clean_sessions.8 $(MANDIR)/man8
	gzip -n9 $(MANDIR)/man8/php_clean_sessions.8
