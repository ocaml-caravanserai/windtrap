### Mutation testing

- A file that binds an operator by an alias pattern, as
  `(_ as ( + ))`, loses the rewrites of that operator's family, as a
  file that binds it by name does. Before, the instrumented file could
  fail to compile (doc/manual/mutation.md#what-is-mutated).
- The guards of `not`, `or` and `and` give their bound value the type
  `bool`. Before, a GADT `match` as a condition or as the left operand
  of `&&` or `||` could fail to compile under instrumentation.
- The guards of `add`, `sub`, `fadd`, `fsub`, `le`, `lt`, `ge` and `gt`
  take the warning and alert attributes of their site. Before, a site
  such as `((match x with Some y -> y) + 1) [@ocaml.warning "-8"]`
  could fail to compile under fatal warnings.
- The guards of `add`, `sub`, `fadd` and `fsub` give their operands the
  type `int` or `float`, where no `open` or `include` of another module
  is in scope. Before, a GADT `match` in an operand could fail to
  compile under instrumentation.
