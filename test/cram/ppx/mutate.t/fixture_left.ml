(* [left] drops the right operand of [@]. The guard pins the operands to
   one list type. *)

let append a b = a @ b
let prefix a b = ( @ ) a b

(* [(a @ b) @ c] has one site. [a @ b @ c] is [a @ (b @ c)], with two
   sites. *)
let left_nested a b c = (a @ b) @ c
let right_nested a b c = a @ b @ c

(* No site on a list literal: [a @ []] is [a], and [tail] gives the
   mutant [acc @ []] of [acc @ [ x ]]. An arid site ends the chain. *)
let empty a = a @ []
let snoc acc x = acc @ [ x ]
let pair a x y = a @ [ x; y ]
let inner a b x = (a @ b) @ [ x ]
let cons a x t = a @ (x :: t)
let first b = [] @ b

(* No site: a qualified or a partial operator, and an opaque open. *)
let opened a b = List.(a @ b)
let qualified a b = Stdlib.( @ ) a b
let partial a = List.map (( @ ) a)
