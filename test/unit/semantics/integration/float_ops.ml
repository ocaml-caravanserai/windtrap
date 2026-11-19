(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Operators of another type, for scoped.ml to open. None of them has its
   replacement operator here, so an arm of a site under one of these opens
   names a Stdlib operator on the incorrect type. A guard of [pos] or [left]
   pins the operands to a Stdlib type, and [decr] here has another type than
   [incr]. *)

let ( * ) = ( *. )
let ( mod ) = Float.rem
let ( land ) a b = a && b
let ( *. ) = ( ^ )
let ( ~- ) = not
let ( ~-. ) = String.uppercase_ascii
let ( @ ) = ( ^ )
let incr (x : float ref) = x := !x +. 1.
let decr (s : string ref) = s := !s ^ "-"

module type Ops = sig
  type t

  val ( * ) : t -> t -> t
  val ( ~- ) : t -> t
end

module Make (_ : sig end) = struct
  let ( * ) = Stdlib.( *. )
  let ( ~- ) = not
  let ( @ ) = ( ^ )
end
