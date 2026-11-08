### Mutation testing

- `--mutate-memory MB` (mirror `WINDTRAP_MUTATE_MEMORY`, default 1024)
  is the memory limit of each worker of a mutant, in megabytes; on
  Linux, the loop kills a worker above it, and its mutant is unknown
  (doc/manual/mutation.md#what-a-mutation-run-runs).
