### Mutation testing

- Eleven rewrites join the catalogue. `*` and `/` swap (`div`, `mul`),
  and `mod` becomes `*` (`mod`). `*.` and `/.` swap (`fdiv`, `fmul`).
  `land` and `lor` swap (`lor`, `land`), and `lxor` becomes `land`
  (`xor`). `lsl` and `lsr` swap (`lsr`, `lsl`), and `asr` becomes `lsl`
  (`asr`). A file that binds an operator of a family loses the family.
  The rewrites give no mutant under an `open` or an `include` of
  another module or of a module of the same file. `x * 1`, `x / -1`,
  their float forms, a shift by or of `0`, `a land a` and `a lor a`
  give no mutant. A literal operand of `*`, `/` or `mod` gives no `int`
  mutant where `mul`, `div` and `mod` can move it
  (doc/manual/mutation.md#what-is-mutated).
- A file that binds an operator by an alias pattern, as
  `(_ as ( + ))`, loses the rewrites of that operator's family, as a
  file that binds it by name does. Before, the instrumented file could
  fail to compile (doc/manual/mutation.md#what-is-mutated).
- The guards of `not`, `or` and `and` give their bound value and the
  right operand of `&&` or `||` the type `bool`. Before, a GADT `match`
  as a condition or as an operand of `&&` or `||` could fail to compile
  under instrumentation.
- The guards of `add`, `sub`, `fadd`, `fsub`, `le`, `lt`, `ge` and `gt`
  take the warning and alert attributes of their site. Before, a site
  such as `((match x with Some y -> y) + 1) [@ocaml.warning "-8"]`
  could fail to compile under fatal warnings.
- The guards of `add`, `sub`, `fadd` and `fsub` give their operands the
  type `int` or `float`, where no `open` or `include` is in scope.
  Before, a GADT `match` in an operand could fail to compile under
  instrumentation. Under a compiler flag `-open M` where
  `M` gives `+`, `-`, `+.` or `-.` another type, the instrumented file
  does not compile at this time. Use `[@mutate off "reason"]` or
  `[@@@mutate exclude_file]`.
