(* [pos] drops a unary minus. The guard pins the operand to [int] or
   [float]. The parser folds a minus on a literal into the literal, so
   [-1] is no site. *)

let negate x = -x
let fnegate x = -.x
let applied f x = -f x
let prefix x = ( ~- ) x

(* A chain of [~-] has one site. [-a + b] is [(-a) + b], so [sub] and
   [pos] start at one byte. *)
let twice x = -(-x)
let sum a b = -a + b

(* No site: a literal, a partial or a qualified operator, and an opaque
   open. *)
let one = -1
let spaced = - 1
let bracketed = -(1)
let fone = -1.5
let partial l = List.map ( ~- ) l
let float_opened x = Float.(-x)

let let_opened x =
  let open Counters in
  -x

(* A dismissal, and an arid site in a log message. *)
let dismissed x = (-x) [@mutate off "the sign is not checked"]
let logged x = Logs.debug (fun m -> m "%d" (-x))
