(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The suite of division.t: one test that multiplies by zero. *)

open Windtrap

let () =
  exit
    (run "division"
       [
         test "scales by zero" (fun () ->
             equal int 0 (Division_subject.scale 3 0));
       ])
