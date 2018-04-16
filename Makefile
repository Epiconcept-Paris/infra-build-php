top:; @date

SHELL := bash

once:; mkdir -p .retry log

roles:; ansible-galaxy install -r requirements.yml


all:; $($@)
$(roles):; $(role)
.Phony: all $(roles)

phony := templates install
$(phony):; ./$@.yml $(DIFF)
.PHONY: $(phony) main
main: $(phony)

ping:; ansible admin2,s1adm,esisdmz -om $@

DIFF :=
DIFF := -D

CHECK := -C
CHECK :=

nodiff := DIFF :=
check  := CHECK := -C
vartar := nodiff check

$(vartar):; @: $(eval $($@))
