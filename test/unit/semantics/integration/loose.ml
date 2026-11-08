(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Without -strict-sequence, a loop body can have a type other than [unit],
   with warning 10 alone. The [del] guard of such a body keeps its type, and
   gives warning 10 where the source gives it, under the attribute of the
   binding. *)

let add_to total i =
  total := !total + i;
  !total

let[@ocaml.warning "-10"] sum_for n =
  let total = ref 0 in
  for i = 1 to n do
    add_to total i
  done;
  !total

let[@ocaml.warning "-10"] sum_while n =
  let total = ref 0 and i = ref 0 in
  while !i < n do
    incr i;
    add_to total !i
  done;
  !total
