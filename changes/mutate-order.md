### Mutation testing

- `--mutate-order=fast` and its mirror `WINDTRAP_MUTATE_ORDER` run the
  reaching tests of each mutant by their time in the dry run, the
  fastest first. Thus a kill comes earlier. The default is
  `catalogue`. Under `fast`, the run does the check of each kill also
  at `--mutate-retry=0`, with the tests of the job in the same order. A
  kill by a fixture release also gets a check under `fast`. A failure
  before the site, or an early end, that only the order causes gives
  an unknown mutant. Under `--incremental`, the run reuses no verdict
  of a run with the other order
  (doc/manual/mutation.md#running-the-fastest-test-first).
- An invalid value is a usage error. If neither the command line nor
  a mirror gives `--mutate`, the flag on the command line is a usage
  error.
