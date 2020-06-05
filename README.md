#### Note: this repository migrated to [Frama-C's public Gitlab](https://git.frama-c.com/pub/sate-6).

*Updates to newer Frama-C versions will be done over there instead.*

# Frama-C's repository for SATE VI tests (Juliet 1.3 for C/C++)

Frama-C 19 (Potassium) can be used to run C tests for
NIST's Juliet 1.3 Test Suite for C/C++, as part of the
[SATE](https://samate.nist.gov/SATE.html) tool exposition.
This repository contains scripts to reproduce the tests.

To run them, you will need:

- Frama-C 19 (Potassium) installed in your PATH
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


## Usage

1. Frama-C installation - choose one:

      a. Install Frama-C 19 (Potassium);

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


## Selected directories and files

The list of directories successfully analyzed with Frama-C is available in
`fc/analyzed-directories.txt`. In each of those directories, all C tests
that were not Windows-specific were analyzed.

In other words, Windows-specific tests (containing `_w32_` in their filename)
and C++ tests were _not_ analyzed.


## Bug detection via the Eva plug-in

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

Note that, except for a few syntactic CWEs, the origin of the CWE may not
be located at the point in which the program behavior becomes undefined.
Thus Frama-C/Eva cannot automatically locate the origin of the issue,
just its "symptoms". The precise identification of the location requires
some inspection work (using the Frama-C GUI) to navigate to the program
point ultimately responsible for the weakness.

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

A few other statuses are possible in the script, mainly for future development
and/or debugging, such as `missing spec` (for stdlib functions without
specifications).


## Patches applied to some tests

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


## Sources and headers used by Frama-C

Frama-C ships with an annotated version of the C standard library.
Without its ACSL specifications, the user is required to provide code for each
function used in the program (Eva performs a whole-program analysis).

The annotations provided in Frama-C's standard library are optimized for
performance, to be used in code bases of unknown size. However, Frama-C also
provides implementations for some libc functions, which improve the precision
of the analysis in some cases.
For the Juliet tests, some of these implementations
(mainly, functions from `string.h` and `math.h`) are included in
`fc/fc_runtime.c`, which itself is included by `analyze.sh`.

The Frama-C standard library is an ongoing effort and some cases of missing/
incomplete specifications have been reported. The library is continuously
improved with each release, but the correctness of an analysis of code using
libc functions is subject to the correctness of such specifications.
For critical code, it is imperative that users review the provided annotations
or use their own libraries instead.


## Scripts used by Frama-C

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


## Useful make targets

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


## Classification of CWEs as viewed by Frama-C/Eva

The CWEs present in Juliet 1.3 for C/C++ were categorized, in a non-formal
manner, according to whether they map well to a semantic analysis based solely
on the information present in the C standard, or whether they require external
inputs, e.g. a list of discouraged syntactic constructs, what constitutes a
plaintext password, etc. Besides that, CWEs were categorized according to
features such as dynamic memory allocation and multithreading.

The following notation is used in the lists below:

- ✓CWEXXX: currently handled by Frama-C/Eva
- ∅CWEXXX: CWE currently handled by Frama-C/Eva, but Juliet 1.3 does not
           contain tests in the scope of Frama-C/Eva (i.e. C++ or Windows-only)
- ↑CWEXXX: handled by Frama-C/Eva, but _all_ test cases lead to unrelated
           warnings (either due to imprecise libc specifications,
           or due to lack of relational domains).
           We expect these to be improved in future versions of Frama-C/Eva.


### Caveat: validity of correctness related to some CWEs

CWEs are sometimes broad in scope and their definition cannot be matched exactly
to the capabilities of an abstract interpretation-based analyzer.
In such cases, "handled by Eva" has the following meaning:
"all the code examples in the test suite were corrected handled by the analysis",
which implies that "it may be possible to craft examples where this is not the
case".

For instance, *CWE758 - Undefined Behavior* is extremely vague and could,
in theory, include examples which lead to any of the ~200 undefined behaviors
listed in Annex J.2 of the ISO/IEC 9899:1999 standard.
It is therefore impossible to guarantee that *every* program which contains a
CWE758-type vulnerability will be reported by Eva.

Currently, however, we can state that, for all test cases in
the Juliet 1.3 C/C++ set, for the CWEs mentioned as handled by Frama-C/Eva,
the analysis reports one or several issues for each test case marked as *bad*.

### Weaknesses directly related to undefined behaviors

- ✓CWE121 Stack Based Buffer Overflow
- ✓CWE122 Heap Based Buffer Overflow
- ✓CWE123 Write What Where Condition
- ✓CWE124 Buffer Underwrite
- ✓CWE126 Buffer Overread
- ✓CWE127 Buffer Underread
- CWE188 Reliance on Data Memory Layout
- ✓CWE190 Integer Overflow
- ✓CWE191 Integer Underflow
- ∅CWE244 Heap Inspection
- ✓CWE369 Divide by Zero
- ∅CWE440 Expected Behavior Violation
- ✓CWE457 Use of Uninitialized Variable
- ✓CWE469 Use of Pointer Subtraction to Determine Size
- ✓CWE475 Undefined Behavior for Input to API
- ✓CWE588 Attempt to Access Child of Non Structure Pointer
- ✓CWE665 Improper Initialization
- ✓CWE680 Integer Overflow to Buffer Overflow
- ↑CWE688 Function Call With Incorrect Variable or Reference as Argument
- ✓CWE758 Undefined Behavior
- ∅CWE785 Path Manipulation Function Without Max Sized Buffer
- ✓CWE843 Type Confusion

### UB-related weaknesses dealing with dynamic memory allocation

- ✓CWE415 Double Free
- ✓CWE416 Use After Free
- ✓CWE476 NULL Pointer Dereference
- ✓CWE590 Free Memory Not on Heap
- ✓CWE690 NULL Deref From Return
- ↑CWE761 Free Pointer Not at Start of Buffer

### Weaknesses related to unspecified and/or implementation-defined behaviors

- ✓CWE194 Unexpected Sign Extension
- ✓CWE195 Signed to Unsigned Conversion Error
- ✓CWE196 Unsigned to Signed Conversion Error
- ✓CWE197 Numeric Truncation Error
- ✓CWE587 Assignment of Fixed Address to Pointer

### Weaknesses (mostly syntactic) requiring input beyond the standard (e.g. whitelists/blacklists)

- CWE78 OS Command Injection
- CWE90 LDAP Injection
- CWE134 Uncontrolled Format String
- CWE242 Use of Inherently Dangerous Function
- CWE252 Unchecked Return Value
- CWE253 Incorrect Check of Function Return Value
- CWE321 Hard Coded Cryptographic Key
- CWE327 Use Broken Crypto
- CWE390 Error Without Action
- CWE391 Unchecked Error Condition
- CWE396 Catch Generic Exception
- CWE397 Throw Generic Exception
- CWE467 Use of sizeof on Pointer Type
- CWE468 Incorrect Pointer Scaling
- CWE478 Missing Default Case in Switch
- CWE480 Use of Incorrect Operator
- CWE481 Assigning Instead of Comparing
- CWE482 Comparing Instead of Assigning
- CWE483 Incorrect Block Delimitation
- CWE484 Omitted Break Statement in Switch
- CWE500 Public Static Field Not Final
- CWE546 Suspicious Comment
- CWE561 Dead Code
- ✓CWE562 Return of Stack Variable Address
- CWE563 Unused Variable
- CWE570 Expression Always False
- CWE571 Expression Always True
- CWE606 Unchecked Loop Condition
- ✓CWE617 Reachable Assertion
- CWE674 Uncontrolled Recursion
- CWE676 Use of Potentially Dangerous Function
- CWE681 Incorrect Conversion Between Numeric Types
- CWE685 Function Call With Incorrect Number of Arguments
- CWE835 Infinite Loop

### Weaknesses related to multithreading/concurrence

- CWE364 Signal Handler Race Condition
- CWE366 Race Condition Within Thread
- CWE367 TOC TOU
- CWE479 Signal Handler Use of Non Reentrant Function

### Weaknesses related to typestate analyses (e.g. input sanitization, access control), often requiring external input

In future versions of Eva, we intend to implement a typestate domain, which
could allow some of the CWEs in this category to be handled by Eva.

- CWE114 Process Control
- CWE226 Sensitive Information Uncleared Before Release
- CWE273 Improper Check for Dropped Privileges
- CWE284 Improper Access Control
- CWE325 Missing Required Cryptographic Step
- CWE404 Improper Resource Shutdown
- CWE459 Incomplete Cleanup
- CWE620 Unverified Password Change
- CWE666 Operation on Resource in Wrong Phase of Lifetime
- CWE667 Improper Locking
- CWE672 Operation on Resource After Expiration or Release
- CWE675 Duplicate Operations on Resource
- CWE762 Mismatched Memory Management Routines
- CWE773 Missing Reference to Active File Descriptor or Handle
- CWE775 Missing Release of File Descriptor or Handle
- CWE780 Use of RSA Algorithm Without OAEP
- CWE832 Unlock of Resource That is Not Locked

### Other weaknesses, not (directly) related to undefined behaviors

- CWE15 External Control of System or Configuration Setting
- CWE23 Relative Path Traversal
- CWE36 Absolute Path Traversal
- CWE176 Improper Handling of Unicode Encoding
- CWE222 Truncation of Security Relevant Information
- CWE223 Omission of Security Relevant Information
- CWE247 Reliance on DNS Lookups in Security Decision
- CWE256 Plaintext Storage of Password
- CWE259 Hard Coded Password
- CWE272 Least Privilege Violation
- CWE319 Cleartext Tx Sensitive Info
- CWE328 Reversible One Way Hash
- CWE338 Weak PRNG
- CWE377 Insecure Temporary File
- CWE398 Poor Code Quality
- CWE400 Resource Exhaustion
- CWE401 Memory Leak
- CWE426 Untrusted Search Path
- CWE427 Uncontrolled Search Path Element
- CWE464 Addition of Data Structure Sentinel
- CWE506 Embedded Malicious Code
- CWE510 Trapdoor
- CWE511 Logic Time Bomb
- CWE526 Info Exposure Environment Variables
- CWE534 Info Exposure Debug Log
- CWE535 Info Exposure Shell Error
- CWE591 Sensitive Data Storage in Improperly Locked Memory
- CWE605 Multiple Binds Same Port
- CWE615 Info Exposure by Comment
- CWE789 Uncontrolled Mem Alloc
