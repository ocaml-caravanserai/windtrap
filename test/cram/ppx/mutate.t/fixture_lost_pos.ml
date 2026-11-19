(* A file that binds [~-.] loses [pos], on [~-] too. The [sub] sites
   stay. *)

let ( ~-. ) x = x
let negate x = -x
let fnegate x = -.x
let sum a b = a + b
