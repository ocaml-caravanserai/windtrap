(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** The counters, deprecated as Base deprecates them. *)

val incr : int ref -> unit [@@deprecated "a counter for the test of an alert"]
val decr : int ref -> unit [@@deprecated "a counter for the test of an alert"]
