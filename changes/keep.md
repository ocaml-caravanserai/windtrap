### Mutation testing

- A new rewrite, `keep`, drops one field of a record update. Each field
  of `{ r with f = v; ... }` is a site, and its mutant is the update
  without that field, or `r` when the field is the only one. An update
  of more than eight fields has no site. When the dropped field is the
  only one that changes a type parameter, the mutant does not compile,
  and `[@mutate off "reason"]` on the update removes it
  (doc/manual/mutation.md#what-is-mutated).
