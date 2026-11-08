# Mutation testing

This page shows how to find the changes to a library that no test
notices, one mutant at a time, and how to kill, reproduce or dismiss
each. The reference is `windtrap mutants --help`, in the
[last section](#the-commands-options), and the suite's `--help`. The
example is `examples/08-mutation/`, and the transcripts ran at the root
of a copy of it made a project of its own, as the
[blueprint](../../examples/x-blueprint/README.md#copying-the-project-out)
shows.

## Instrumenting a library for mutation

Mutation testing is a field of the library stanza, and the tests are
ordinary `(test)` stanzas.

`dune`:

```lisp
(library
 (name windtrap_example_mutation)
 (modules calc)
 (instrumentation
  (backend ppx_windtrap.mutate)))

(test
 (name test_calc)
 (modules test_calc)
 (libraries windtrap windtrap_example_mutation))
```

The `instrumentation` field names the backend, `ppx_windtrap.mutate`.
A build that passes `--instrument-with ppx_windtrap.mutate` compiles
every mutant of the library into it, each behind a guard, and a run
executes the original code until it tests a mutant. A plain build
compiles the library as written. The field repeats, and one library can
carry both this backend and [coverage](coverage.md)'s.

## Testing a suite's mutants

The library holds a calculator.

`calc.ml`:

```ocaml
type op = Add | Sub | Mul | Div

let apply op a b =
  match op with
  | Add -> a + b
  | Sub -> a - b
  | Mul -> a * b
  | Div -> if b = 0 then invalid_arg "Calc.apply: division by zero" else a / b

let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

let abs n =
  if (n >= 0) [@mutate off "both arms yield 0 at n = 0"] then n else -n
```

`test_calc.ml`:

```ocaml
open Windtrap
module Calc = Windtrap_example_mutation.Calc

let addition =
  group "addition"
    [ test "adds" (fun () -> equal int 5 (Calc.apply Calc.Add 2 3)) ]

let subtraction =
  group "subtraction"
    [
      test "stays positive" (fun () -> is_true (Calc.apply Calc.Sub 10 4 > 0));
      test "subtracts" (fun () -> equal int 6 (Calc.apply Calc.Sub 10 4));
    ]

let multiplication =
  group "multiplication"
    [ test "multiplies" (fun () -> equal int 12 (Calc.apply Calc.Mul 3 4)) ]

let division =
  group "division"
    [
      test "divides" (fun () -> equal int 3 (Calc.apply Calc.Div 7 2));
      test "rejects a zero divisor" (fun () ->
          raises_match (Exn.invalid_arg ~sub:"division by zero") (fun () ->
              Calc.apply Calc.Div 1 0));
    ]

let sign =
  group "sign"
    [
      test "is 1 for a positive" (fun () -> equal int 1 (Calc.sign 5));
      test "is -1 for a negative" (fun () -> equal int (-1) (Calc.sign (-5)));
    ]

let abs =
  group "abs"
    [
      test "negates a negative" (fun () -> equal int 3 (Calc.abs (-3)));
      test "keeps zero" (fun () -> equal int 0 (Calc.abs 0));
    ]

let () =
  exit
    (run "calc" [ addition; subtraction; multiplication; division; sign; abs ])
```

To test the mutants a suite reaches, run the suite built with the
backend and pass `--mutate`. The run executes the suite once, recording
which tests reach each mutant, then runs each reached mutant in a
process of its own with those tests alone. A mutant that no test fails on prints
as a `SURVIVED` block: its location in the compiler's format, which
editors and dune jump to, its identifier, the rewrite, the source line
and the tests that ran it. No test calls `sign 0` or `sign 1`:

```
$ dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --mutate
calc: 10 passed in 1.3ms.

─────────────────────── survivors ────────────────────────
File "calc.ml", line 10, characters 16-21:
  SURVIVED  calc.ml:10:16:ge  n > 0 → n >= 0
      10 │ let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

    2 tests ran this line and none failed:
      sign › is -1 for a negative  test_calc.ml:32
      sign › is 1 for a positive   test_calc.ml:31

File "calc.ml", line 10, characters 20-21:
  SURVIVED  calc.ml:10:20:int  0 → 1
      10 │ let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

    2 tests ran this line and none failed:
      sign › is -1 for a negative  test_calc.ml:32
      sign › is 1 for a positive   test_calc.ml:31

File "calc.ml", line 10, characters 37-42:
  SURVIVED  calc.ml:10:37:le  n < 0 → n <= 0
      10 │ let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

    1 test ran this line and did not fail:
      sign › is -1 for a negative  test_calc.ml:32
──────────────────────────────────────────────────────────

─────────────────── never reached (1) ────────────────────
  1  calc.ml   line 10
──────────────────────────────────────────────────────────

reproduce: dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --arm calc.ml:10:16:ge
mutants: 3 survived of 9 reached by this suite, 6 killed, 1 never reached, score 66.7% (6/9), reach 90.0% (9/10), total 60.0% (6/10)
```

## Reproducing a survivor

The `reproduce:` line arms the first survivor. `--arm` for a mutant that
`[@mutate off]` dismisses is a usage error and exits 1. `--arm ID` runs the
suite once with that mutant active, names it first, records no
correction, and ends on one verdict line:

- `mutant killed.`
- `mutant survived: the armed site was evaluated N times and no test
  failed.` Other forms of this line say that only tests marked `xfail`
  failed, that only tests before the first evaluation failed, or that
  only a process that a test forked evaluated the site.
- `mutant not evaluated: no selected test ran the site.` When a test
  failed, the line adds that the mutant did not cause the failure.
- `mutant not reached: only xfail tests ran the site.`

A test that fails kills the mutant as in a mutation run: only when it or
an earlier test in the selection ran the site. An evaluation outside
every test counts as one before every test. A test whose worker crashed,
or was killed at its limit, kills the mutant, because its evaluations
are unknown. Under `-x` the run stops at the first failure that kills
the mutant. Under `dune runtest`, the mirror arms it in every suite that
holds its file, as in
`WINDTRAP_MUTATE_ARM=ID dune runtest --force --instrument-with ppx_windtrap.mutate`
(see [Mutation testing a project](#mutation-testing-a-project) for
`--force`). Arming a killed mutant shows the failure that killed it:

```
$ dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --arm calc.ml:10:16:ge
mutant calc.ml:10:16:ge armed: n > 0 → n >= 0
calc: 10 passed in 2.1ms.
mutant survived: the armed site was evaluated 2 times and no test failed.
$ dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --arm calc.ml:6:11:add
mutant calc.ml:6:11:add armed: a - b → a + b
calc: 10 tests
──────────────────────── failures ────────────────────────
  FAIL  subtraction › subtracts (mutant armed)
    test_calc.ml:12
      12 │ test "subtracts" (fun () -> equal int 6 (Calc.apply Calc.Sub 10 4));

    expected  6
    actual    14
──────────────────────────────────────────────────────────

9 passed, 1 failed in 1.8ms.
mutant killed.
```

## Testing one test's mutants

To judge a new test, narrow the mutation run. `--mutate=PREFIX` tests
only the mutants of the files whose path starts with a prefix, and still
saves its verdicts. The filters select the tests as in any run; a
filtered run lists the mutants its tests never reached and saves no
verdict. `stays positive` checks a sign that `a - b → a + b` keeps:

```
$ dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --mutate=calc.ml -f "stays positive"
calc: 1 passed in 1.1ms.

─────────────────────── survivors ────────────────────────
File "calc.ml", line 6, characters 11-16:
  SURVIVED  calc.ml:6:11:add  a - b → a + b
      6 │ | Sub -> a - b

    1 test ran this line and did not fail:
      subtraction › stays positive  test_calc.ml:11
──────────────────────────────────────────────────────────

─────────────────── never reached (9) ────────────────────
  9  calc.ml   lines 5, 8, 10
──────────────────────────────────────────────────────────

reproduce: dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --arm calc.ml:6:11:add -f 'stays positive'
windtrap: verdicts not saved: this run's selection narrows the suite, and a partial run's verdicts would stand in the project merge as the whole.
mutants: 1 survived of 1 reached by the 1 selected test, 9 never reached, score 0.0% (0/1), reach 10.0% (1/10), total 0.0% (0/10)
```

## Testing a change's mutants

A change is judged by the mutants on its own lines. `--lines` keeps the
mutants on the lines it names, as `--lines=calc.ml:10` or
`--lines=lib/a.ml:3-7,12,lib/b.ml:40`, each file as its mutants'
identifiers spell it, relative to the project root. `--diff FILE`
reads the lines that a `git diff -U0` output adds or changes; with the
default `a/` and `b/` prefixes it names the files as the identifiers do
when the repository's root is the project's. Both narrow `--mutate`,
whose prefixes they combine with, and the run still saves its verdicts,
replacing those on its lines. `windtrap mutants` takes the same two
flags, and reports, and fails on, the mutants of those lines alone, and
`windtrap coverage` the points of those lines (see
[coverage.md](coverage.md)). Their mirrors are `WINDTRAP_LINES` and
`WINDTRAP_DIFF`; a relative path in `WINDTRAP_DIFF` is read from the
project root.

```
$ git diff -U0 > change.diff
$ dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --mutate --diff change.diff
```

## Testing the mutants of some rewrites

The executable holds each mutant that the rewriter compiled. Two flags
select the mutants of some rewrites, with no new build. Each takes a
comma-separated list of rewrite names (see
[What is mutated](#what-is-mutated)):

- `--rewrites=NAME,...` (mirror `WINDTRAP_REWRITES`) tests only the
  mutants of these rewrites.
- `--skip-rewrites=NAME,...` (mirror `WINDTRAP_SKIP_REWRITES`) tests
  the mutants of all other rewrites.

```
$ dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --mutate --rewrites=del,int
```

The two flags narrow `--mutate` as `--lines` does, and they combine
with the prefixes of `--mutate` and with `--lines` or `--diff`. The run
does not test or record a mutant of another rewrite. Thus the run keeps
the verdicts outside its scope only when the same build wrote the
verdict file and tested its suite (see
[Unstable verdicts](#unstable-verdicts)). A mutant that `[@mutate off]`
dismisses stays out of the run. `windtrap mutants` does not take the
two flags.

An unknown name or an empty list is a usage error. The message gives
the names of the rewrites. A repeated name counts one time.

The two flags together are a usage error, from the command line or from
a mirror. If a flag occurs two times, the last value applies. If neither
the command line nor a mirror gives `--mutate`, a flag on the command
line is a usage error. A mirror alone has no effect on a suite that does
not mutate. But an invalid value, or the two mirrors together, is a
usage error on each suite.

A filter that keeps no site of the scope is not an error. The scope is
the prefixes of `--mutate` and the lines of `--lines` or `--diff`. When
the suite passes, the run gives a message on standard error, runs the
suite without mutation, exits 0 and saves no verdict file. From the
command line, the run refuses a red suite, as always. Under
`WINDTRAP_MUTATE`, the suite runs as usual (see [Mutation testing a
project](#mutation-testing-a-project)).

Lines with no site, or with no site of the selected rewrites, follow the
same rule. The run refuses a prefix with no site, or lines that name no
instrumented file under the prefixes, as with no filter.

## Testing a sample of the mutants

A large project has many mutants, and a full run can take hours.
`--sample=PCT` (mirror `WINDTRAP_SAMPLE`) tests only a fixed part of
`PCT` percent of the reached mutants. The report then gives the score
and the total as estimates, each with a 95% interval:

```
$ WINDTRAP_MUTATE=1 WINDTRAP_SAMPLE=20 dune runtest --force --instrument-with ppx_windtrap.mutate
```

`PCT` is a number above 0 and at most 100. The parser takes each form
that OCaml's `float_of_string` reads, hexadecimal included, for example
`20`, `12.5`, `1e1` or `0x1p4`. A run with `--sample=100` tests all the
reached mutants, as a run with no sample. Another value is a usage
error, from the command line or from the mirror. If neither the command line
nor a mirror gives `--mutate`, the flag on the command line is a usage
error. The mirror alone has no effect on a suite that does not mutate.

### Which mutants the sample holds

A mutant is in the sample when a hash of its identifier and of the seed
of the run is below a limit. The limit is `PCT` percent of the range of
the hash. The seed is that of `--seed` or `WINDTRAP_SEED`. Without
them, a mutation run uses the fixed seed `s1:6d7574616e747321`. Thus
each run with the same seed tests the same mutants. A change to one
file does not change the sample of another file.

The run selects the sample after the dry run, from the reached mutants
of its scope. `--skip-killed` first skips the mutants that another
suite killed, and the sample holds a part of the rest. `--incremental` then uses verdicts again only
in the sample. The job of a mutant in the sample is the job of a run
with no sample.

The verdict file records a reached mutant out of the sample as
`not sampled`. The dry run reached this mutant, so the reach counts it
and stays exact. The outcome line gives the count of these mutants.
One line above the outcome line gives the sample and the seed, so you
can do the run again. These lines come from a larger project than the
example:

```
sample: 20% of the reached mutants, seed s1:6d7574616e747321
mutants: 12 survived of 487 reached by this suite, 84 killed, 31 never reached, 391 not sampled, score 87.5% (84/96, 80.4% to 92.3%), reach 94.0% (487/518), total 82.3% (75.6% to 86.8%)
```

### The estimates

The score of the sample is `k / n`. `n` is the scored mutants of the
sample: the killed, the survived and the not evaluated mutants. `k` is
the killed mutants among them. The interval of the score is the
two-sided 95% Wilson score interval of `k / n`. It has a correction for
a finite population, because the sample is a part of the mutants.

The population is `N = n * E / s`, unrounded. `E` is the reached
mutants that the hash judged: those of the scope, less the mutants
that `--skip-killed` skipped. `s` is the mutants of `E` in the sample,
also those that are unknown. The correction multiplies `z^2` by
`(N - n) / (N - 1)`. A sample of all the population gives an interval
of one point.

In a merge, a mutant killed elsewhere is an exact kill: the run skipped
it, and the hash did not judge it. Thus `E`, `n` and `k` do not count
these mutants. With `X` exact kills, the score is
`(X + p * N) / (X + N)`, where `p` is `k / n`. The bounds of the score
are the bounds of `p`, mapped in the same way. The line gives these
kills after the counts of the sample, as
`score 60.0% (5/25 and 50 killed elsewhere, 55.6% to 66.6%)`.

The total of the sample is `(X + p * N) / (X + N + U)`. `U` is the
mutants that no test reached and those that ran outside every test,
which are exact counts. The interval of the total maps each bound of
`p` in the same way. When the sample has no scored mutant, the line
gives `no scored mutant` for the score, and the total has no estimate.
With `--min-total`, the line gives `total: no scored mutant`. The
interval of the score is then 0% to 100%. Thus `--min` and
`--min-total` fail unless the minimum is 0.

### Gates on a sample

`windtrap mutants` merges the files of a sample as other files. When
each file that tested its suite has the same percent and seed, the
merge gives the intervals and the line of the sample. `--min` and
`--min-total` then compare the lower bound of the interval. The lower
bound is a one-sided bound at 97.5%. `--min-reach` compares the exact
reach. The gate names the bound, here in the larger project:

```
$ dune exec windtrap -- mutants --min 80 | tail -n 1
mutants: 12 survived of 487 reached, 84 killed, 31 never reached, 391 not sampled, 1 executable, score 87.5% (84/96, 80.4% to 92.3%), minimum 80% of the lower bound: ok, reach 94.0% (487/518), total 82.3% (75.6% to 86.8%)
```

Files with different samples, or a sample and no sample, give the
estimates with no interval. A note on standard error tells why. `--min`
and `--min-total` then compare a bound that is always true: each mutant
that is not sampled counts as survived. The line gives this bound, as
`score 87.5% (84/96, at least 17.2%)`. A file of a suite that was not
mutation-tested does not count for this rule. In a merge of one sample,
such a file counts its unknown mutants in the estimate, and the merge
fails anyway.

Without a gate, a merge with a mutant that is not sampled exits 1. The
sample does not tell that each mutant was killed, and a sampled file
can hide the survivor of a full file. A sentence on standard error then
tells to give `--min` or `--min-total`. `--max-survivors` with a file
that tested a sample is a usage error, and the command exits 2. The
sample does not count each survivor.

In the document of `--json`, a mutant out of the sample has the verdict
`not_sampled`. When the merge has a sample, `summary` gives their count
in `not_sampled`. Under one sample that holds a reached mutant, it also
gives the sample and the bounds. With no scored mutant, `score` and
`total_percent` are `null`. `--sarif` gives no result for a mutant that
is not sampled.

### Samples and the last run

A sampled run writes `not sampled` over the verdicts of the last run,
for each mutant out of its sample. It does not narrow the scope. The
next full run under `--incremental` thus tests these mutants again. A
kill or a survivor of a sampled run is a verdict of a full job, and
`--incremental` uses it again by the usual rules. A `not sampled`
verdict is never used again, and it is no change for the unstable
section.

A change of `--seed`, or of `WINDTRAP_SEED`, changes the sample. It
also stops the use of each verdict again, because the seed is one of
the settings that `--incremental` compares. Under a scope, the run
keeps the records outside its scope only from a file with the same
sample. A run of no sample keeps them only from a file of no sample.

A good practice is a small sample in each pull request and a full run
each night. The sample gives a fast estimate. The full run gives each
survivor and a verdict for each mutant:

```
$ WINDTRAP_MUTATE=1 WINDTRAP_SAMPLE=10 dune runtest --force --instrument-with ppx_windtrap.mutate
$ dune exec windtrap -- mutants --min 80
```

## What a mutation run runs

A mutation run runs in passes, and prints neither the focus warning nor
the withheld-correction warning:

- The dry run is the suite's ordinary run. Under `-u` it accepts
  corrections before any mutant is armed.
- The determinism probe runs the suite again and checks that it passes
  again.
- Each reached mutant runs with its reaching tests, up to the first
  failure in or after the test that first evaluates its site. One that
  evaluates its site more than `hits * 8 + 1000` times, `hits` being
  the dry run's count, fails its test, and the mutant is killed.
- Under `--mutate-retry N`, the job of each survivor runs again, up to
  `N` more times (see
  [Running a survivor again](#running-a-survivor-again)).
- Under `--mutate-retry N` with `N` above 0, the tests of each kill run
  again with no mutant, up to 3 times (see [Flaky kills](#flaky-kills)).

Every pass runs in worker processes, and the probe and each mutant in a
worker of its own, started as a run's workers are (see [Running
tests](running-tests.md#running-tests-in-worker-processes)): none starts
from what the dry run or another mutant left, a table filled or a lazy
value forced, so a cache cannot hide a mutant. The mutant is armed once
the worker's module initialisation is over. They run up to `-j` at once,
as tests do, and are reported in catalogue order. Unless `--seed` is
given, a mutation run draws its property cases from one fixed seed,
`s1:6d7574616e747321`, so a verdict is the same on every run of one
binary.

A mutant whose run ends before its tests do is unknown, and so is no
survivor. The run ends early when the process crashes or exits, or
passes its deadline (taken from the dry run) or its memory limit. The
report lists it under `unknown` with the reason and an `arm:` command,
which runs the suite with it armed and shows what happens. A mutant
whose run does not evaluate its site, as when an earlier test that its
run leaves out decided whether the site runs, is not evaluated and is
no survivor either, listed under `not evaluated` with its `arm:`
command.

A mutant can also make its run take memory with no limit, for example
when it removes the step of a loop that builds a list. On Linux, the
loop reads the resident memory of each worker, at most 4 times each
second. If a worker is above the limit, the loop kills it with its
process group, as at its deadline, and the mutant is unknown:
`its run passed its memory limit of 1024 MB`. The loop does not kill a
worker that sent a report that the loop did not read yet, or a worker
that finishes its job. Its deadline bounds such a worker.

`--mutate-memory MB` (mirror `WINDTRAP_MUTATE_MEMORY`) sets the limit,
from 1 to 1048576, and the default is 1024. The flag without `--mutate`
is a usage error, and its mirror alone has no effect. The limit is for
the worker process only, not for a process that a test starts. The dry
run has no limit, and the `arm:` command of a mutant runs it with no
limit. If the probe passes the limit, the loop refuses the run and tells
you to raise the limit. On a system without `/proc`, the loop has no
limit.

Until a mutant's run evaluates the site, the run executes the code
without the mutant. Thus a test that fails before the first evaluation
does not kill the mutant. Its failure has another cause, for example a
schedule of domains, the clock or an earlier test. The run does not stop
there. It runs the next reaching test. A failure in the test that
evaluates the site, or after it, kills the mutant. A fixture release or
an `at_exit` function that fails kills the mutant when the run evaluated
the site at any time. When the run does not evaluate the site, the
mutant is not evaluated, and the report names the failure under it, as
`a failure that the mutant did not cause: calc › memo`. For this rule,
an evaluation in a process that a test forks counts, also under
`--arm`. The dry run does not see such an evaluation, so it does not
make a test reach the site.

A site that no test runs, and that module initialization or a
fixture release runs, is evaluated outside tests. No run tests its
mutant, and the report lists its line under `evaluated outside tests`,
apart from the lines never reached.

A test marked `xfail` reaches no mutant. The dry run and the probe run
it, and no mutant's run does. A line that only such tests run is never
reached, and an `--arm` run of its mutant ends on `mutant not reached`.

The mutation run exits 0 whatever it finds. It exits 1, with a sentence
on standard error, when a pass fails or no mutant is left to test. Lines
(`--lines` or `--diff`) of an instrumented file with no site, and a
rewrite filter that keeps no site of a scope that has sites, are no such
failure (see [Testing the mutants of some
rewrites](#testing-the-mutants-of-some-rewrites)).

## Running a survivor again

A test whose result depends on the clock, on threads or on a schedule
of domains can let a mutant survive one run and kill it in the next
run. For example, under `--mutate-workers` a kill can depend on a
schedule (see
[Stateful tests on several domains](#stateful-tests-on-several-domains)).

`--mutate-retry N` (mirror `WINDTRAP_MUTATE_RETRY`) runs the job of a
survivor again, up to `N` more times. Each of these runs is a retry. A
retry runs in a fresh worker, with the tests, the deadline and the
budget of the first run. `N` is from 0 to 100, and the default is 0.

The first run gives the verdict as a run with no retry does. After the
first run, only a kill changes the verdict, and only when its check
trusts it (see [Flaky kills](#flaky-kills)). A retry can end early, for
example at its deadline, or not evaluate the site. Such a retry leaves
the mutant a survivor, and the next retry runs. Thus a retry cannot
take a survivor out of the score. A mutant survives when its first run
survives and no retry kills it. The number of runs in its title counts
the first run and each retry. Each retry that hangs costs its deadline.

The loop runs the retries in passes. The first pass runs the probe and
the job of each mutant. Each later pass runs again the jobs of the
mutants that survived the pass before it. A pass runs its jobs up to
`-j` at once. A job that runs alone in the first pass also runs alone in
a retry. Only survivors cost more time, and the probe runs one time.

The report prints the block of a survivor in the last pass, and gives
the number of runs after its title:

```
  SURVIVED  calc.ml:10:16:ge  n > 0 → n >= 0  (3 runs)
```

Below its reaching tests, the block gives one line for each retry that
ended early or did not evaluate the site, with the reason:

```
    run 2: its run passed its deadline of 1.0s
```

The live line names a mutant in a retry as it did in the first pass.
The verdict file does not keep the number of runs. Thus
`windtrap mutants` and its `--json` do not show it. The verdict file
keeps the `N` of the run that gave each verdict, which `--incremental`
compares (see
[Reusing the verdicts of the last run](#reusing-the-verdicts-of-the-last-run)).
The `reproduce:` and `arm:` commands do not have `--mutate-retry`,
because an `--arm` run runs the suite one time. Thus an `--arm` run can
kill a survivor of 3 runs.

A retry makes a false survivor less probable. It does not make a
verdict deterministic. For example, a mutant that 1 run in 10 kills
survives 3 runs in about 73 of 100 mutation runs. The loop does not run
a killed mutant again, so a kill that only some runs give stays a kill.

A retry changes how frequently the verdict of a mutant changes between
two mutation runs (see [Unstable verdicts](#unstable-verdicts)). For a
mutant that most runs kill, a retry makes this change less probable.
For a mutant that few runs kill, a small `N` makes this change more
probable, and a large `N` makes it less probable. For example, take a
mutant that 1 run in 10 kills. With no retry, its verdict changes in
about 18 of 100 pairs of mutation runs. With 2 retries, it changes in
about 40 of 100 pairs.

A signal stops the loop during a retry as it does during a first run.
A survivor that waits for its next run gets no verdict, and the loop
writes no verdict file. When the signal comes between two passes, the
message names the first survivor that waits, as in
`interrupted before the retry of calc.ml:10:16:ge`.

If neither the command line nor a mirror gives `--mutate`, the flag on
the command line is a usage error. The mirror of the flag alone has no
effect on a suite that does not mutate.

## Flaky kills

A test that depends on the clock, on threads or on a schedule of
domains can fail with no mutant. When such a test fails in the run of a
mutant, it can kill a mutant that the tests do not find.

Under `--mutate-retry N` with `N` above 0, the loop does a check of each
kill that names a test. The killing test is the first test that fails
in or after the test that first evaluates the site. The check runs the
tests of the job that killed the mutant, which are its reaching tests,
up to and with the killing test. It runs them with no mutant, in a
fresh worker. A failure of an earlier test does not stop this run. The
check does this run up to 3 times:

- If the killing test fails in a run, the check fails and stops.
- If the killing test does not fail in the 3 runs, the kill stays.

A run that ends before the killing test ends, at its deadline, at its
memory limit or with its worker, does not give a failure of the test.
A failure of the test counts also when the run then ends early, for
example in a fixture release that hangs. A kill that names no test gets
no check, for example a kill by a fixture release. An `--arm` run does no check.

When the check of a kill in the first run fails, the mutant is unknown.
The report lists it under `unknown`, with the killing test, its failure
in the run with no mutant, and an `arm:` command:

```
────────────────────── unknown (1) ───────────────────────
File "lib/calc.ml", line 13, characters 9-14:
  lib/calc.ml:13:9:sub  a - b → a + b
    its killing test calc › subtracts on two domains also fails with no mutant: expected 6, got 5
    arm: _build/default/test/test.exe --arm lib/calc.ml:13:9:sub
──────────────────────────────────────────────────────────
```

The failure is the first failure of the test in that run, on one line.
The verdict file keeps this reason. An unknown mutant is not part of
the score (see [Gating on the score](#gating-on-the-score)). Thus the
score does not count a kill that the check does not trust, and its
denominator gets smaller. To get a verdict for the mutant, make the
test deterministic, and then run the suite again.

When the check of a kill in a retry fails, the mutant stays a survivor
of its first run. The loop runs no more retries of it. Its block gives
one line for that retry, and prints after the blocks of the last pass
of retries:

```
  SURVIVED  calc.ml:10:16:ge  n > 0 → n >= 0  (2 runs)
    ...
    run 2: its killing test calc › ge on two domains also fails with no mutant: expected true
```

The loop runs the checks in passes after the last pass of retries.
Each pass runs once each check that has not failed, up to `-j` at once.
A check that holds a test that spawned a pool runs alone, as a job does.
Two kills whose checks run the same tests share one check, also when
the two jobs had different tests after the killing test. Each run of
the check has the longest deadline of the jobs that wait for it. Thus a
killing test that fails at its own timeout also fails in the check.
Each different list of tests costs up to 3 more runs. The live line shows a run of a check
with the first mutant that waits for it.

Three runs with no failure do not prove that a test is not flaky. For
example, a test that fails in 1 run of 10 passes 3 runs in about 73 of
100 checks, and its mutant then stays killed. A failed check also does
not prove that the mutant is not killed. The mutant can make the test
fail in each run, and the test can also fail with no mutant.

A signal stops the loop during a check as it does during a job. A kill
that waits for its check gets no verdict, and the loop writes no
verdict file. The signal can come during a pass of checks or between
two passes. If the first mutant with no verdict then waits for its
check, the message names that mutant, as in
`interrupted while the kill of calc.ml:13:9:sub waits for its check`.

## Stateful tests on several domains

Under mutation testing, a stateful test on several domains spawns no
worker domains. It runs each program one time on the domain of the
test, the branches one after the other. Thus a kill does not depend on
a schedule. But a mutant that only a concurrent order of the calls
shows survives, and no test reaches code that only a worker runs.

`--mutate-workers` (mirror `WINDTRAP_MUTATE_WORKERS`) lets such a test
spawn its worker domains under `--mutate` and `--arm`, as it does
without mutation testing. Each program then runs 50 times, and its
branches run on the workers. Use it for the code of a structure that
domains share. It has these costs:

- A run of such a test does about 50 times more work.
- A kill can depend on a schedule. A mutant that one run kills can
  survive the next run, and an `--arm` run of the same mutant can pass.
- The job of a mutant that such a test reaches runs alone, and so does
  the determinism probe. Under `-j`, no other job runs at the same time
  as such a job, because its workers need the CPUs. The other jobs run
  up to `-j` at once.

The dry run records each test that spawned worker domains. The
deadline of a job is the time of the whole dry run plus ten times the
time of the job's tests in the dry run (at least 1 s). The pools of
these tests also ran in the dry run, so their time is in the deadline.
A worker process ends after a test that spawned domains. Then a new
worker process runs the rest of the job. The time that the new worker
process takes to start does not count toward the deadline. But each
start leaves out at most the deadline, so a start that hangs ends the
job.

The `reproduce:`, `arm:` and `replay:` commands of such a run keep
`--mutate-workers`, also in the JUnit file and in the GitHub
annotations. A verdict file does not record the flag, so the commands
of `windtrap mutants` do not have it. Add `--mutate-workers` to such a
command yourself.

If neither the command line nor a mirror gives `--mutate` or `--arm`,
the flag on the command line is a usage error. Its mirror alone has no
effect on a suite that does not mutate.
Thus a suite that opts in through its dune stanza sets the mirror, as
in `(setenv WINDTRAP_MUTATE_WORKERS 1 (run %{test}))`, because the
flag in the stanza is a usage error under a plain `dune runtest`.
Outside mutation testing, a stateful test always spawns its worker
domains.

## Dismissing an equivalent mutant

A mutant that no test can tell from the original is equivalent. `abs`
returns `n` when `n >= 0`, and the mutant `n > 0` differs at zero only,
where both branches return 0. To dismiss it, put `[@mutate off
"reason"]` on the expression, as `calc.ml` does; the site is then
neither tested nor counted. It dismisses every mutant of the
expression, in this version and in any later one that gives the
expression more mutants. `[@@mutate off]` dismisses a binding,
`[@@@mutate off]` and `[@@@mutate on]` the structure items between
them, and `[@@@mutate exclude_file]` a file. Only `off` takes a reason,
which no report prints. `--arm` names it when it refuses the mutant:
a dismissed site has no guard, so `--arm` for its mutant is a usage
error and exits 1.

## Mutation testing a project

A suite's mutation run covers its own executable. To judge the project,
run every suite with `WINDTRAP_MUTATE=1` and merge the verdict files
with `windtrap mutants`. `WINDTRAP_MUTATE` is the mirror of `--mutate`,
where `1` is the bare flag, `0` its absence, and a value that spells no
boolean the prefixes. A suite with no mutant to test, such as a suite
over another library, runs as usual and says why on standard error. A
mutant killed by one executable is killed. A mutant that no executable
killed and one could not judge is unknown, and one that another did not
evaluate is not evaluated; neither is a survivor. The command exits 1
when a mutant survived every executable that reached it, listing the
most reached first, and when an executable could not mutation-test its
suite: the merge names it under `not mutation-tested`, with the mutants
its file leaves unknown. Without a gate, it also exits 1 when a mutant
is not sampled (see [Gates on a sample](#gates-on-a-sample)). A gate on
the score can replace the first condition (see
[Gating on the score](#gating-on-the-score)).

Each suite of an executable writes its own verdict file, and the report
names the suite of a file. A refused row names it, as in
`t.exe (suite lts)`, and the outcome line counts the suites not
mutation-tested. A later refused row whose mutants an earlier row
already counts says `no other mutant unknown`. When two suites of one
executable report the same test path, each witness row ends with
`(suite X)`.

Dune does not track `WINDTRAP_MUTATE`. A suite that ran without it
does not run again when it is set, unless its build changed, and the
merge then finds no verdict of that build.
`(deps (env_var WINDTRAP_MUTATE))` on a test stanza makes dune run it
again when the variable changes. Without it, `--force` makes dune run
every suite:

```
$ WINDTRAP_MUTATE=1 dune runtest --force --instrument-with ppx_windtrap.mutate
calc: 10 passed in 2.7ms.

─────────────────────── survivors ────────────────────────
File "calc.ml", line 10, characters 16-21:
  SURVIVED  calc.ml:10:16:ge  n > 0 → n >= 0
      10 │ let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

    2 tests ran this line and none failed:
      sign › is -1 for a negative  test_calc.ml:32
      sign › is 1 for a positive   test_calc.ml:31

File "calc.ml", line 10, characters 20-21:
  SURVIVED  calc.ml:10:20:int  0 → 1
      10 │ let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

    2 tests ran this line and none failed:
      sign › is -1 for a negative  test_calc.ml:32
      sign › is 1 for a positive   test_calc.ml:31

File "calc.ml", line 10, characters 37-42:
  SURVIVED  calc.ml:10:37:le  n < 0 → n <= 0
      10 │ let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

    1 test ran this line and did not fail:
      sign › is -1 for a negative  test_calc.ml:32
──────────────────────────────────────────────────────────

─────────────────── never reached (1) ────────────────────
  1  calc.ml   line 10
──────────────────────────────────────────────────────────

reproduce: dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --arm calc.ml:10:16:ge
mutants: 3 survived of 9 reached by this suite, 6 killed, 1 never reached, score 66.7% (6/9), reach 90.0% (9/10), total 60.0% (6/10)
$ dune exec windtrap -- mutants
───────────────────── survivors (3) ──────────────────────
File "calc.ml", line 10, characters 16-21:
  SURVIVED  calc.ml:10:16:ge  n > 0 → n >= 0
      10 │ let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

    2 tests ran this line and none failed:
      test_calc.exe  sign › is -1 for a negative
      test_calc.exe  sign › is 1 for a positive

File "calc.ml", line 10, characters 20-21:
  SURVIVED  calc.ml:10:20:int  0 → 1
      10 │ let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

    2 tests ran this line and none failed:
      test_calc.exe  sign › is -1 for a negative
      test_calc.exe  sign › is 1 for a positive

File "calc.ml", line 10, characters 37-42:
  SURVIVED  calc.ml:10:37:le  n < 0 → n <= 0
      10 │ let sign n = if n > 0 then 1 else if n < 0 then -1 else 0

    1 test ran this line and did not fail:
      test_calc.exe  sign › is -1 for a negative
──────────────────────────────────────────────────────────

─────────────────── never reached (1) ────────────────────
  1  calc.ml   line 10
──────────────────────────────────────────────────────────

reproduce: dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --arm calc.ml:10:16:ge
mutants: 3 survived of 9 reached, 6 killed, 1 never reached, 1 executable, score 66.7% (6/9), reach 90.0% (9/10), total 60.0% (6/10)
```

Only code that a suite's own process runs reaches a mutant. A binary
that is not a suite, such as a command-line tool that a cram test or a
dune rule runs or that a test starts as a child process, reaches none,
even when it links the instrumented library. Mutants in code that only
such a binary runs are listed as never reached when a suite links their
module, and are missing from the reports when no suite links it.
`WINDTRAP_MUTATE_ARM` arms a mutant in a suite, never in such a binary.
[Coverage](coverage.md#where-the-dumps-are) does count that code, as
each instrumented executable writes its own dump. A command-line tool
can then be fully covered and have no mutant reached. To test those
mutants, put the tool's entry point in the library, call it from a
test, and check what it prints with `expect` or `expect_file`.

## Skipping the mutants that another suite killed

A project with several suites tests a mutant in each suite that reaches
it. One kill is enough for the merge, so the other suites do work that
does not change the report. `--skip-killed` (mirror
`WINDTRAP_SKIP_KILLED`) skips this work. It narrows `--mutate`, as
`--lines` does. If neither the command line nor a mirror gives
`--mutate`, the flag on the command line is a usage error. The mirror
alone has no effect on a suite that does not mutate.

After the dry run, the suite reads the other verdict files in its
directory, the files of the other suites of its executable included. A
reached mutant gets no worker when another file kills it directly. The
record of that kill must also be of the same mutant: the rewriter read
the same source file for the two executables, and the mutant has the
same renderings and extent. A mutant that another suite skipped does not cause a skip,
so a skip always comes from a run that tested the mutant.

The suite does not use a refused file, and it gives no warning for it. A
refused file holds no kill. The suite also does not use these files, and
it gives a warning for each of them:

- A file that it cannot read, or that is not a verdict file of this
  version.
- A file that names no executable.
- A file whose executable was deleted since, or rebuilt since. These
  are the files that `windtrap mutants` leaves out.

The verdict file records a skipped mutant as killed elsewhere, with the
executable of the file that killed it. The report of the suite counts
the mutant as not tested, and a line above the outcome line names the
executable of each file that the suite used, with the number of skips
that it gave:

```
killed elsewhere: 2 mutants, not tested, from the verdict files of default/test/a.exe (1), default/test/b.exe (1)
```

`windtrap mutants` first judges each skip. A skip stands when another
file of the killing executable kills the mutant. It also stands when no
other file of the killing executable holds the mutant, for example
because the file of the killing suite is now stale. In every other case
the kill does not hold, and the skip does not count:

The merge leaves out every skip that does not count. The other records
of the mutant then give the verdict:

- When they give a verdict of a reached mutant, the merge drops the
  skip, and that verdict stands. For example, a survivor that the
  killing suite now reports stays a survivor.
- When they give no such verdict, the mutant is unknown, because the
  suite that skipped it reached it. Two suites that skipped one mutant
  because of each other give this result when no other record gives a
  verdict of a reached mutant. A third file that holds the mutant as
  never reached gives this result too.

When no file of the merge kills the mutant directly, a note on standard
error then tells to run the suite that skipped the mutant again. A
mutant that another file kills gets no such note. A skip that stands
counts as killed, also in the score and in the `--json` document. When
no file of the merge kills that mutant directly, a note on standard
error tells which suite to run again. The notes do not change the exit
code.

The option uses only the files on disk. Thus run the fast suites first,
for example in a first `dune runtest`, and then the slow suites with
`--skip-killed`. Do not run two suites with the option at the same
time, as `dune runtest` does by default. Each suite can skip a mutant
because of the earlier file of the other. Then no new file kills the
mutant, and the merge gives it as unknown. To run the suites one after
the other, use `dune runtest -j 1`. A suite tests a mutant again when
the rewriter read different source files of the mutant for the two
suites. The digests then differ.

## Reusing the verdicts of the last run

A mutation run runs the job of each reached mutant, but a change usually
affects few mutants. `--incremental` (mirror `WINDTRAP_INCREMENTAL`) uses
the verdicts of the last run of the same suite again, for each mutant
whose evidence did not change. The run then does not run the job of that
mutant. The dry run and the determinism probe always run. If neither the
command line nor a mirror gives `--mutate`, the flag on the command line
is a usage error. The mirror alone has no effect on a suite that does
not mutate.

```
$ WINDTRAP_MUTATE=1 WINDTRAP_INCREMENTAL=1 dune runtest --force --instrument-with ppx_windtrap.mutate
```

The last run is the verdict file of the suite (see
[Where the verdicts are](#where-the-verdicts-are)). The file can come
from another build of the executable, because nearly every change builds
the executable again. It must come from the same suite. A refused file
gives no verdict to use again. A file that does not load, for example a
file of an earlier format, gives a warning, and the run replaces it. On
a CI machine, keep `_build/_mutants` from one run to the next, for
example in a cache.

The run uses a verdict again only for the same mutant. The rewriter read
the same source file, with the same digest. The mutant has the same
renderings and extent. The run that tested the mutant and this run must
have the same seed, `--prop-count`, `--replay`, `--case` and
`--timeout`. They must also have the same `--mutate-memory`,
`--mutate-workers` and windtrap version. Then the rule of the last
verdict applies:

| Last verdict | The run uses it again when |
| --- | --- |
| Killed | The kill names its killing test. In this dry run, that test reaches the mutant. The tests before it in the job of this run are the tests before it in the job of the run that tested the mutant, in the same order. The source files of these tests did not change. Under `--mutate-retry N` with `N` above 0, the run that tested the mutant also had `N` above 0. Only such a run does the check of the kill. A kill in the `k`-th retry is used again only when `N` is `k` or more. |
| Survived | In this dry run, the same tests reach the mutant. The source files of these tests did not change. The `N` of `--mutate-retry` is not more than the `N` of the run that tested the mutant. |
| Not evaluated, unknown, killed elsewhere | Never. |

A kill by a fixture release or by an `at_exit` function names no test.
Thus the run never uses it again. The order of the reaching tests comes
from the dry run. Under `-j` above 1, this order can change from one run
to the next, and then the run uses a kill again less frequently.

The source file of a test is the file of its location, which the report
shows after the test, as in `test_calc.ml:31`. The run reads this file on
disk, under the project root. A change to the limit or to the retries
that a test declares also stops the use of the verdict again. A test
with no location, for example in an executable built without `-g`,
stops the use of each verdict that names it. A test whose file the run
cannot read does the same.

A verdict that the run uses again keeps the `N` of `--mutate-retry` of
the run that tested the mutant. Thus a later run can use it again under
the same rules. Under `--incremental`, the report gives the number of
verdicts that the run used again, also when it is 0. The line is above
the `reproduce:` line, or above the outcome line when there is no
`reproduce:` line:

```
reused: 41 verdicts from the last run
```

The block of a survivor that the run used again has `(reused)` after its
title. For the same verdicts, the blocks print in the order of a run
that tests each mutant.

One type of survivor is an exception. A kill in a retry can give a
survivor when its check does not trust the kill. This survivor prints
when its check ends, after the last pass. When the run uses it again, it
prints with the survivors of the last pass. Thus, except for this
survivor, the `reproduce:` line arms the same survivor.

A verdict that the run used again is not a change for the unstable
section.

When a signal stops the run before the probe ends, the run uses no
verdict again. A later signal stops the use of the verdicts that come
after the stopped job, as it stops the jobs. But when the run ends with
each verdict known, it uses again the verdicts that remain.

The verdict file and `windtrap mutants` mark each verdict that the run
used again. The report of `windtrap mutants` gives
`reused: 41 verdicts from earlier runs`. Its `--json` gives
`"reused": true` to each such mutant. When the merge combines records
of one mutant, the mutant has the mark only when each record of the
highest verdict has it. Thus a fresh kill in another file removes the
mark.

Under `--lines`, `--diff`, `--rewrites`, `--skip-rewrites` or
`--mutate=PREFIX`, the run uses again only the verdicts in its scope.
The records outside the scope follow the rule of a scoped run (see
[Unstable verdicts](#unstable-verdicts)). Thus after
a new build, a run under `--diff` keeps only the records of the diff, and
the next full run can use again only these records. Under
`--skip-killed`, the run first skips the mutants that another suite
killed. A mutant that the last run skipped gets a job, unless the run
skips it again. A run whose selection narrows the suite uses verdicts
again too, and it saves no verdict. When no file of this build exists,
such a run writes a refused file, so the next run uses no verdict again.

Do a full run without `--incremental` from time to time, for example
each night. The rule is a heuristic, as the history file of PIT is. The
run examines only the source file of the mutant and the source files of
the tests. It does not find a change to:

- A module of the tests in another file, for example a helper module. A
  function that declares tests in another file gives them its own file as
  location.
- The file that groups the tests or runs the suite, for example their
  order.
- Another module of the library under test, for example a module that
  the mutated function calls.
- A file that a test reads, for example a baseline file or a fixture.
- The environment, a library that the project uses, or the compiler.

The rule also cannot find a direct run of a stale executable under a
scope (`--lines`, `--diff`, `--rewrites`, `--skip-rewrites` or
`--mutate=PREFIX`) after a change to a test file. Such a run records
the new test digests for the old verdicts outside the scope.

Thus a verdict that the run uses again can be incorrect. A full run
tests each mutant again, and its unstable section lists each verdict
that changed. The run reads the test files on disk, so run the suite
through dune, which builds the executable from these files.

```
$ WINDTRAP_MUTATE=1 dune runtest --force --instrument-with ppx_windtrap.mutate
```

## Unstable verdicts

A mutation run compares the verdict of each mutant with the verdict of
the last run of the same suite. When the verdict changed, the report
lists the mutant in the `unstable` section. A change to a test can
cause this. A test whose result depends on the clock, on the order of
domains or on the tests before it can cause it too:

```
────────────────────── unstable (2) ──────────────────────
  The source of each mutant did not change, but its verdict did.
  calc.ml:10:16:ge   survived → killed
  calc.ml:10:37:le   killed → survived
──────────────────────────────────────────────────────────
```

The run compares only the verdicts killed, survived and not evaluated.
These verdicts do not appear in the section:

- An unknown verdict. The run of the mutant gave no verdict.
- A mutant that no test reached, or that ran outside every test.
- A mutant that the suite skipped under `--skip-killed`. No test of the
  suite ran it.
- A mutant out of the sample of `--sample`. No test of the suite ran
  it.
- A verdict that the run used again under `--incremental`. No test of
  the suite ran the mutant.

After such a verdict, the next run compares with the verdict before it.
For example, a mutant that survived, then was skipped, and then was
killed appears as `survived → killed`. Two survivors with other
reaching tests have the same verdict.

The run compares a mutant only with the same mutant: the rewriter read
the same source file, with the same digest, and the mutant has the same
renderings and extent. Thus a change to the source file of a mutant
starts a new comparison. The earlier verdict file can come from another
build, because nearly every change to a test builds the executable
again. It must come from the same suite.

These runs show no section: a run whose selection narrows the suite, a
refused run, a run that a signal stopped, and a run whose file cannot
be written. Under `--lines`, `--diff`, `--rewrites`, `--skip-rewrites`
or `--mutate=PREFIX`, the section has only the mutants of the scope.
The section does not change the score or the exit code.

A scoped run keeps the records outside its scope only when the same
build wrote the earlier file and tested its suite. In all other cases
the run drops these records, and their previous verdicts go away. A
refused run also drops the records outside its scope. Then the next
full run lists no change of these mutants across that gap. For example,
change a test, which builds the executable again, and then run the
suite under `--mutate=PREFIX` of one module. The next full run compares
the mutants of the other modules with nothing.

The verdict file keeps the previous verdict of each mutant. Thus
`windtrap mutants` gives, for each verdict file, the last change that
the file records for each mutant, with the executable and the suite of
the file. Under a scope, a run keeps the records outside the scope, so
that change can come from a run before the last one. The rows come
from each verdict file, sorted by mutant and then by file. Under
`--json`, the array `unstable` holds the same rows, each with the index
of its verdict file in `executables`.

## Gating on the score

The outcome line gives the mutation score. The score is the percentage
of killed mutants among the mutants that were killed, that survived, or
that were not evaluated. These mutants do not count in the score:

- A mutant that no test reached.
- A mutant that ran outside every test.
- An unknown mutant. Its run gave no verdict, or the check of its kill
  failed (see [Flaky kills](#flaky-kills)). Thus it is not a kill and
  not a survivor.

The line gives the score with the killed and the counted mutants, as
`score 66.7% (6/9)`. When no mutant counts and no gate is given, the
line gives no score.

After the score, the line gives two more measures in the same form:

- The reach is the percentage of reached mutants among the mutants
  that were reached, that no test reached, or that ran outside every
  test. Its numerator is the reached count at the start of the line.
  Thus an unknown mutant counts as reached.
- The total is the percentage of killed mutants among the mutants of
  the score, the mutants that no test reached, and the mutants that ran
  outside every test. An unknown mutant does not count. The total is
  near the mutation score of PIT.

A measure with a denominator of 0 is 100%. When no gate is given on a
measure with a denominator of 0, the line does not give that measure.

A project can keep a survivor that it does not plan to kill. To gate on
the measures and not on each survivor, give one or more of these gates
to `windtrap mutants`:

| Flag | The command exits 1 when |
| --- | --- |
| `--min PCT` | the score is less than `PCT` |
| `--min-reach PCT` | the reach is less than `PCT` |
| `--min-total PCT` | the total is less than `PCT` |
| `--max-survivors N` | more than `N` mutants survived |

`PCT` is a percentage from 0 to 100, and `N` is a non-negative integer.
With a gate, a survivor alone does not make the command exit 1. Each
gate that fails makes it exit 1. The outcome line gives each gate and
its result, `ok` or `FAILED`, after its measure. The gate of the
survivors comes last. A gate compares its measure before it is rounded.
A gate on the score reads a merge with no scored mutant as 100%, and
the line then says `no scored mutant`. Under `--lines` or `--diff`, each
measure is that of the mutants on the lines:

```
$ dune exec windtrap -- mutants --min 60 --min-reach 95 | tail -n 1
mutants: 3 survived of 9 reached, 6 killed, 1 never reached, 1 executable, score 66.7% (6/9), minimum 60%: ok, reach 90.0% (9/10), minimum 95%: FAILED, total 60.0% (6/10)
$ dune exec windtrap -- mutants --max-survivors 3 | tail -n 1
mutants: 3 survived of 9 reached, 6 killed, 1 never reached, 1 executable, score 66.7% (6/9), reach 90.0% (9/10), total 60.0% (6/10), maximum 3 survivors: ok
```

A suite that was not mutation-tested fails the merge also under a gate,
because the merge does not have the verdicts of that suite. Each gate
then says `FAILED`. The mutants of that suite count as unknown, thus as
reached in the reach. When the write of the report or of the document
to standard output fails with an error, for example on a full disk, the
command gives the reason on standard error and exits 1. The gates do
not run then. A closed pipe ends the command by SIGPIPE, unless the
parent ignores that signal. The mutation run of a suite gives the three
measures too, and has no gate. Under a sample, `--min` and
`--min-total` compare the lower bound of an interval (see
[Gates on a sample](#gates-on-a-sample)).

### Counting a crash as a kill

By default, an unknown mutant does not count in the score. PIT counts a
timeout and a memory error as detected. To count the same mutants as
killed, give `--crash-kills` to `windtrap mutants`. The option counts an
unknown mutant as killed when its run passed its deadline, crashed or
passed its memory limit. When more than one suite holds the mutant as
unknown, one such reason in a mutation-tested suite is sufficient. A
flaky kill stays unknown, because the test that killed it also fails
with no mutant. An unknown mutant with another reason stays unknown too.

The score, the total and each gate then count these mutants with the
killed mutants. The reach does not change, because it counts a killed
and an unknown mutant the same. The killed term of the outcome line
gives their number. The unknown section keeps each mutant and marks it
`(counted as killed)`. In this example, the project has two more
mutants. The run of one passed its deadline, and the run of the other
crashed:

```
$ dune exec windtrap -- mutants --crash-kills | tail -n 1
mutants: 3 survived of 11 reached, 8 killed (2 by --crash-kills), 1 never reached, 1 executable, score 72.7% (8/11), reach 91.7% (11/12), total 66.7% (8/12)
```

The verdict of a suite that was not mutation-tested never counts a
mutant as killed. Each gate fails when such a suite exists. The option
does not change the verdict files. A suite run takes `--crash-kills`
with `--mutate`, and its mirror is `WINDTRAP_CRASH_KILLS=1`. The option
changes the outcome line and the unknown section of the run. The flag
without `--mutate` is a usage error, and its mirror alone has no effect.

## Exporting the verdicts

For other tools, `--json` prints the merge as one JSON document on
standard output, in place of the report. The document has its version,
the counts, the score, the reach and the total, the verdict files, and
each mutant with its verdict. A survivor also has the tests that ran it.
A killed mutant has the tests that killed it in `killed_by`: in each run
that killed it, the first test that failed. The array is empty when a
kill names no test, as for a kill by a fixture release. It is also empty
for a mutant killed elsewhere. An unknown mutant has its reason, and the
kind of the reason in `reason_kind`: `deadline`, `crashed`, `memory`,
`flaky_kill` or `other`. Its `counted_as_killed` is `true` when
`--crash-kills` counts it as killed, and `false` if not. Under the
option, `killed` in `summary` counts such a mutant, and `unknown` does
not count it. The `verdict` of such a mutant stays `unknown`. A mutant
whose verdict a run used again under `--incremental` has
`"reused": true` after its verdict, and the other mutants do not have
the key. A test names its verdict file by its index in `executables`,
because two files can have the same name. Under `--lines` or `--diff`, the verdict counts,
the three measures and `mutants` hold only the mutants on the lines. But
`executables` still lists every verdict file, and `refused` still counts
every refused file. Under a gate, the outcome line goes to standard
error, and the exit code is that of the gates. A later version can add
keys. A change to the meaning of a key increments `version`.
[`bin/mutate_cmd.mli`](../../bin/mutate_cmd.mli) gives each key:

```
$ dune exec windtrap -- mutants --json --lines=calc.ml:10
{ "version": 1,
  "summary": { "reached": 5, "killed": 2, "survived": 3,
    "not_evaluated": 0, "unknown": 0, "outside_tests": 0,
    "unreached": 1, "refused": 0, "score": 40.00,
    "reach_percent": 83.33, "total_percent": 33.33 },
  "executables": [
    { "name": "test_calc.exe", "path": "default/test_calc.exe", "suite": "calc", "refused": null } ],
  "mutants": [
    { "id": "calc.ml:10:16:ge",
      "file": "calc.ml", "line": 10, "col": 16, "rewrite": "ge",
      "end_line": 10, "end_col": 21,
      "before": "n > 0", "after": "n >= 0",
      "verdict": "survived",
      "tests": [
        { "executable": 0, "test": ["sign", "is -1 for a negative"] },
        { "executable": 0, "test": ["sign", "is 1 for a positive"] } ] },
    { "id": "calc.ml:10:20:int",
      "file": "calc.ml", "line": 10, "col": 20, "rewrite": "int",
      "end_line": 10, "end_col": 21,
      "before": "0", "after": "1",
      "verdict": "survived",
      "tests": [
        { "executable": 0, "test": ["sign", "is -1 for a negative"] },
        { "executable": 0, "test": ["sign", "is 1 for a positive"] } ] },
    { "id": "calc.ml:10:27:int",
      "file": "calc.ml", "line": 10, "col": 27, "rewrite": "int",
      "end_line": 10, "end_col": 28,
      "before": "1", "after": "0",
      "verdict": "killed",
      "killed_by": [
        { "executable": 0, "test": ["sign", "is 1 for a positive"] } ] },
    { "id": "calc.ml:10:37:le",
      "file": "calc.ml", "line": 10, "col": 37, "rewrite": "le",
      "end_line": 10, "end_col": 42,
      "before": "n < 0", "after": "n <= 0",
      "verdict": "survived",
      "tests": [
        { "executable": 0, "test": ["sign", "is -1 for a negative"] } ] },
    { "id": "calc.ml:10:48:int",
      "file": "calc.ml", "line": 10, "col": 48, "rewrite": "int",
      "end_line": 10, "end_col": 50,
      "before": "(-1)", "after": "0",
      "verdict": "killed",
      "killed_by": [
        { "executable": 0, "test": ["sign", "is -1 for a negative"] } ] },
    { "id": "calc.ml:10:56:int",
      "file": "calc.ml", "line": 10, "col": 56, "rewrite": "int",
      "end_line": 10, "end_col": 57,
      "before": "0", "after": "1",
      "verdict": "unreached" } ],
  "unstable": [ ] }
```

A mutant out of a sample has the verdict `not_sampled`. When the merge
has a sample, `summary` gives `not_sampled`, their count, which
`reached` adds. Under one sample that holds a reached mutant, `summary`
also gives `sample_percent`, `sample_seed`, `score_low`, `score_high`,
`total_low` and `total_high`. A verdict file of a sample has `sample`,
its percent and seed, in its object of `executables`.

## Exporting SARIF

`--sarif` prints the merge as one SARIF 2.1.0 document on standard
output, in place of the report. GitHub code scanning and the SARIF
viewer of VS Code read this format:

```
$ dune exec windtrap -- mutants --sarif > mutants.sarif
```

Each mutant gives one result or none:

- A survivor gives a warning. Its message gives the original and the
  mutated expression, and the number of tests that ran the line.
- An unknown mutant gives a note with the reason of the report. When
  `--crash-kills` counts the mutant as killed, that mutant gives no
  result.
- A mutant that was not evaluated gives a note.
- A killed mutant, a mutant killed elsewhere, a mutant that is not
  sampled, a never reached mutant and a mutant evaluated outside tests
  give no result. An unknown mutant
  gives no result when only suites that were not mutation-tested hold it
  as unknown.

Each result has a rule, which is the rewrite of the mutant, and the
location of the mutated expression. A column counts Unicode code points.
When the command cannot read the source of the file, or the source has
no such column, the location gives only the lines. A file path is
relative to the root of the dune workspace. GitHub reads it relative to
the root of the repository, so the two roots must be the same. The
options act as they do for `--json`. `--lines` and `--diff` keep the
mutants on their lines. Under a gate, the outcome line goes to standard
error, and the exit code is that of the gates.

This GitHub Actions job uploads the document to code scanning. The
steps that build the project and run the mutation tests come before
the two steps of the example:

```yaml
mutants:
  runs-on: ubuntu-latest
  permissions:
    actions: read
    contents: read
    security-events: write
  steps:
    # Put the steps that get the source, build the project and run
    # the mutation tests here.
    - run: dune exec windtrap -- mutants --sarif > mutants.sarif
      continue-on-error: true
    - uses: github/codeql-action/upload-sarif@v4
      with:
        sarif_file: mutants.sarif
```

Without a gate, the command exits 1 when a mutant survives, when a
mutant is not sampled, or when a suite was not mutation-tested. With a
gate, it exits 1 when a gate fails. Thus the `windtrap` step has
`continue-on-error: true`, so that the upload runs. Another way is to
remove `continue-on-error` and to give the upload step
`if: ${{ !cancelled() }}`. Then the job fails, but the upload occurs.
The upload uses the `security-events: write` permission. On a private
repository, it uses `actions: read` too. GitHub Code Security is probably also
necessary on a private repository. We did not do a test of this.

## Killing a survivor

A survivor names a behaviour no test checks. To kill the three survivors
of [Testing a suite's mutants](#testing-a-suites-mutants), add tests at
zero and at one to the `sign` group:

`test_calc.ml`:

```ocaml
let sign =
  group "sign"
    [
      test "is 1 for a positive" (fun () -> equal int 1 (Calc.sign 5));
      test "is -1 for a negative" (fun () -> equal int (-1) (Calc.sign (-5)));
      test "is 0 for zero" (fun () -> equal int 0 (Calc.sign 0));
      test "is 1 for one" (fun () -> equal int 1 (Calc.sign 1));
    ]
```

The mutation run then kills every mutant the suite reaches, and the
project's merge passes:

```
$ dune exec --instrument-with ppx_windtrap.mutate ./test_calc.exe -- --mutate
calc: 12 passed in 2.7ms.
mutants: 10 reached by this suite, 10 killed, score 100.0% (10/10), reach 100.0% (10/10), total 100.0% (10/10)
$ dune exec windtrap -- mutants
mutants: 10 reached, 10 killed, 1 executable, score 100.0% (10/10), reach 100.0% (10/10), total 100.0% (10/10)
```

## What is mutated

Each mutant rewrites one expression, and the last part of its
identifier names the rewrite. `--rewrites` and `--skip-rewrites` take
these names (see
[Testing the mutants of some rewrites](#testing-the-mutants-of-some-rewrites)):

- `not` negates a condition that is neither a comparison nor a
  connective: the condition of an `if` or a `while`, or a guard.
- A comparison in a condition moves by one boundary: `<` becomes `<=`
  (`le`), `<=` becomes `<` (`lt`), `>` becomes `>=` (`ge`), `>=` becomes
  `>` (`gt`), `=` becomes `<>` (`neq`) and `<>` becomes `=` (`eq`).
- `&&` becomes `||` (`or`), and `||` becomes `&&` (`and`).
- `+` becomes `-` (`sub`) and `-` becomes `+` (`add`); `+.` and `-.`
  swap likewise (`fsub`, `fadd`).
- `del` drops a statement, and the statement does not run. A statement
  is `e1` in `e1; e2`, the branch `e` of `if c then e` with no `else`,
  or the body of a `while` or a `for` loop. In such a branch or body,
  the last statement of a sequence is a statement too. `del` asks if a
  test observes what the statement does. A `while` loop can loop
  forever when a statement of its body does not run. Then the run
  evaluates the site more than `hits * 8 + 1000` times, the test fails,
  and the mutant is killed
  (see [What a mutation run runs](#what-a-mutation-run-runs)).
- `int` nudges an integer literal by one: `1` becomes `0`, and any other
  `n` becomes `n + 1`, in the type of its suffix.
- `bool` flips `true` or `false`, outside a condition and the operands
  of `&&` and `||`, where `not` already acts.
- `none` replaces `Some e` with `None`, and `e` does not run.
- `tail` replaces `h :: t` with `t`, and `h` does not run. A list
  literal is one site, at its bracket: `[a; b; c]` becomes `[b; c]`. In
  a chain, as `a :: b :: t`, the outermost `::` alone is a site.

Some code carries no mutant, because no test should pin it or none can
run it. `del` leaves a resource release alone: a call of `close`,
`close_in`, `close_out`, their `_noerr` forms or `closedir`. `int`
leaves alone an operand of `+` or `-`, which `add` and `sub` move
already; an argument of a function whose name ends in `create`, as the
capacity of `Hashtbl.create 16`; the constant of a comparison in a
condition when the nudge is the comparison's own boundary move, as the
`0` of `x < 0`, since `x < 1` is `x <= 0`. `bool` leaves alone the
argument of `~cloexec`. None of these five rewrites has a mutant in code
that runs when the module is initialized, before any test, as in a
top-level `let limit = 64` or `let () = setup (); main ()`, since no run
can judge it. `none` and `tail` also leave alone the right-hand side of
a `let rec` outside its functions and `lazy` bodies, as
`let rec ones = 1 :: ones`, which the compiler accepts only as written.
When the head of a `tail` site written as `h :: t` is a list, as in
`[x] :: acc` or `(x :: cur) :: acc`, it starts at the first byte of the
site and has no `tail` mutant of its own, since one identifier names one
site.

The rewriter also gives no mutant where the syntax shows the mutant
equivalent to the original. It gives none where the mutant changes a
log message or a failure message alone. These cases are:

- `x + 0` and `x - 0`, with an integer `0`. `0 + x` keeps its mutant.
- `a && a` and `a || a`, when `a` is a name, a constructor without an
  argument or a field.
- The condition of `if c then e else e`, when the two branches are the
  same code. Code that can give its location, as `__LOC__`, `assert` or
  a `match`, is never the same code as its copy.
- Each site in the arguments of `Logs.app`, `Logs.err`, `Logs.warn`,
  `Logs.info`, `Logs.debug` and `Logs.msg`. The rule reads these names
  as the source spells them, so a module `Logs` of your project in
  another file matches too. A file that declares a module `Logs` loses
  the rule. The list is fixed, and no flag adds a name.
- An integer or boolean literal in the arguments of `failwith` or
  `invalid_arg`. A file that binds one of these names loses the rule.
  The rewriter does not see a binding that an `open` or an `include` of
  another unit brings in. The rule does not cover `raise`.

The last two cases are a choice and not an equivalence. A test can read
a log message or a failure message, and thus kill such a mutant. No test
should pin the text of a message. No attribute and no flag gives such a
mutant back.

These two rules read `f x`, `f @@ x`, `x |> f`, `Printf.ksprintf f` and
`Format.kasprintf f` as calls of `f`. `f @@ x` and `x |> f` match only
when `f` is a name. Thus the message of `Logs.err ~src @@ fun m -> ...`
keeps its mutants, and that of `Logs.err ~src (fun m -> ...)` does not.

In these arguments, a statement is `e1` in `e1; e2` or the `e` of
`let () = e in`. It keeps its mutants and the sites in it, because it
acts on the state of the program. Outside such a statement, a
then-branch with no `else` and a loop body give no `del` site. The rule
of the message applies to their sites. In `a + b + 0` the outermost `+`
has no mutant, so `a + b` carries the mutant of the chain. A
`[@mutate off]` on such a site records it as dismissed, as on any other
site.

A comparison outside a condition, as in `let ok = a < b`, carries no
mutant, and neither does an `assert`. In a chain of one operator, as
`a + b + c`, the outermost application alone is a site. Inline tests
(`let%test`, `let%expect_test` and `module%test` with its helpers)
carry no mutant, and the rest of their file is mutated. A file that
rebinds an operator loses the rewrites of its family: the four
arithmetic operators, the six comparisons or the two connectives. A file
that declares a constructor `Some`, `None` or `::` loses `none` and
`tail`.

The `none` mutant names `None` without a module, and the `tail` mutant
gives `t` the type of `h :: t`. The rewriter does not see a `Some` or a
`::` that an `open` or the expected type takes from another module, as
in `let f x : M.t = Some x`. If `M.t` has no `None`, or its `::` does
not join two values of one type, the mutant does not compile. The
compiler shows the error at the expression, and `[@mutate off "reason"]`
on the expression removes the mutant.

## Where the verdicts are

A suite's `--mutate` run over the whole suite writes one verdict file
under `_build/_mutants`, and the next such run of that suite replaces
the file. Each suite of an executable has its own file, named from the
executable and the suite. Thus a main that calls `Windtrap.run` with
more than one suite name keeps the verdicts of each suite. The
partitions of an inline-test library, which dune runs at the same time,
also keep their verdicts. An executable outside any build directory
writes under `_windtrap/mutants` in its working directory.

A run under `--mutate=PREFIX` replaces the verdicts under its prefixes.
It keeps the others when the same build wrote the file for the same
suite with the same sample. A verdict file records its executable, a
digest of its bytes and its suite. Each record keeps the digest of the
source file of its mutant, as the rewriter read it, which
`--skip-killed` compares. Each record also keeps the previous verdict of
its mutant (see [Unstable verdicts](#unstable-verdicts)). Each record
also keeps the `N` of `--mutate-retry` and the settings of the run that
gave its verdict, and a mark when a run used it again. The file keeps a
digest of each test: of its source file, its limit and its retries. The
file also keeps the sample of its run, or no sample. A kill also keeps a
digest of the tests of its job up to the killing test (see [Reusing the
verdicts of the last run](#reusing-the-verdicts-of-the-last-run)).
`windtrap mutants` merges the files of all suites, and counts the files
of one executable as one executable. It leaves out a file whose
executable was deleted or rebuilt since, with a warning, as [`windtrap
coverage`](coverage.md#when-a-dump-is-excluded) does a dump.

A suite that you rename, or that no longer runs, leaves its file in the
directory. `windtrap mutants` merges this file until a new build of the
executable makes it stale. To remove its verdicts before that, delete
the file.

## Mutation testing without dune

The mutation backend is applied without dune as
[the coverage backend](coverage.md#instrumenting-without-dune) is, and
the suite then runs with `--mutate`.

## When a run cannot mutate

A mutation run starts a worker process for each mutant. It is refused on
Windows, and in a process forked from the test executable that spawned a
domain before its run: that process cannot fork, and a new start of the
program would not reach its run. A test may spawn a domain. A run that
is refused, or whose selection narrows the suite, still writes its
verdict file when this build has none, saying why, and the project's
merge names the executable and the suite under `not mutation-tested`.
`--mutate` and `--arm` together are a usage error. `--arm` refuses a
mutant that `[@mutate off]` dismisses, names the reason, and exits 1:
its site has no guard, so no run can arm it. An interrupt ends the
run: the running mutants are killed, and no verdict file is written. The
message on standard error names the mutant of the next job that the run
gives, or the determinism probe. Between two passes of
`--mutate-retry`, it names the first survivor that waits for its retry.

## The command's options

`windtrap mutants --help` lists its options; the suite's own flags are
in [Running tests](running-tests.md):

```
$ dune exec windtrap -- mutants --help
windtrap mutants - merge .mutants verdict files and report the survivors

usage: windtrap mutants [OPTIONS] [PATH...]

Merges the .mutants verdict files written by mutation runs and reports the
mutants that survived every test executable. Without PATH arguments the files
are found under the build directory's _mutants (or _windtrap/mutants in a tree
built without one), walking up from the current directory to the enclosing
project root; PATH arguments (.mutants files, or directories searched
recursively) replace that default.

The score is the percentage of killed mutants among those killed, survived and
not evaluated. The reach is the percentage of reached mutants among those
reached, never reached and evaluated outside tests. The total is the percentage
of killed mutants among those scored, never reached and evaluated outside
tests. When the suites tested a sample (--sample), the score and the total are
estimates with a 95% interval. Runs no tests and drives no build. Exits 1 when
an executable could not mutation-test its suite. Without a gate, exits 1 also
when any mutant survived every executable that reached it, or when a mutant is
not sampled. With a gate, exits 1 when a gate fails, and not for a survivor
alone.

OPTIONS:
  --min=PCT
      Gate: exit 1 when the score is below PCT. Under a sample, the lower
      bound of the score.

  --min-reach=PCT
      Gate: exit 1 when the reach is below PCT.

  --min-total=PCT
      Gate: exit 1 when the total is below PCT. Under a sample, the lower
      bound of the total.

  --max-survivors=N
      Gate: exit 1 when more than N mutants survived. Refused (exit 2) when
      a suite tested a sample.

  --crash-kills
      Count a mutant whose run passed its deadline, crashed or passed its
      memory limit as killed, in the score, the total and each gate.

  --json
      Machine-readable report on standard output.

  --sarif
      SARIF 2.1.0 document of the survivors, the unknown and the
      not-evaluated mutants on standard output, for code scanning.

  --lines=FILE:A-B,...
      Report only the mutants on these lines of these files.

  --diff=FILE
      Report only the mutants on the lines that FILE, the output of git diff
      -U0, adds or changes.

  --color=MODE (env WINDTRAP_COLOR)
      Color output: always, never or auto.

  -h, --help
      Print this help and exit.

ENVIRONMENT (no flag):
  NO_COLOR
      Any value: never style output (--color auto).
```
