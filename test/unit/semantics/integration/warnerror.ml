(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* A warnerror attribute on a site covers the operands that its guard moves
   out of the site, and the copy of a counter operand. The original gives
   warnings 26 and 42, which the attribute makes non-fatal. *)

type s = { c : int ref }
type t = { c : int ref; d : int }

let counted (x : s) = incr x.c [@warnerror "-42"]

let negated (x : int) =
  -(let y = 1 in
    x)
  [@warnerror "-26"]

let appended (x : int list) z =
  (x
  @
  let y = 1 in
  z)
  [@warnerror "-26"]

let product (x : int) =
  ((let y = 1 in
    x)
  * 3)
  [@ocaml.warnerror "-26"]

let _ = { c = ref 0; d = 0 }
