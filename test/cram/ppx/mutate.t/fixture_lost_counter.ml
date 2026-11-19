(* A file that binds [decr] loses [decr] and [incr], the [Atomic.] forms
   included. The other families keep their sites. *)

let decr r = r := !r - 2
let up r = incr r
let down r = decr r
let atomic_up (a : int Atomic.t) = Atomic.incr a
let atomic_down (a : int Atomic.t) = Atomic.decr a
let negated x = -x
let sum a b = a + b
