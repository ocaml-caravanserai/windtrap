(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Sites of [mul], [fmul] and [bit] whose operands must get the expected type of
   the application: a GADT branch, a locally abstract result, a GADT
   [match] or an existential in an operand. The guard pins the operands to
   [ints] or [floats], so this module compiles under [-principal]. *)

type _ number = Int : int number | Float : float number

let scale : type a. a number -> a -> a =
 fun t v -> match t with Int -> v * 2 | Float -> v *. 2.

let halve : type a. a number -> a -> int =
 fun t v -> match t with Int -> v / 3 lor 1 | Float -> int_of_float (v /. 2.)

let magic x = Obj.magic x * 2
let square r = r.contents * r.contents

type _ whole = Whole : int whole
type _ real = Real : float real
type packed = Packed : 'a whole * 'a -> packed

let doubled (type a) (w : a whole) (x : a) = (match w with Whole -> x) * 2
let unpacked p = (match p with Packed (Whole, v) -> v) * 2
let shifted (type a) (w : a whole) = (match w with Whole -> 1) lsl 2
let fdoubled (type a) (w : a real) (x : a) = (match w with Real -> x) *. 2.
