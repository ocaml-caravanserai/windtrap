### Mutation testing

- `--incremental` and its mirror `WINDTRAP_INCREMENTAL` let a mutation
  run use the verdict of the last run of the same suite again, with no
  job for the mutant. A kill is used again when its killing test, and
  each test before it in the job, reach the mutant in the same order.
  Their source files must not change. Under `--mutate-retry`, a kill is
  used again only from a run with enough retries. A survivor is used
  again when the same tests reach it, with unchanged source files and no
  higher `--mutate-retry`.
- Under `--incremental`, the run that tested a mutant and this run must
  have the same seed, `--prop-count`, `--replay`, `--case` and
  `--timeout`. They must also have the same `--mutate-memory`,
  `--mutate-workers` and windtrap version. The report gives
  `reused: N verdicts from the last run` above the outcome line, and the
  block of such a survivor has `(reused)`. The rule does not examine helper
  modules, the other modules of the library or the files that a test
  reads, so do a full run each night. If neither the command line nor a
  mirror gives `--mutate`, the flag on the command line is a usage error
  (doc/manual/mutation.md#reusing-the-verdicts-of-the-last-run).
- In the `windtrap mutants --json` document, a mutant whose verdict a run
  used again has `"reused": true`. The report of `windtrap mutants` marks
  such a survivor with `(reused)`, and gives the number of such verdicts
  above the outcome line (doc/manual/mutation.md#exporting-the-verdicts).
