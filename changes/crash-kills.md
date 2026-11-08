### Mutation testing

- `windtrap mutants --crash-kills` counts as killed an unknown mutant
  whose run passed its deadline, crashed or passed its memory limit
  (doc/manual/mutation.md#counting-a-crash-as-a-kill).
- A suite run takes `--crash-kills` with `--mutate`, and its mirror
  `WINDTRAP_CRASH_KILLS` (doc/manual/mutation.md#counting-a-crash-as-a-kill).
- In the `windtrap mutants --json` document, each unknown mutant has
  `counted_as_killed` (doc/manual/mutation.md#exporting-the-verdicts).
