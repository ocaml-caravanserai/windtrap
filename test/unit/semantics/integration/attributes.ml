(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* A warning attribute on [h :: t] covers the copy of [t] in its [tail]
   guard. This module compiles under fatal warnings only because the copy
   takes the attributes of its site. *)

let partial x y = x :: (match y with Some z -> [ z ]) [@ocaml.warning "-8"]
let listed x y = [ x; (match y with Some z -> z) ] [@ocaml.warning "-8"]

(* A warning or an alert attribute on a site that binds its operands covers
   the operands in the guard: [ari], and [cmp] on an ordering. *)

module Old : sig
  val value : int [@@deprecated "a value for the test of an alert"]
end = struct
  let value = 3
end

let sum x y = ((match y with Some z -> z) + x) [@ocaml.warning "-8"]
let shifted x = (x + Old.value) [@alert "-deprecated"]

let below x y =
  if ((match y with Some z -> z) < x) [@warning "-8"] then 1 else 0

let negated y = -(match y with Some z -> z) [@ocaml.warning "-8"]
let appended x y = (x @ match y with Some z -> z) [@ocaml.warning "-8"]

(* A warning attribute on the operator or the counter of a site covers the
   operator or the counter of the armed arm too. Warning 44 reports the
   [open] that shadows the replacement. *)

let opened_operator x y =
  let open Bound_operators in
  (( + ) [@warning "-44"]) x y

let opened_counter (a : int Atomic.t) =
  let open Atomic in
  (incr [@warning "-44"]) a
