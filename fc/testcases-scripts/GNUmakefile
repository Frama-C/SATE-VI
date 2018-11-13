# Do not run this Makefile directly!
# Each subdirectory should contain a symbolic link (named 'GNUmakefile') to
# this one.

makefile_dir:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

RSYNC := $(shell command -v rsync 2> /dev/null)

ifeq ($(makefile_dir),$(shell pwd)/)
# Running make from top-level directory: compute summary
summary:
	./run_all_makes.sh
	./summarize_results.sh | tee results_summary.txt
	# copy results for versioning
	cp results_summary.txt ../..
ifdef RSYNC
	$(RSYNC) --archive --prune-empty-dirs --checksum \
	  --include="*.csv" --include="*.res" --include="*/" --exclude="*" \
	  $(PWD)/ ../../oracles/
else
	$(info rsync not available, not updating oracles)
endif

else
# Running make from a subdirectory: run tests

TARGETS=$(shell find . -regextype posix-extended -regex '.*[0-9]a?.c' ! -regex ".*w32.*" | sed 's/a\.c/.c/')

all: $(addsuffix _bad.res,$(TARGETS:%.c=%)) \
     $(addsuffix _good.res,$(TARGETS:%.c=%))

%_good.res: %.c
	@echo "testing $(PWD)/$(patsubst %_good.res,%.c,$@) (good)"
	@GB="good" BASE="$(patsubst %_good.res,%.c,$@)" DIR="$(PWD)" \
		$(makefile_dir)/../../fc/evaluate_case.sh

# for multifile tests
%_good.res: %a.c
	@echo "testing $(PWD)/$(patsubst %_good.res,%.c,$@) (good)"
	@GB="good" BASE="$(patsubst %_good.res,%.c,$@)" DIR="$(PWD)" \
		$(makefile_dir)/../../fc/evaluate_case.sh

%_bad.res: %.c
	@echo "testing $(PWD)/$(patsubst %_bad.res,%.c,$@) (bad)"
	@GB="bad" BASE="$(patsubst %_bad.res,%.c,$@)" DIR="$(PWD)" \
		$(makefile_dir)/../../fc/evaluate_case.sh

# for multifile tests
%_bad.res: %a.c
	@echo "testing $(PWD)/$(patsubst %_bad.res,%.c,$@) (bad)"
	@GB="bad" BASE="$(patsubst %_bad.res,%.c,$@)" DIR="$(PWD)" \
		$(makefile_dir)/../../fc/evaluate_case.sh

%_good.gui: %_good.res
	GB="good" BASE="$(patsubst %_good.gui,%.c,$@)" DIR="$(PWD)"\
		$(makefile_dir)/../../fc/evaluate_case.sh -gui

%_bad.gui: %_bad.res
	GB="bad" BASE="$(patsubst %_bad.gui,%.c,$@)" DIR="$(PWD)" \
		$(makefile_dir)/../../fc/evaluate_case.sh -gui

clean:
	rm -f *.res *_good *_bad *.csv

.PHONY: clean
endif
