Frama-C's repository for SATE VI tests (Juliet 1.3 for C/C++)
=============================================================

Frama-C 18 (Argon) can be used to run C tests for
NIST's Juliet 1.3 Test Suite for C/C++, as part of the
[SATE](https://samate.nist.gov/SATE.html) tool exposition.
This repository contains scripts to reproduce the tests.

To run them, you will need:

- Frama-C 18 (Argon) installed in your PATH
  - Alternatively, you can copy Frama-C sources to directory `fc/frama-c`.
    The scripts will then compile and use that version of Frama-C when running
    the tests.

- [GNU make](https://www.gnu.org/software/make/)

- [GNU parallel](https://www.gnu.org/software/parallel/)

- Bash 4.0+

- [wget](https://www.gnu.org/software/wget/) to download and extract the
  [Juliet 1.3 for C/C++](https://samate.nist.gov/SARD/testsuite.php).
  Alternatively, you can download it yourself and place it in this directory.
  - Note: Juliet 1.3 for C/C++ is a ~150 MB zip;
    its uncompressed size is about 600 MB.

- [rsync](https://rsync.samba.org/) (optional) to update the versioned test
  oracles after running all tests

Usage
-----

1. Frama-C installation - choose one:

      a. Install Frama-C 18 (Argon);

      b. **OR** put a copy of the Frama-C uncompressed sources in `fc/frama-c`
         and run (to configure and locally install Frama-C):

          make fc/frama-c/build/bin/frama-c

2. Run `make all`. This should download Juliet 1.3 for C/C++, unzip it, copy the
   required Frama-C scripts and makefiles, and apply some patches.

3. Run `cd C/testcases`, then `make`. This will analyze _all_ directories
   supported by Frama-C (about 45,000 tests) and output a summary in the end.

   Note: running all tests typically takes over 2 hours on a fast desktop.
         Every 5 seconds, a message indicates how many tests have been processed
         so far, which serves as a rough estimate.


Selected directories and files
------------------------------

The list of directories successfully analyzed with Frama-C is available in
`fc/analyzed-directories.txt`. In each of those directories, all C tests
that were not Windows-specific were analyzed.

In other words, Windows-specific tests (containing `_w32_` in their filename)
and C++ tests were _not_ analyzed.


Bug detection via the Eva plug-in
---------------------------------

Frama-C's Eva plug-in has been developed to show the absence of runtime errors
on whole programs. When applied to the tests in Juliet, it enables the
detection of classes of bugs that are related to runtime errors.

Eva is run with a fixed set of parameters, defined in `analyze.sh`
(details about the parameters used in the script are available in the
[Frama-C blog post about SATE VI - Juliet](http://blog.frama-c.com/index.php?post/2018/11/15/Frama-C/Eva-in-SATE-VI-with-Juliet-1.3))
.
The bugs identified by the analysis are those that correspond to undefined
behaviors (or, in some cases, unspecified or implementation-defined behaviors).
Some of the bugs are detected by the Frama-C kernel or the Variadic
plug-in, in combination with Eva.

Eva's classification of runtime errors is not currently mapped to CWEs;
after Frama-C/Eva is run on a program, another script (`evaluate_case.sh`)
checks the output to see if any warnings/alarms were generated, and if so,
categorizes the tests in one of the following cases:

- `ok`: either the test was a "good" one (no bugs), and Frama-C reported no
  alarms/warnings, or the test was a "bad" one (presence of one or more bugs)
  and Frama-C emitted an alarm/warning;

- `imprecise`: the test was a "good" one (no bugs), but Frama-C emitted an
  alarm/warning;

- `unsound`: the test was a "bad" one (presence of one or more bugs), and
  Frama-C did not report any alarms/warnings. This should NOT happen for
  any of the analyzed test directories, after the proper patches are applied
  (see next section).

- `timeout`: the test took too long (>30s). This should not happen unless
  the test machine is overloaded.

- `non-terminating (and no grepped alarms/warnings)`: special case for a few
  tests which are non-terminating on purpose. Equivalent to `ok` when inside
  directory `CWE835_Infinite_Loop`, otherwise may indicate an issue with the
  parametrization.

A few other statuses are possible in the script, mainly for future development
and/or debugging, such as `missing spec` (for stdlib functions without
specifications).


Patches applied to some tests
-----------------------------

Two sets of patches were applied as part of the `make all` command above.

During the analysis with Frama-C, some "good" tests were identified as actually
containing bugs or undefined behaviors. These tests had to be patched to ensure
that Frama-C would correctly label them. The patches can be applied to a fresh
copy by running

    make juliet-patches

Without the above patches, Frama-C will report `unsound (non-termination)`
for some tests in the affected directories.

Another set of patches allows Frama-C to obtain more precise results
by changing some files in `C/testcasesupport`:

1. `RAND*()` macros in `C/testcasesupport/std_testcase.h` are modified as
   follows:

    - Added macros for `RAND16()` and `RAND8()`, for `short` and `char` types
      respectively;

    - Modified macros `RAND32()` and `RAND64()` to avoid overflows.

    These patches, combined with the replacement of calls to `(char)RAND32()`
    with `RAND8()` and calls to `(short)RAND32()` with `RAND16()`, ensure
    Frama-C does not report alarms about overflows in downcasts related to the
    usage of these macros.

2. Some calls to `printf` in `C/testcasesupport/io.c` are modified to use
   `char` modifiers (`hh`) when printing values of type `char`, e.g.
   `%02hhx` to print a char as hexadecimal. This prevents Frama-C
   (more specifically, the Variadic plug-in) from emitting some warnings.

These patches can be applied to a fresh copy by running

    make improve-testcasesupport-patches

Without the above patches, Frama-C will report `imprecise` in some "good"
tests.


Sources and headers used by Frama-C
-----------------------------------

Frama-C's standard library provides specifications for several functions used
by Juliet tests. These specifications are optimized for performance, to be used
in code bases of unknown size. However, Frama-C also provides implementations
for some libc functions, which improve the precision of the analysis in some
cases.
For the Juliet tests, some of these implementations
(mainly, functions from `string.h` and `math.h`) are included in
`fc/fc_runtime.c`, which itself is included by `analyze.sh`.


Scripts used by Frama-C
-----------------------

- `fc/analyze.sh`: runs Eva with a set of predefined parameters. Used by
  the test makefiles. Allows modifying analysis parameters.

- `fc/evaluate_case.sh`: invokes `analyze.sh` and parses the output, to
  summarize the test result: ok, imprecise, unsound, timeout, etc.
  Used by the test makefiles.

The following Frama-C specific files are copied into `C/testcases`:

- `GNUmakefile`: makefile used to run Frama-C. It is named `GNUmakefile` to
  avoid overwriting existing `Makefile`s, but also to avoid requiring using
  `-f <file>` option when running `make` (in GNU make, `GNUmakefile` takes
  precedence over `Makefile`).

- `CWE*/**/GNUmakefile`: in each directory analyzed by Frama-C, a symbolic link
  to the previous `GNUmakefile` has been installed. Thus adding/removing such
  files allows Frama-C to consider/stop considering a given directory.

- `run_all_makes.sh`: script that runs all sub-makefiles in parallel.
  Automatically invoked by `make`.

- `summarize_results.sh`: after all tests are run, compiles a summary
  of the results per directory.
  Automatically invoked by `make`.

- `results_summary.txt`: results of the tests run by Eva.

- `clean_all_makes.sh`: removes **all** result files.

- `clean_all_timeout_and_unsound.sh`: removes result files for tests
  that resulted in `unsound` or `timeout`. Used during development and also
  in case the test machine was overloaded, resulting in timeouts.
  Re-run `make` after running this script, to recompute the results for
  the failed tests.


Useful make targets
-------------------

When inside a test directory (`testcases/CWEXXX_*/sNN`), the following targets
are available for each test file `CWEXXX_<test>.c`:

- `make CWEXXX_<test>_good.res` will run the "good" test case in the shell.

- `make CWEXXX_<test>_bad.res` will run the "bad" test case in the shell.

- `make CWEXXX_<test>_good.gui` will run the "good" test case and open it
  with the Frama-C GUI. Same for `_bad`.

    * **Note**: running a test in the GUI may modify the resulting `.res` file,
      which might affect the overall summary. Consider erasing the `.res` file
      and re-running `make` without the GUI to force its recomputation.

- Note: for multifile tests (files ending with `a`, `b`, `c`, etc.), the target
  name does not have the letter suffix. E.g., the test targets for files
  `test_42a.c` and `test_42b.c` are `test_42_good.res` and `test_42_bad.res`.

- `make` will re-run all necessary tests. Note that some dependencies are not
  tracked, e.g. if you modify Frama-C's libc files, you may have to force
  the tests to be run again (with `-B`).

- `make clean` will erase all files created during testing.
