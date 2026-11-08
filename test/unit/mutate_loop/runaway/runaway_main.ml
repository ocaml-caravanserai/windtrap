(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* A suite whose two tests terminate only because [step] and the loop body
   of [Looper.drain] count down. Unmutated the dry run evaluates each site
   five times, so the loop hands the child a budget of a few thousand hits;
   mutated, the child spins until the guard raises and the test fails. Each
   mutant is killed by its budget, not by the clock, and the whole run takes
   milliseconds. *)

open Windtrap

let rec drain n =
  if n = 0 then 0 else drain (Mutate_loop_spinner.Spinner.step n)

let () =
  exit
  @@ run "spin"
       [
         test "counts down to zero" (fun () -> equal int 0 (drain 5));
         test "drains to zero" (fun () ->
             let pending = ref 5 in
             Mutate_loop_spinner.Looper.drain pending;
             equal int 0 !pending);
       ]
