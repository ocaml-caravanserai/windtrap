(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* A GADT [match] whose type comes from the expected type of the site. A
   guard that binds the [match] with no constraint gives it the abstract type
   [a], and the arm does not compile. *)

type _ truth = Truth : bool truth
type _ whole = Whole : int whole
type _ real = Real : float real
type packed = Packed : 'a whole * 'a -> packed

let decide (type a) (w : a truth) (x : a) =
  if match w with Truth -> x then 1 else 0

let both (type a) (w : a truth) (x : a) c = (match w with Truth -> x) && c

type _ value = Bool : bool value | Int : int value

let listed (type a) (t : a value) (v : a) x =
  [ (x && match t with Bool -> v | Int -> v > 0) ]

let succ (type a) (w : a whole) (x : a) = (match w with Whole -> x) + 1
let fsucc (type a) (w : a real) (x : a) = (match w with Real -> x) +. 1.
let unpacked p = (match p with Packed (Whole, v) -> v) - 1
