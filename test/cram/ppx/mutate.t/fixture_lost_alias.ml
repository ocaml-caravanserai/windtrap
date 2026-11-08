(* An alias pattern binds an operator as a variable pattern does. [( * )]
   loses [mul] and [( + )] loses [ari], so no guard applies the operator of
   another type. The comparison keeps its [cmp] site. *)

let times ((_ as ( * )) : float -> float -> float) a b = a * b
let plus ((_ as ( + )) : float -> float -> float) a b = a + b
let pick a b x y = if a < b then x else y
