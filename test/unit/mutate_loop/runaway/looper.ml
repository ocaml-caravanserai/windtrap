(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* One mutation site: the body of a loop. Armed, [del] empties the body, and
   the loop no longer ends. The condition is dismissed, so that it is no
   second site. *)

let drain pending =
  while (!pending > 0) [@mutate off "the body is the site"] do
    decr pending
  done
