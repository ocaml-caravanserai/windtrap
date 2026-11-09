(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The eleven operators under the flag [-open Base], which the rewriter does
   not see. Base gives each operator the type of Stdlib, so each arm
   compiles. Base deprecates [mod], and the attribute covers the guard. *)

let product a b = a * b
let quotient a b = a / b
let remainder a b = (a mod b) [@alert "-deprecated"]
let fproduct a b = a *. b
let fquotient a b = a /. b
let masked a b = a land b
let merged a b = a lor b
let flipped a b = a lxor b
let shifted_left a b = a lsl b
let shifted_right a b = a lsr b
let shifted_arith a b = a asr b
