### Mutation testing

- `--rewrites=NAME,...` and its mirror `WINDTRAP_REWRITES` test only the
  mutants of these rewrites, with no new build. `--skip-rewrites=NAME,...`
  and its mirror `WINDTRAP_SKIP_REWRITES` test the mutants of all other
  rewrites. Each narrows `--mutate` as `--lines` does
  (doc/manual/mutation.md#testing-the-mutants-of-some-rewrites).
