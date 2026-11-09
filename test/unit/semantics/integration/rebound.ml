(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* A file that binds [/] to a function on strings. A [div] site at [a * b]
   gives the arm [a / b], a string, so this module compiles only because the
   binding loses the [mul] family. The other families keep their sites, and
   the [2] of [x * 2] keeps its [int] site. *)

let ( / ) = Filename.concat
let area a b = a * b
let sum a b = a + b
let fl a b = a *. b
let bits a b = a land b
let scaled x = x * 2
