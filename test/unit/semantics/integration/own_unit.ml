(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* A file that declares a constructor [()]. The [()] of a [del] guard is the
   predefined one by its type, so this module compiles with each [del]
   site: a statement, a then-branch, a [while] body and a [for] body. *)

[@@@ocaml.warning "-65"]

type t = ()

let made : t = ()

let count n =
  let total = ref 0 and left = ref n in
  incr total;
  if n > 2 then incr total;
  while !left > 0 do
    decr left
  done;
  for _ = 1 to n do
    incr total
  done;
  !total
