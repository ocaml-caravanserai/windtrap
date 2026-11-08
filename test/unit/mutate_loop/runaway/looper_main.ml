(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* A suite whose single test ends only because the loop body of [drain]
   counts down. Mutated, the loop spins until the guard of its body raises,
   and the test fails. *)

open Windtrap

let () =
  exit
  @@ run "loop"
       [
         test "drains to zero" (fun () ->
             let pending = ref 5 in
             Mutate_loop_looper.Looper.drain pending;
             equal int 0 !pending);
       ]
