### Mutation testing

- A file that binds an operator by an alias pattern, as
  `(_ as ( + ))`, loses the rewrites of that operator's family, as a
  file that binds it by name does. Before, the instrumented file could
  fail to compile (doc/manual/mutation.md#what-is-mutated).
