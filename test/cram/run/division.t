A mutant that raises is killed. The armed `div` mutant of `a * b` is
`a / b`, which raises `Division_by_zero` when `b` is `0`. The exception
escapes the test, and the test fails. POSIX only: the mutation loop
forks. The session drops the lines of the backtrace, which depend on
the build.

  $ bin=$PWD
  $ root=$(cd "$(mktemp -d)" && pwd -P)
  $ mkdir -p "$root/_build/default/division"
  $ cp "$bin/division_main.exe" "$root/_build/default/division/"
  $ cd "$root/_build/default/division"
  $ suite() {
  >   env -i PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" WINDTRAP_COLOR=never \
  >     WINDTRAP_SLOW_THRESHOLD=0 "$@" > out 2>&1
  >   status=$?
  >   sed -E 's/ in [0-9.]+m?s\./ in DURATION./' out \
  >     | grep -v -E '^ +(Raised|Re-raised|Called) '
  >   echo "[$status]"
  > }

The loop kills the mutant:

  $ suite ./division_main.exe --mutate
  division: 1 passed in DURATION.
  mutants: 1 reached by this suite, 1 killed, score 100.0% (1/1), reach 100.0% (1/1), total 100.0% (1/1)
  [0]

Under `--arm`, the test fails, and the failure names the exception:

  $ suite ./division_main.exe --arm test/cram/run/division_subject.ml:9:16:div
  mutant test/cram/run/division_subject.ml:9:16:div armed: a * b → a / b
  division: 1 test
  ──────────────────────── failures ────────────────────────
    FAIL  scales by zero (mutant armed)
      test/cram/run/division_main.ml:14
      uncaught exception:
        Division_by_zero
  ──────────────────────────────────────────────────────────
  
  1 failed in DURATION.
  mutant killed.
  [1]
