(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The code division.t mutates: one [div] site, whose mutant raises
   [Division_by_zero] when [b] is [0]. *)

let scale a b = a * b
