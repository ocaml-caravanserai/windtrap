(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The operators of float_ops.ml under each opaque form of open. A site
   under one of them gives an arm that applies a Stdlib operator to floats,
   booleans, strings or an abstract type, so this module compiles only
   because these forms have no site of [mul], [fmul], [bit], [pos], [left],
   [decr] or [incr]. The sites outside the opens stay. *)

let product a b = a * b
let local a b = Float_ops.(a * b)
let local_unary b s r = Float_ops.(-b, -.s, s @ s, incr r)

let let_open a b =
  let open Float_ops in
  a mod b

let let_open_unary b s r =
  let open Float_ops in
  (-b, -.s, s @ s, incr r)

let banged a b =
  let open! Float_ops in
  a land b

let banged_unary b s r =
  let open! Float_ops in
  (-b, -.s, s @ s, incr r)

let strings a b = Float_ops.(a *. b)
let listed a b = Float_ops.[ a * b ]
let arrayed a b = Float_ops.[| a * b |]

let applied a b =
  let open Float_ops.Make (struct end) in
  a * b

let applied_unary b s =
  let open Float_ops.Make (struct end) in
  (-b, s @ s)

let unpacked (type a) (module P : Float_ops.Ops with type t = a) (x : a) =
  P.(x * x)

let unpacked_unary (type a) (module P : Float_ops.Ops with type t = a) (x : a) =
  P.(-x)

class squares =
  let open Float_ops in
  object
    method square (x : float) = x * x
    method unary b s r = (-b, -.s, s @ s, incr r)
  end

module Opened = struct
  open Float_ops

  let inside a b = a * b
  let unary b s r = (-b, -.s, s @ s, incr r)
end

let quotient a b = a / b

module Included = struct
  include Float_ops

  let inside a b = a * b
  let unary b s r = (-b, -.s, s @ s, incr r)
end

let fquotient a b = a /. b

module Square (X : Float_ops.Ops) = struct
  include X

  let square a = a * a
  let negated a = -a
end

let shifted a b = a lsl b

include Float_ops

let after a b = a * b
let after_unary b s r = (-b, -.s, s @ s, incr r)
