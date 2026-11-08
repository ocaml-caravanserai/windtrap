The rewrite filter selects mutants of the binary with no new build.
`--rewrites` tests only the mutants of the rewrites that it names, and
`--skip-rewrites` tests the mutants of all other rewrites. POSIX only:
the mutation loop forks.

The suite runs in a scratch project, so that its verdict file goes to
the `_build` of that project. Its one site is `a + b`, whose mutant has
the rewrite `sub`:

  $ bin=$PWD
  $ root=$(cd "$(mktemp -d)" && pwd -P)
  $ mkdir -p "$root/_build/default/mutants"
  $ cp "$bin/mutant_main.exe" "$root/_build/default/mutants/"
  $ cd "$root/_build/default/mutants"
  $ suite() {
  >   env -i PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" WINDTRAP_COLOR=never \
  >     WINDTRAP_SLOW_THRESHOLD=0 "$@" > out 2>&1
  >   status=$?
  >   sed -E 's/ in [0-9.]+m?s\./ in DURATION./' out
  >   echo "[$status]"
  > }

`--rewrites=sub` keeps the mutant, and the loop tests it:

  $ suite ./mutant_main.exe --mutate --rewrites=sub
  mutant: 1 passed in DURATION.
  mutants: 1 reached by this suite, 1 killed, score 100.0% (1/1), reach 100.0% (1/1), total 100.0% (1/1)
  [0]

`--skip-rewrites=sub` keeps no mutant, and the loop refuses the run:

  $ suite ./mutant_main.exe --mutate --skip-rewrites=sub
  mutant: 1 passed in DURATION.
  windtrap: --skip-rewrites=sub leaves no mutant in this executable's catalogue: no instrumented file matches the scope (is the library under test instrumented with ppx_windtrap.mutate?), or the matched files have no mutation sites of the selected rewrites
  [1]

The mirrors do the same:

  $ suite WINDTRAP_REWRITES=sub ./mutant_main.exe --mutate
  mutant: 1 passed in DURATION.
  mutants: 1 reached by this suite, 1 killed, score 100.0% (1/1), reach 100.0% (1/1), total 100.0% (1/1)
  [0]
  $ suite WINDTRAP_SKIP_REWRITES=sub ./mutant_main.exe --mutate
  mutant: 1 passed in DURATION.
  windtrap: --skip-rewrites=sub leaves no mutant in this executable's catalogue: no instrumented file matches the scope (is the library under test instrumented with ppx_windtrap.mutate?), or the matched files have no mutation sites of the selected rewrites
  [1]

A mirror alone has no effect. With WINDTRAP_MUTATE, a filter that keeps
no mutant is no error: the suite runs without mutation and says why:

  $ suite WINDTRAP_SKIP_REWRITES=sub ./mutant_main.exe
  mutant: 1 passed in DURATION.
  [0]
  $ suite WINDTRAP_MUTATE=1 WINDTRAP_SKIP_REWRITES=sub ./mutant_main.exe
  windtrap: WINDTRAP_MUTATE is set, but no mutant of this executable's catalogue is of a rewrite other than sub, so the suite runs without mutation
  mutant: 1 passed in DURATION.
  [0]

An unknown name and an empty list are usage errors that give the names
of the rewrites, from the flag and from its mirror:

  $ suite ./mutant_main.exe --mutate --rewrites=dell
  windtrap: invalid value 'dell' for --rewrites: expected a comma-separated list of the rewrites not, lt, le, gt, ge, eq, neq, add, sub, fadd, fsub, and, or, del, int, bool, none, tail
  usage: mutant_main.exe [OPTIONS] [PATTERN...]
  [2]
  $ suite ./mutant_main.exe --mutate --skip-rewrites=
  windtrap: invalid value '' for --skip-rewrites: expected a comma-separated list of the rewrites not, lt, le, gt, ge, eq, neq, add, sub, fadd, fsub, and, or, del, int, bool, none, tail
  usage: mutant_main.exe [OPTIONS] [PATTERN...]
  [2]
  $ suite WINDTRAP_REWRITES=sub,keep ./mutant_main.exe --mutate
  windtrap: invalid value 'sub,keep' for WINDTRAP_REWRITES: expected a comma-separated list of the rewrites not, lt, le, gt, ge, eq, neq, add, sub, fadd, fsub, and, or, del, int, bool, none, tail
  usage: mutant_main.exe [OPTIONS] [PATTERN...]
  [2]

Each flag on the command line needs `--mutate`, and the two flags
together are a usage error:

  $ suite ./mutant_main.exe --rewrites=sub
  windtrap: option '--rewrites' scopes '--mutate', which is not given
  usage: mutant_main.exe [OPTIONS] [PATTERN...]
  [2]
  $ suite ./mutant_main.exe --mutate --rewrites=sub --skip-rewrites=add
  windtrap: options '--rewrites' and '--skip-rewrites' cannot be combined
  usage: mutant_main.exe [OPTIONS] [PATTERN...]
  [2]
  $ suite WINDTRAP_REWRITES=sub ./mutant_main.exe --mutate --skip-rewrites=add
  windtrap: options '--rewrites' and '--skip-rewrites' cannot be combined
  usage: mutant_main.exe [OPTIONS] [PATTERN...]
  [2]

The scratch project leaves with the session:

  $ cd "$bin" && rm -rf "$root"
