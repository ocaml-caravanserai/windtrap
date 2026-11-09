`windtrap mutants --tests` gives one row for each test that reaches a
mutant: the mutants that it kills, the mutants that only it kills, and
then the tests that kill no mutant. A path the command builds is
absolute and spelled by the platform, so a verdict file is shown by its
name.

  $ bin=$PWD
  $ mkdata() { "$bin/mkdata.exe" "$@"; }
  $ run() {
  >   env -i PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" WINDTRAP_COLOR=never "$@" > "$bin/out" 2> "$bin/err"
  >   code=$?; cat "$bin/out"
  >   if [ -s "$bin/err" ]; then
  >     echo '--- stderr'
  >     sed -E 's#[^ ()]*[/\\]([^/\\ ()]+\.mutants)#.../\1#g' "$bin/err"
  >   fi
  >   return $code
  > }
  $ scratch=$(cd "$(mktemp -d)" && pwd -P)
  $ plant() {
  >   mkdir -p "$1/lib"
  >   printf 'let add a b = a + b\nlet sub a b = a - b\nlet cmp a b = a < b\n' > "$1/lib/calc.ml"
  > }
  $ add='lib/calc.ml:1:14:add:a + b:a - b'
  $ sub='lib/calc.ml:2:14:sub:a - b:a + b'
  $ lt='lib/calc.ml:3:14:lt:a < b:a <= b'

Each run had --full-matrix

Two executables over one library. In A, two tests kill add, and a third
test ran in its job and killed nothing. sub survives in A and only one
test of B kills it. A test of each executable kills lt, and the job of
B ended before its tests did:

  $ plant "$scratch/full" && cd "$scratch/full"
  $ mkdata mutants _build/_mutants/windtrap-a.mutants --full-matrix \
  >   "$add=killed:calc/adds;calc/sums:calc/runs" \
  >   "$sub=survived:calc/runs;calc/subtracts" "$lt=killed:calc/compares"
  $ mkdata mutants _build/_mutants/windtrap-b.mutants --full-matrix \
  >   "$add=survived:cli/runs" "$sub=killed:cli/subtracts" \
  >   "$lt=killed:cli/compares:cli/runs:partial"

The table counts the kills of each test. A mutant counts in the only
column of a test when that test is its one killing test in each file
and each job that killed it ran whole. Two tests kill add, and the job
of B that killed lt did not end, so only `cli › subtracts` has a
mutant of its own. The tests that kill no mutant follow:

  $ run windtrap mutants --tests
  ─────────────────────── tests (8) ────────────────────────
    kills  only  executable          test
        1     0  windtrap-a.mutants  calc › adds
        1     0  windtrap-a.mutants  calc › compares
        0     0  windtrap-a.mutants  calc › runs
        0     0  windtrap-a.mutants  calc › subtracts
        1     0  windtrap-a.mutants  calc › sums
        1     0  windtrap-b.mutants  cli › compares
        0     0  windtrap-b.mutants  cli › runs
        1     1  windtrap-b.mutants  cli › subtracts
  ──────────────────────────────────────────────────────────
  
  ───────────── tests that kill no mutant (3) ──────────────
    windtrap-a.mutants  calc › runs
    windtrap-a.mutants  calc › subtracts
    windtrap-b.mutants  cli › runs
  ──────────────────────────────────────────────────────────

The JSON marks each kill of a run under --full-matrix:

  $ run windtrap mutants --json | grep -E '"verdict"'
        "verdict": "killed", "full_matrix": true,
        "verdict": "killed", "full_matrix": true,
        "verdict": "killed", "full_matrix": true,

The exit code is that of the report: no mutant survived, so it is 0. A
gate gives its outcome line on standard error and its exit code:

  $ run windtrap mutants --tests > /dev/null
  $ run windtrap mutants --tests --min=100 > /dev/null; cat "$bin/err"
  windtrap: mutants: 3 reached, 3 killed, 2 executables, score 100.0% (3/3), minimum 100%: ok, reach 100.0% (3/3), total 100.0% (3/3)
  $ run windtrap mutants --tests --max-survivors=0 > /dev/null; cat "$bin/err"
  windtrap: mutants: 3 reached, 3 killed, 2 executables, score 100.0% (3/3), reach 100.0% (3/3), total 100.0% (3/3), maximum 0 survivors: ok

Under `--lines`, only the mutants on the lines count:

  $ run windtrap mutants --tests --lines=lib/calc.ml:1
  ─────────────────────── tests (4) ────────────────────────
    kills  only  executable          test
        1     0  windtrap-a.mutants  calc › adds
        0     0  windtrap-a.mutants  calc › runs
        1     0  windtrap-a.mutants  calc › sums
        0     0  windtrap-b.mutants  cli › runs
  ──────────────────────────────────────────────────────────
  
  ───────────── tests that kill no mutant (2) ──────────────
    windtrap-a.mutants  calc › runs
    windtrap-b.mutants  cli › runs
  ──────────────────────────────────────────────────────────

A run without --full-matrix

B runs again without the flag. Its job of sub stopped at the first kill,
so a note names it, its tests have no only column, and they are not in
the tests that kill no mutant:

  $ mkdata mutants _build/_mutants/windtrap-b.mutants \
  >   "$add=survived:cli/runs" "$sub=killed:cli/subtracts" "$lt=killed:cli/compares"
  $ run windtrap mutants --tests
  ─────────────────────── tests (8) ────────────────────────
    kills  only  executable          test
        1     0  windtrap-a.mutants  calc › adds
        1     0  windtrap-a.mutants  calc › compares
        0     0  windtrap-a.mutants  calc › runs
        0     0  windtrap-a.mutants  calc › subtracts
        1     0  windtrap-a.mutants  calc › sums
        1     -  windtrap-b.mutants  cli › compares
        0     -  windtrap-b.mutants  cli › runs
        1     -  windtrap-b.mutants  cli › subtracts
  ──────────────────────────────────────────────────────────
  
  ───────────── tests that kill no mutant (2) ──────────────
    windtrap-a.mutants  calc › runs
    windtrap-a.mutants  calc › subtracts
  ──────────────────────────────────────────────────────────
  --- stderr
  windtrap: the counts of windtrap-b.mutants come from the first kill of each mutant only, because its run had no --full-matrix. Thus its tests have - in the only column, and they are not in the tests that kill no mutant. Run the suites again with --full-matrix to count each kill
  $ run windtrap mutants --json | grep -E '"verdict"'
        "verdict": "killed", "full_matrix": true,
        "verdict": "killed",
        "verdict": "killed",

When no run had the flag, the note names no file:

  $ mkdata mutants _build/_mutants/windtrap-a.mutants \
  >   "$add=killed:calc/adds" "$sub=survived:calc/runs;calc/subtracts" "$lt=killed:calc/compares"
  $ run windtrap mutants --tests
  ─────────────────────── tests (7) ────────────────────────
    kills  only  executable          test
        1     -  windtrap-a.mutants  calc › adds
        1     -  windtrap-a.mutants  calc › compares
        0     -  windtrap-a.mutants  calc › runs
        0     -  windtrap-a.mutants  calc › subtracts
        1     -  windtrap-b.mutants  cli › compares
        0     -  windtrap-b.mutants  cli › runs
        1     -  windtrap-b.mutants  cli › subtracts
  ──────────────────────────────────────────────────────────
  --- stderr
  windtrap: the counts come from the first kill of each mutant only, because the runs had no --full-matrix. Thus each test has - in the only column, and no test is in the tests that kill no mutant. Run the suites again with --full-matrix to count each kill

A file with no kill gives exact counts also without the flag, because
no job of its run stopped at a kill:

  $ plant "$scratch/survivors" && cd "$scratch/survivors"
  $ mkdata mutants _build/_mutants/windtrap-a.mutants \
  >   "$add=survived:calc/runs" "$sub=unreached" "$lt=unreached"
  $ run windtrap mutants --tests
  ─────────────────────── tests (1) ────────────────────────
    kills  only  executable          test
        0     0  windtrap-a.mutants  calc › runs
  ──────────────────────────────────────────────────────────
  
  ───────────── tests that kill no mutant (1) ──────────────
    windtrap-a.mutants  calc › runs
  ──────────────────────────────────────────────────────────
  [1]

No test reaches a mutant:

  $ plant "$scratch/none" && cd "$scratch/none"
  $ mkdata mutants _build/_mutants/windtrap-a.mutants --full-matrix \
  >   "$add=unreached" "$sub=outside_tests" "$lt=unreached"
  $ run windtrap mutants --tests
  ─────────────────────── tests (0) ────────────────────────
    No test reaches a mutant.
  ──────────────────────────────────────────────────────────

An unknown verdict names no test, so it gives no row. In B, add is
unknown, and a test of B can kill it. Thus add is in the only column of
no test. Under `--crash-kills`, a note says that the counts leave out
the unknown mutants:

  $ plant "$scratch/unknown" && cd "$scratch/unknown"
  $ mkdata mutants _build/_mutants/windtrap-a.mutants --full-matrix \
  >   "$add=killed:calc/adds" "$sub=survived:calc/subtracts" "$lt=unreached"
  $ mkdata mutants _build/_mutants/windtrap-b.mutants --full-matrix \
  >   "$add=deadline:2.5" "$sub=unreached" "$lt=unreached"
  $ run windtrap mutants --tests --crash-kills
  ─────────────────────── tests (2) ────────────────────────
    kills  only  executable          test
        1     0  windtrap-a.mutants  calc › adds
        0     0  windtrap-a.mutants  calc › subtracts
  ──────────────────────────────────────────────────────────
  
  ───────────── tests that kill no mutant (1) ──────────────
    windtrap-a.mutants  calc › subtracts
  ──────────────────────────────────────────────────────────
  --- stderr
  windtrap: the counts hold only the killed mutants: --crash-kills counts no unknown mutant here
  [1]

Without the file of B, `calc › adds` is the one test that kills add:

  $ run windtrap mutants --tests _build/_mutants/windtrap-a.mutants
  ─────────────────────── tests (2) ────────────────────────
    kills  only  executable          test
        1     1  windtrap-a.mutants  calc › adds
        0     0  windtrap-a.mutants  calc › subtracts
  ──────────────────────────────────────────────────────────
  
  ───────────── tests that kill no mutant (1) ──────────────
    windtrap-a.mutants  calc › subtracts
  ──────────────────────────────────────────────────────────
  [1]

Under a sample, a note says that the counts hold only the mutants of
the sample:

  $ plant "$scratch/sample" && cd "$scratch/sample"
  $ mkdata mutants _build/_mutants/windtrap-a.mutants --sample 50 42 --full-matrix \
  >   "$add=killed:calc/adds" "$sub=not_sampled" "$lt=survived:calc/compares"
  $ run windtrap mutants --tests
  ─────────────────────── tests (2) ────────────────────────
    kills  only  executable          test
        1     1  windtrap-a.mutants  calc › adds
        0     0  windtrap-a.mutants  calc › compares
  ──────────────────────────────────────────────────────────
  
  ───────────── tests that kill no mutant (1) ──────────────
    windtrap-a.mutants  calc › compares
  ──────────────────────────────────────────────────────────
  --- stderr
  windtrap: a suite tested a sample of its mutants (--sample), so the counts hold only the mutants of its sample
  windtrap: 1 mutant is not sampled, so no gate tells that each mutant was killed: give --min or --min-total to gate a sample
  [1]

--tests with --json or --sarif is a usage error:

  $ run windtrap mutants --tests --json
  --- stderr
  windtrap: options '--tests' and '--json' cannot be combined
  usage: windtrap mutants [OPTIONS] [PATH...]
  [2]
  $ run windtrap mutants --sarif --tests
  --- stderr
  windtrap: options '--sarif' and '--tests' cannot be combined
  usage: windtrap mutants [OPTIONS] [PATH...]
  [2]
