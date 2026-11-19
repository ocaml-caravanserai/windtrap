(* A file that binds [@] loses [left]. The other families keep their
   sites. *)

let ( @ ) a b = a ^ b
let joined a b = a @ b
let negated x = -x
let sum a b = a + b
