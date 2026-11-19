### Mutation testing

- Four rewrites join the catalogue. `incr r` becomes `decr r` (`decr`),
  and `decr r` becomes `incr r` (`incr`), also for `Atomic.incr` and
  `Atomic.decr`. The mutant uses the path of the source. A counter is a
  site only on a name, a constructor without an argument or a field.
  `pos` drops a unary minus: `-x` and `-.x` become `x`. `left` drops the
  right operand of `@`: `a @ b` becomes `a`. In `(a @ b) @ c` the outer
  `@` alone is a site (doc/manual/mutation.md#what-is-mutated).
- A file that binds `incr` or `decr` loses `decr` and `incr`. A file
  that binds `~-` or `~-.` loses `pos`, and a file that binds `@` loses
  `left`. A binding is also an instance variable.
- `pos` and `left` give no mutant under an `open` or an `include` of
  another module or of a module of the same file. `decr` and `incr`
  keep their mutants under an `open` of a module of a fixed list, as
  `Int` or `Atomic`, which the file does not declare. A class body with
  an `inherit` has no `decr` or `incr` mutant.
- `a @ l` gives no `left` mutant when `l` is a list literal, as
  `acc @ [ x ]`, where `tail` gives `acc @ []`.
- Under a compiler flag `-open M` where `M` gives `~-`, `~-.`, `@`,
  `incr` or `decr` another type, the instrumented file can fail to
  compile. A module of the library with a name of the list has the same
  effect.
  Use `[@mutate off "reason"]` or `[@@@mutate exclude_file]`.
