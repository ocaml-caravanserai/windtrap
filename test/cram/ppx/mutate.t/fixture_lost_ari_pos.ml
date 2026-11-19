(* A file that binds [-] loses [sub] and [add], but keeps [pos]. The minus
   in [a - (-b)] keeps its site, because the [-] has none. *)

let ( - ) a b = a + b
let negate x = -x
let fnegate x = -.x
let diff a b = a - (-b)
