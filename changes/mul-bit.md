### Mutation testing

- A file that binds an operator by an alias pattern, as
  `(_ as ( + ))`, loses the rewrites of that operator's family, as a
  file that binds it by name does. Before, the instrumented file could
  fail to compile (doc/manual/mutation.md#what-is-mutated).
- The guards of `not`, `or` and `and` give their bound value the type
  `bool`. Before, a GADT `match` as a condition or as the left operand
  of `&&` or `||` could fail to compile under instrumentation.
