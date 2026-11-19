`--mutate-order=fast` runs the reaching tests of each mutant by their
time in the dry run, the fastest first. POSIX only: the mutation loop
forks.

The suites run in a scratch project, so that their verdict file goes to
the `_build` of that project. Their one site is `a + b`. In each suite,
the first test sleeps for 0.1 s and the second test is fast:

  $ bin=$PWD
  $ root=$(cd "$(mktemp -d)" && pwd -P)
  $ mkdir -p "$root/_build/default/order"
  $ cp "$bin/order_main.exe" "$root/_build/default/order/"
  $ cd "$root/_build/default/order"
  $ suite() {
  >   env -i PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" WINDTRAP_COLOR=never \
  >     WINDTRAP_SLOW_THRESHOLD=0 "$@" > out 2>&1
  >   status=$?
  >   sed -E 's/ in [0-9.]+m?s\./ in DURATION./' out
  >   echo "[$status]"
  > }
  $ mutants() {
  >   (cd "$root" && env -i PATH="$PATH" WINDTRAP_COLOR=never windtrap mutants "$@")
  > }
  $ mutate=--mutate=test/cram/run/mutant_subject.ml

In the suite `speed`, the two tests kill the mutant. In the catalogue
order, the kill names the slow test:

  $ suite ORDER_FIXTURE=speed ./order_main.exe $mutate
  speed: 2 passed in DURATION.
  mutants: 1 reached by this suite, 1 killed, score 100.0% (1/1), reach 100.0% (1/1), total 100.0% (1/1)
  [0]
  $ mutants --json | grep -A 1 '"killed_by"'
        "killed_by": [
          { "executable": 0, "test": ["slow adds"] } ] } ],

In the fast order, the kill names the fast test:

  $ suite ORDER_FIXTURE=speed ./order_main.exe $mutate --mutate-order=fast
  speed: 2 passed in DURATION.
  mutants: 1 reached by this suite, 1 killed, score 100.0% (1/1), reach 100.0% (1/1), total 100.0% (1/1)
  [0]
  $ mutants --json | grep -A 1 '"killed_by"'
        "killed_by": [
          { "executable": 0, "test": ["fast adds"] } ] } ],

In the suite `order`, the two tests reach the mutant, and neither pins
it. The fast test fails when it runs before the slow test. In the
catalogue order, the mutant survives:

  $ suite ./order_main.exe $mutate
  order: 2 passed in DURATION.
  
  ─────────────────────── survivors ────────────────────────
  File "test/cram/run/mutant_subject.ml", line 9, characters 14-19:
    SURVIVED  test/cram/run/mutant_subject.ml:9:14:sub  a + b → a - b
  
      2 tests ran this line and none failed:
        needs the state  test/cram/run/order_main.ml:41
        sets the state   test/cram/run/order_main.ml:37
  ──────────────────────────────────────────────────────────
  
  reproduce: ./order_main.exe --arm test/cram/run/mutant_subject.ml:9:14:sub
  mutants: 1 survived of 1 reached by this suite, score 0.0% (0/1), reach 100.0% (1/1), total 0.0% (0/1)
  [0]

In the fast order, the fast test fails, and the check of the kill runs
it again with no mutant. It fails again, so the mutant is unknown:

  $ suite ./order_main.exe $mutate --mutate-order=fast
  order: 2 passed in DURATION.
  
  ────────────────────── unknown (1) ───────────────────────
  File "test/cram/run/mutant_subject.ml", line 9, characters 14-19:
    test/cram/run/mutant_subject.ml:9:14:sub  a + b → a - b
      its killing test needs the state also fails with no mutant in the fast order: the state is not set
      arm: ./order_main.exe --arm test/cram/run/mutant_subject.ml:9:14:sub
  ──────────────────────────────────────────────────────────
  
  mutants: 1 reached by this suite, 1 unknown, reach 100.0% (1/1)
  [0]

The mirror does the same:

  $ suite WINDTRAP_MUTATE_ORDER=fast ./order_main.exe $mutate
  order: 2 passed in DURATION.
  
  ────────────────────── unknown (1) ───────────────────────
  File "test/cram/run/mutant_subject.ml", line 9, characters 14-19:
    test/cram/run/mutant_subject.ml:9:14:sub  a + b → a - b
      its killing test needs the state also fails with no mutant in the fast order: the state is not set
      arm: ./order_main.exe --arm test/cram/run/mutant_subject.ml:9:14:sub
  ──────────────────────────────────────────────────────────
  
  mutants: 1 reached by this suite, 1 unknown, reach 100.0% (1/1)
  [0]

The flag without `--mutate` is a usage error, and its mirror alone has
no effect:

  $ suite ./order_main.exe --mutate-order=fast
  windtrap: option '--mutate-order' requires '--mutate'
  usage: order_main.exe [OPTIONS] [PATTERN...]
  [2]
  $ suite WINDTRAP_MUTATE_ORDER=fast ./order_main.exe
  order: 2 passed in DURATION.
  [0]

An invalid value is a usage error, from the flag and from the mirror:

  $ suite ./order_main.exe $mutate --mutate-order=slow
  windtrap: invalid value 'slow' for --mutate-order: expected catalogue or fast
  usage: order_main.exe [OPTIONS] [PATTERN...]
  [2]
  $ suite WINDTRAP_MUTATE_ORDER=slow ./order_main.exe $mutate
  windtrap: invalid value 'slow' for WINDTRAP_MUTATE_ORDER: expected catalogue or fast
  usage: order_main.exe [OPTIONS] [PATTERN...]
  [2]

The scratch project leaves with the session:

  $ cd "$bin" && rm -rf "$root"
