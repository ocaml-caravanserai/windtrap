(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* An alert attribute on the counter of a site covers the counter of the
   armed arm too. The flag -open Windtrap_mutate_deprecated gives deprecated
   counters, which the rewriter does not see. *)

let up r = (incr [@alert "-deprecated"]) r
let down r = (decr [@alert "-deprecated"]) r
