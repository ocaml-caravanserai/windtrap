Under --incremental, a mutation run takes the verdicts of the last run of
its suite again, for each mutant whose evidence did not change. pins_add.exe
pins calc.ml's add and only reaches sub and shared, so a full run kills one
mutant and lets two survive.

The executable runs from a scratch build directory, where it writes its
verdict file. Its source and the source of its tests are planted where they
were recorded, because the run reads the file of each test. --mutate scopes
the loop to calc.ml's mutants, since under --instrument-with the executable
also links an instrumented core.

  $ bin=$PWD
  $ run() {
  >   env -i PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" WINDTRAP_COLOR=never WINDTRAP_SLOW_THRESHOLD=0 "$@" \
  >     > "$bin/out" 2> "$bin/err"
  >   code=$?; cat "$bin/out"
  >   if [ -s "$bin/err" ]; then echo '--- stderr'; cat "$bin/err"; fi
  >   return $code
  > }
  $ root=$(cd "$(mktemp -d)" && pwd -P) && cd "$root"
  $ mkdir -p _build/default/test test/cram/bin
  $ cp "$bin/calc.ml" "$bin/pins_add.ml" test/cram/bin/ && chmod u+w test/cram/bin/pins_add.ml
  $ cp "$bin/pins_add.exe" _build/default/test/
  $ exe=_build/default/test/pins_add.exe
  $ scope=--mutate=test/cram/bin/calc.ml
  $ verdicts() { grep -e SURVIVED -e '^reused:' -e '^mutants:' -e '^--- stderr' "$bin/out"; }

A run without the flag gives no line of reused verdicts:

  $ run $exe $scope > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b
  mutants: 2 survived of 3 reached by this suite, 1 killed, 1 never reached, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)

The flag reuses each verdict. The line gives their number, the block of
each survivor has (reused), and the outcome line is the same:

  $ run $exe $scope --incremental > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b  (reused)
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b  (reused)
  reused: 3 verdicts from the last run
  mutants: 2 survived of 3 reached by this suite, 1 killed, 1 never reached, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)

The mirror does the same under --mutate:

  $ run env WINDTRAP_INCREMENTAL=1 $exe $scope > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b  (reused)
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b  (reused)
  reused: 3 verdicts from the last run
  mutants: 2 survived of 3 reached by this suite, 1 killed, 1 never reached, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)

A change to the file of the tests stops each reuse, because each verdict
names a test of that file. The next run reuses again:

  $ echo '(* a comment *)' >> test/cram/bin/pins_add.ml
  $ run $exe $scope --incremental > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b
  reused: 0 verdicts from the last run
  mutants: 2 survived of 3 reached by this suite, 1 killed, 1 never reached, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)
  $ run $exe $scope --incremental > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b  (reused)
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b  (reused)
  reused: 3 verdicts from the last run
  mutants: 2 survived of 3 reached by this suite, 1 killed, 1 never reached, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)

A run with more retries tests each mutant again: a survivor of no retry
can die in a retry, and a kill of no retry had no check. The next run with
the same retries reuses each verdict, and so does a run with no retry:

  $ run $exe $scope --mutate-retry=1 --incremental > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b  (2 runs)
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b  (2 runs)
  reused: 0 verdicts from the last run
  mutants: 2 survived of 3 reached by this suite, 1 killed, 1 never reached, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)
  $ run $exe $scope --mutate-retry=1 --incremental > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b  (reused)
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b  (reused)
  reused: 3 verdicts from the last run
  mutants: 2 survived of 3 reached by this suite, 1 killed, 1 never reached, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)
  $ run $exe $scope --incremental > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b  (reused)
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b  (reused)
  reused: 3 verdicts from the last run
  mutants: 2 survived of 3 reached by this suite, 1 killed, 1 never reached, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)

Under a line scope, the run reuses only the verdicts on its lines, from
--lines or from a diff:

  $ run $exe $scope --lines=test/cram/bin/calc.ml:13 --incremental > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b  (reused)
  reused: 1 verdict from the last run
  mutants: 1 survived of 1 reached by this suite, score 0.0% (0/1), reach 100.0% (1/1), total 0.0% (0/1)
  $ printf -- '--- a/test/cram/bin/calc.ml\n+++ b/test/cram/bin/calc.ml\n@@ -14 +14 @@\n-let shared a b = b + a\n+let shared a b = a + b\n' > change.diff
  $ run $exe $scope --diff change.diff --incremental > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b  (reused)
  reused: 1 verdict from the last run
  mutants: 1 survived of 1 reached by this suite, score 0.0% (0/1), reach 100.0% (1/1), total 0.0% (0/1)

windtrap mutants marks each reused survivor, and gives the number of
reused verdicts above the reproduce: line. Its document gives
"reused": true to each reused mutant:

  $ run $exe $scope --incremental > /dev/null
  $ run windtrap mutants
  ───────────────────── survivors (2) ──────────────────────
  File "test/cram/bin/calc.ml", line 13, characters 14-19:
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b  (reused)
        13 │ let sub a b = a - b
  
      1 test ran this line and did not fail:
        pins_add.exe  sub › sub is nonzero
  
  File "test/cram/bin/calc.ml", line 14, characters 17-22:
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b  (reused)
        14 │ let shared a b = a + b
  
      1 test ran this line and did not fail:
        pins_add.exe  shared › shared is nonzero
  ──────────────────────────────────────────────────────────
  
  ─────────────────── never reached (1) ────────────────────
    1  test/cram/bin/calc.ml   line 15
  ──────────────────────────────────────────────────────────
  
  reused: 3 verdicts from earlier runs
  reproduce: dune exec --instrument-with ppx_windtrap.mutate test/pins_add.exe -- --arm test/cram/bin/calc.ml:13:14:add
  mutants: 2 survived of 3 reached, 1 killed, 1 never reached, 1 executable, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)
  [1]
  $ run windtrap mutants --json | grep -E '"id"|"verdict"'
      { "id": "test/cram/bin/calc.ml:12:14:sub",
        "verdict": "killed", "reused": true,
      { "id": "test/cram/bin/calc.ml:13:14:add",
        "verdict": "survived", "reused": true,
      { "id": "test/cram/bin/calc.ml:14:17:sub",
        "verdict": "survived", "reused": true,
      { "id": "test/cram/bin/calc.ml:15:16:add",
        "verdict": "unreached" } ],

The flag without --mutate is a usage error. The mirror alone has no effect
on a run that does not mutate. The mirror refuses a value that is not a
boolean:

  $ run $exe --incremental
  --- stderr
  windtrap: option '--incremental' requires '--mutate'
  usage: pins_add.exe [OPTIONS] [PATTERN...]
  [2]
  $ run env WINDTRAP_INCREMENTAL=1 $exe | sed -E 's/ in [0-9.]+[mµ]?s\././'
  pins_add: 5 passed.
  $ run env WINDTRAP_INCREMENTAL=maybe $exe $scope > /dev/null; head -n 1 "$bin/err"
  windtrap: invalid value 'maybe' for WINDTRAP_INCREMENTAL: expected a boolean: 1/0, true/false, yes/no or on/off
