### Mutation testing

- In the `windtrap mutants --json` document, a killed mutant has
  `killed_by`, the tests that killed it in each executable
  (doc/manual/mutation.md#exporting-the-verdicts).
- In the same document, an unknown mutant has `reason_kind`, the kind
  of its reason: `deadline`, `crashed`, `memory`, `flaky_kill` or
  `other` (doc/manual/mutation.md#exporting-the-verdicts).
