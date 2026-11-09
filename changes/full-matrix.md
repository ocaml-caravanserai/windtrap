### Mutation testing

- `--full-matrix` and its mirror `WINDTRAP_FULL_MATRIX` run all the
  reaching tests of each mutant, also after a kill. A fresh worker runs
  the tests after each kill. The kill names each test that fails in or
  after the first evaluation of the site. A kill before an expiry or a
  crash stays a kill. The flag costs up to the job deadline for each
  killed mutant. Under `--incremental`, a kill is used again only from a
  run with the same flag. `--full-matrix` with `--skip-killed` is a
  usage error. If neither the command line nor a mirror gives
  `--mutate`, the flag on the command line is a usage error
  (doc/manual/mutation.md#finding-the-tests-that-kill-each-mutant).
- `windtrap mutants --tests` gives one row for each test that reaches a
  mutant: the mutants that it kills and the mutants that only it kills.
  The tests that kill no mutant follow. A note names the files of runs
  without `--full-matrix`, whose counts come from the first kill only.
  The `--json` document gives `"full_matrix": true` to a kill of a run
  under the flag (doc/manual/mutation.md#the-kills-of-each-test).
