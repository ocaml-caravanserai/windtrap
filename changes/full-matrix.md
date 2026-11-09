### Mutation testing

- `--full-matrix` and its mirror `WINDTRAP_FULL_MATRIX` run all the
  reaching tests of each mutant, also after a kill. A fresh worker runs
  the tests after each kill. The kill names each counted failing test in
  or after the first evaluation of the site. A kill before an expiry or
  a crash stays a kill. The flag costs up to the job deadline for each
  killed mutant
  (doc/manual/mutation.md#finding-the-tests-that-kill-each-mutant).
- Under `--incremental`, a kill is used again only from a run with the
  same flag, and under the flag only when the job of the kill ran
  each of its tests. `--full-matrix` with `--skip-killed` is a usage
  error. If neither the command line nor a mirror gives `--mutate`, the
  flag on the command line is a usage error.
- `windtrap mutants --tests` gives one row for each test that reaches a
  mutant: the mutants that it kills and the mutants that only it kills.
  The tests that kill no mutant follow. A note names each file whose
  counts come from the first kill only, and tells why. The `--json`
  document gives `"full_matrix": true` to a killed mutant when each run
  that killed it had the flag
  (doc/manual/mutation.md#the-kills-of-each-test).
