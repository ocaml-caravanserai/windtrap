(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* An alias pattern binds an operator to a float function. A site at [a * b]
   or [a + b] gives an arm on floats that applies an [int] operator, so this
   module compiles only because the alias loses the family. [pick] keeps its
   [le] site, so that the file registers. *)

let times (_ as ( * ) : float -> float -> float) a b = a * b
let plus (_ as ( + ) : float -> float -> float) a b = a + b
let pick a b x y = if a < b then x else y
