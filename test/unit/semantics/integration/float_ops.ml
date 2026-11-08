(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Operators of another type, for scoped.ml to open. None of them has its
   replacement operator here, so an arm of a site under one of these opens
   names a Stdlib operator on the wrong type. *)

let ( * ) = ( *. )
let ( mod ) = Float.rem
let ( land ) a b = a && b
let ( *. ) = ( ^ )

module type Ops = sig
  type t

  val ( * ) : t -> t -> t
end

module Make (_ : sig end) = struct
  let ( * ) = Stdlib.( *. )
end
