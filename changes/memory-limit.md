### Mutation testing

- `--mutate-memory MB` (mirror `WINDTRAP_MUTATE_MEMORY`) is the memory
  limit of each worker of a mutant, with a default of 1024. On Linux, a
  worker above the limit ends, and its mutant is unknown
  (doc/manual/mutation.md#what-a-mutation-run-runs).
