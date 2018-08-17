#
#	Pseudo-makefile for waitpid's bin and man
#
TOPDIR=../top
BINDIR=$(TOPDIR)/usr/sbin
MANDIR=$(TOPDIR)/usr/share/man
CFLAGS=-O -Wall -fPIE -fstack-protector-strong -Wall
LDFLAGS=-Wl,-z,relro -Wl,-z,now -pie

all: bin man

bin: waitpid.c
	test -d $(BINDIR) || mkdir -p $(BINDIR)
	cc $(CFLAGS) $(LDFLAGS) -s -o $(BINDIR)/waitpid waitpid.c

man: waitpid.8
	test -d $(MANDIR)/man8 || mkdir -p $(MANDIR)/man8
	cp -p waitpid.8 $(MANDIR)/man8
	gzip -n9 $(MANDIR)/man8/waitpid.8
