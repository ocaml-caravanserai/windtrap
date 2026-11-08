(* An [external] that binds [*.] loses [fmul], and a parameter named [lsl]
   loses [bit]. [mul] and [ari] keep their sites. *)

external ( *. ) : float -> float -> float = "%mulfloat"

let ftimes a b = a *. b
let fdivide a b = a /. b
let shifted = fun ( lsl ) a b -> a lsl b
let both a b = a land b
let times a b = a * b
let sum a b = a + b
