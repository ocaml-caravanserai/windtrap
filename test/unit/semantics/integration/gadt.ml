(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* A GADT [match] whose type comes from the expected type of the site. A
   guard that binds the [match] with no constraint gives it the abstract type
   [a], and the arm does not compile. *)

type _ truth = Truth : bool truth

let decide (type a) (w : a truth) (x : a) =
  if match w with Truth -> x then 1 else 0

let both (type a) (w : a truth) (x : a) c = (match w with Truth -> x) && c
