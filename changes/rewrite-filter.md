### Mutation testing

- `--rewrites=NAME,...` (mirror `WINDTRAP_REWRITES`) tests only the
  mutants of these rewrites, and `--skip-rewrites=NAME,...` (mirror
  `WINDTRAP_SKIP_REWRITES`) tests the mutants of all other rewrites. The
  two flags select the mutants with no new build and narrow `--mutate`
  as `--lines` does
  (doc/manual/mutation.md#testing-the-mutants-of-some-rewrites).
