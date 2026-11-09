(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* With nothing armed, the functions of base_ops.ml compute their original
   results. That base_ops.ml compiles is the main check. *)

module B = Windtrap_mutate_base.Base_ops

let () =
  let ints =
    [
      B.product 7 3;
      B.quotient 7 3;
      B.remainder 7 3;
      B.masked 12 10;
      B.merged 12 10;
      B.flipped 12 10;
      B.shifted_left 8 1;
      B.shifted_right 8 1;
      B.shifted_arith (-8) 1;
    ]
  in
  let floats = [ B.fproduct 7. 2.; B.fquotient 7. 2. ] in
  if ints <> [ 21; 2; 1; 8; 14; 6; 16; 4; -4 ] || floats <> [ 14.; 3.5 ] then
    exit 1
