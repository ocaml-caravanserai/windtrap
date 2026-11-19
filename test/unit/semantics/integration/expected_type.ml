(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The expected-type corpus, the twin of the typing-context corpus in
   disambiguate.ml (which is about ORDER). OCaml gives an application's
   arguments not only an order but an expected type: under
   [( < ) : 'a -> 'a -> bool] the right operand is checked against the
   type the left one has just fixed, and type-directed disambiguation
   resolves a constructor or a record literal by that type. Every right
   operand below names a constructor or a label that a type declared
   LATER in this file also declares, so scope alone resolves each of them
   to the wrong type, and the functions compile only while the swapping
   [cmp] guard hands its right operand the left one's type - which the
   uninstrumented application gets from the comparison's signature and
   the guard must get from the annotation on its tuple.

   Like disambiguate.ml this is a module of a library that keeps dune's
   default warning set (see dune), and it is preprocessed directly, so
   a guard that loses the expected type is a build failure on every
   ordinary build. *)

module Color = struct
  type t = Red | Green | Blue
end

(* Declared last, so that by scope alone every one of these names is a
   [light]. *)
type light = Red | Green | Yellow

(* The swapping orderings, in each context [cmp] fires in: an [if]
   condition, a [when] guard, and the operands of a connective. *)
let before_green (c : Color.t) = if c < Green then 1 else 0
let past_green (c : Color.t) = match c with _ when c > Green -> 1 | _ -> 0
let within (c : Color.t) = c >= Red && c <= Green

(* A record literal, resolved the same way. *)
module Point = struct
  type t = { x : int; y : int }
end

type mark = { x : float; y : float }

let below (p : Point.t) = if p < { x = 0; y = 10 } then 1 else 0

(* [=] and [<>] bind the whole comparison rather than its operands, so
   the application - and the expected types it gives them - survives
   untouched. *)
let is_green (c : Color.t) = if c = Green then 1 else 0

(* The right operand of [@] gets the type of the left one. [A] is
   declared after [Letter], so by scope alone it is a [late]. *)
module Letter = struct
  type t = A | B
end

type late = A | C

let prepended (xs : Letter.t list) ys = xs @ (A :: ys)

(* A GADT [match] as an operand of [@]. The guard pins the two operands to
   one list type, so this compiles without [-principal]. *)
type _ listed = Listed : int list listed

let left_gadt (type a) (w : a listed) (x : a) (ys : int list) =
  (match w with Listed -> x) @ ys

let right_gadt (type a) (w : a listed) (x : a) (ys : int list) : int list =
  ys @ match w with Listed -> x
