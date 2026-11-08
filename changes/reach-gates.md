### Mutation testing

- The outcome line gives two more measures after the score. The reach
  is the percentage of reached mutants among the reached, the never
  reached and the evaluated outside tests. The total is the percentage
  of killed mutants among the scored, the never reached and the
  evaluated outside tests (doc/manual/mutation.md#gating-on-the-score).
- The `summary` of the `windtrap mutants --json` document has
  `reach_percent` and `total_percent`
  (doc/manual/mutation.md#exporting-the-verdicts).
- `windtrap mutants` has three more gates: `--min-reach PCT`,
  `--min-total PCT` and `--max-survivors N`. Each gate that fails makes
  the command exit 1, and the outcome line gives each gate with `ok` or
  `FAILED` (doc/manual/mutation.md#gating-on-the-score).
