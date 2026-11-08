### Mutation testing

- `--incremental` and its mirror `WINDTRAP_INCREMENTAL` let a mutation run
  use the verdict of the last run of the same suite again, with no job for
  the mutant. A kill needs its killing test, and each test before it in the
  job, to reach the mutant in the same order, with source files that did
  not change. A survivor needs the same reaching tests, with source files
  that did not change, and no higher `--mutate-retry`. The run that tested
  the mutant and this run need the same seed, `--prop-count`, `--replay`,
  `--case`, `--timeout`, `--mutate-memory` and `--mutate-workers`, and the
  same version of windtrap. The
  report gives `reused: N verdicts from the last run` above the outcome
  line, and the block of such a survivor has `(reused)`. The rule does not
  examine helper modules, the other modules of the library or the files
  that a test reads, so do a full run each night. If neither the command
  line nor a mirror gives `--mutate`, the flag on the command line is a
  usage error (doc/manual/mutation.md#reusing-the-verdicts-of-the-last-run).
- In the `windtrap mutants --json` document, a mutant whose verdict a run
  used again has `"reused": true`. The report of `windtrap mutants` marks
  such a survivor with `(reused)`, and gives the number of such verdicts
  above the outcome line (doc/manual/mutation.md#exporting-the-verdicts).
