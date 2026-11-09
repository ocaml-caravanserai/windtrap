(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The suite of full_matrix.t: two tests kill the one mutant of
   [Mutant_subject.add], and a third test reaches it and kills nothing. *)

open Windtrap

let () =
  exit
    (run "matrix"
       [
         test "adds two" (fun () -> equal int 4 (Mutant_subject.add 2 2));
         test "adds three" (fun () -> equal int 5 (Mutant_subject.add 2 3));
         test "is not 99" (fun () -> is_true (Mutant_subject.add 1 1 <> 99));
       ])
