(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The suites of order.t, which ORDER_FIXTURE chooses. Each has its own name,
   and thus its own verdict file. A slow test sleeps for 0.1 s, so that its
   time in whole milliseconds is above that of a fast test also on a loaded
   machine.

   - [speed]: a slow test and then a fast test kill the one mutant of
     [Mutant_subject.add].
   - [order]: a slow test and then a fast test reach the mutant, and neither
     pins it. The fast test fails when it runs before the slow test, after it
     evaluates the site. *)

open Windtrap

let slow () = Unix.sleepf 0.1
let state = ref false

let () =
  match Sys.getenv_opt "ORDER_FIXTURE" with
  | Some "speed" ->
      exit
        (run "speed"
           [
             test "slow adds" (fun () ->
                 slow ();
                 equal int 4 (Mutant_subject.add 2 2));
             test "fast adds" (fun () -> equal int 5 (Mutant_subject.add 2 3));
           ])
  | _ ->
      exit
        (run "order"
           [
             test "sets the state" (fun () ->
                 slow ();
                 is_true (Mutant_subject.add 1 1 <> 99);
                 state := true);
             test "needs the state" (fun () ->
                 is_true (Mutant_subject.add 2 2 <> 99);
                 if not !state then fail "the state is not set");
           ])
