`--full-matrix` runs all the reaching tests of each mutant, and records
each test that kills it. POSIX only: the mutation loop forks.

The suite runs in a scratch project, so that its verdict file goes to
the `_build` of that project. Its one site is `a + b`. The tests
`adds two` and `adds three` kill its mutant, and `is not 99` reaches it
and kills nothing:

  $ bin=$PWD
  $ root=$(cd "$(mktemp -d)" && pwd -P)
  $ mkdir -p "$root/_build/default/matrix"
  $ cp "$bin/matrix_main.exe" "$root/_build/default/matrix/"
  $ cd "$root/_build/default/matrix"
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

Without the flag, the job stops at the first kill, and the kill names
the first test:

  $ suite ./matrix_main.exe --mutate
  matrix: 3 passed in DURATION.
  mutants: 1 reached by this suite, 1 killed, score 100.0% (1/1), reach 100.0% (1/1), total 100.0% (1/1)
  [0]
  $ mutants --json | grep -A 1 '"killed_by"'
        "killed_by": [
          { "executable": 0, "test": ["adds two"] } ] } ],
  $ mutants --tests
  windtrap: the counts come from the first kill of each mutant only, because the run had no --full-matrix. Thus each test has - in the only column, and no test is in the tests that kill no mutant. Run the suites again with --full-matrix to count each kill
  ─────────────────────── tests (1) ────────────────────────
    kills  only  executable       test
        1     -  matrix_main.exe  adds two
  ──────────────────────────────────────────────────────────

With the flag, the kill names the two tests, and `is not 99` is the
test that kills no mutant:

  $ suite ./matrix_main.exe --mutate --full-matrix
  matrix: 3 passed in DURATION.
  mutants: 1 reached by this suite, 1 killed, score 100.0% (1/1), reach 100.0% (1/1), total 100.0% (1/1)
  [0]
  $ mutants --json | grep -A 3 '"verdict"'
        "verdict": "killed", "full_matrix": true,
        "killed_by": [
          { "executable": 0, "test": ["adds three"] },
          { "executable": 0, "test": ["adds two"] } ] } ],
  $ mutants --tests
  ─────────────────────── tests (3) ────────────────────────
    kills  only  executable       test
        1     0  matrix_main.exe  adds three
        1     0  matrix_main.exe  adds two
        0     0  matrix_main.exe  is not 99
  ──────────────────────────────────────────────────────────
  
  ───────────── tests that kill no mutant (1) ──────────────
    matrix_main.exe  is not 99
  ──────────────────────────────────────────────────────────

The mirror does the same:

  $ suite WINDTRAP_FULL_MATRIX=1 ./matrix_main.exe --mutate
  matrix: 3 passed in DURATION.
  mutants: 1 reached by this suite, 1 killed, score 100.0% (1/1), reach 100.0% (1/1), total 100.0% (1/1)
  [0]
  $ mutants --json | grep -c '"full_matrix": true'
  1

The flag needs `--mutate`, and its mirror alone has no effect:

  $ suite ./matrix_main.exe --full-matrix
  windtrap: option '--full-matrix' requires '--mutate'
  usage: matrix_main.exe [OPTIONS] [PATTERN...]
  [2]
  $ suite WINDTRAP_FULL_MATRIX=1 ./matrix_main.exe
  matrix: 3 passed in DURATION.
  [0]

`--full-matrix` with `--skip-killed` is a usage error, also from the
mirrors and without `--mutate`:

  $ suite ./matrix_main.exe --mutate --full-matrix --skip-killed
  windtrap: options '--skip-killed' and '--full-matrix' cannot be combined
  usage: matrix_main.exe [OPTIONS] [PATTERN...]
  [2]
  $ suite WINDTRAP_SKIP_KILLED=1 ./matrix_main.exe --mutate --full-matrix
  windtrap: options '--skip-killed' and '--full-matrix' cannot be combined
  usage: matrix_main.exe [OPTIONS] [PATTERN...]
  [2]
  $ suite WINDTRAP_SKIP_KILLED=1 WINDTRAP_FULL_MATRIX=1 ./matrix_main.exe
  windtrap: options '--skip-killed' and '--full-matrix' cannot be combined
  usage: matrix_main.exe [OPTIONS] [PATTERN...]
  [2]

The scratch project leaves with the session:

  $ cd "$bin" && rm -rf "$root"
