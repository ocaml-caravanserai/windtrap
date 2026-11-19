### Mutation testing

- Four rewrites join the catalogue. `incr r` becomes `decr r` (`decr`),
  and `decr r` becomes `incr r` (`incr`), also for `Atomic.incr` and
  `Atomic.decr`. The mutant uses the path of the source. A counter is a
  site only on a name, a constructor without an argument, or a field of
  such an operand.
- `pos` drops a unary minus: `-x` and `-.x` become `x`. A minus on the
  right operand of `+`, `-`, `+.` or `-.` has no mutant when that
  operator has one. Thus `x - (-y)` has only the `add` mutant, because
  the `add` mutant has the value of the `pos` mutant `x - y`.
- `left` drops the right operand of `@`: `a @ b` becomes `a`. `a @ l`
  gives no `left` mutant when `l` is a list literal, as `acc @ [ x ]`,
  where `tail` gives `acc @ []`. A type constraint on the literal does
  not change this.
- A chain has one site. In `(a @ b) @ c` the outer `@` alone is a site,
  and `a @ b @ c` has two. In `-(-x)` and `-((-x) : int)` the outer
  minus alone is a site (doc/manual/mutation.md#what-is-mutated).
- A file that binds `incr` or `decr` loses `decr` and `incr`. A file
  that binds `~-` or `~-.` loses `pos`, and a file that binds `@` loses
  `left`. A binding is also an instance variable.
- `pos` and `left` give no mutant under an `open` or an `include` of
  another module or of a module of the same file. `decr` and `incr`
  keep their mutants under an `open` of a module of a fixed list, as
  `Int` or `Atomic`. The file must not declare that module, and
  `Atomic.incr a` has no mutant in a file that declares a module
  `Atomic`. A class body with an `inherit` has no `decr` or `incr`
  mutant.
- Under a compiler flag `-open M` where `M` gives `~-`, `~-.`, `@`,
  `incr` or `decr` another type, the instrumented file can fail to
  compile. An `@` of `M` on two values of one type that is not a list
  breaks the `left` mutant. A module of the library with a name of the
  fixed list has the same effect. Use `[@mutate off "reason"]` or
  `[@@@mutate exclude_file]`.
- The replacement operator of `ari`, `mul`, `fmul` and `bit` keeps the
  warning and alert attributes of the source operator. Before, an
  attribute such as `[@warning "-44"]` on the source operator did not
  cover the replacement, and the instrumented file did not compile.
