ANALYZED_DIRS_MAKEFILES:=$(foreach dir,$(shell cat fc/analyzed-directories.txt),C/testcases/$(dir)/GNUmakefile)

all: C/testcases/GNUmakefile $(ANALYZED_DIRS_MAKEFILES) juliet-patches improve-testcasesupport-patches done

Juliet_Test_Suite_v1.3_for_C_Cpp.zip:
	@echo "Downloading Juliet 1.3 zip from NIST's website..."
	wget https://samate.nist.gov/SARD/testsuites/juliet/Juliet_Test_Suite_v1.3_for_C_Cpp.zip --continue

C/testcases: Juliet_Test_Suite_v1.3_for_C_Cpp.zip
	@echo "Extracting Juliet 1.3 contents..."
	unzip Juliet_Test_Suite_v1.3_for_C_Cpp.zip

# Copy Frama-C scripts and main makefile
C/testcases/GNUmakefile: C/testcases
	@echo "Copying Frama-C scripts..."
	cp fc/testcases-scripts/* C/testcases

# Symbolic links to internal makefile, for each tested directory
$(ANALYZED_DIRS_MAKEFILES): C/testcases/GNUmakefile
	@echo "Installing makefiles for analyzed directories..."
	(cd $(dir $@); ln -s $$(realpath --relative-to $$PWD $(CURDIR)/C/testcases)/GNUmakefile .)

# Apply patches to fix some Juliet 1.3 tests
juliet-patches: C/testcases
ifeq (,$(wildcard ./.juliet-patches-applied))
	@echo "Applying patches to fix some Juliet 1.3 tests..."
	git apply --whitespace=nowarn fc/patches/fix-tests.patch
	@touch .juliet-patches-applied
else
	@echo "juliet patches already applied."
endif

# Apply extra patches to avoid warnings related to RAND*() macros and
# printf modifiers
improve-testcasesupport-patches: C/testcases
ifeq (,$(wildcard ./.improve-testcasesupport-patches-applied))
	@echo "Applying patches to improve RAND*() macros and io.c..."
	git apply --whitespace=nowarn fc/patches/improve-testcasesupport.patch
	@touch .improve-testcasesupport-patches-applied
else
	@echo "improve-testcasesupport patches already applied."
endif

fc/frama-c/build/bin/frama-c: fc/frama-c
	@echo "Locally building and installing Frama-C..."
	(cd fc/frama-c && ./configure --prefix=$$(pwd)/build)
	$(MAKE) -C fc/frama-c -j
	$(MAKE) -C fc/frama-c install

done:
	@echo ""
	@echo "Everything done. Make sure Frama-C is installed,"
	@echo "go to directory C/testcases and run 'make'."

clean:
	rm -rf C
	rm -f .juliet-patches-applied
	rm -f .improve-testcasesupport-patches-applied

.PHONY: done
