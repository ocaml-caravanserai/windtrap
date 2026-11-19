(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* A file that binds [incr], [~-] and [@] with other types. A site of
   [decr], [pos] or [left] gives an ill-typed arm here, so this module
   compiles only because the bindings lose these families. The other
   families keep their sites. *)

let incr (s : string ref) = s := !s ^ "+"
let ( ~- ) (s : string) = "-" ^ s
let ( @ ) a b = a ^ b

let bumped s =
  incr s;
  !s

let negated s = -s
let joined a b = a @ b
let sum a b = a + b
