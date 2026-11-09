(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The operators of float_ops.ml under each opaque form of open. A site
   under one of them gives an arm that applies a Stdlib operator to floats,
   booleans, strings or an abstract type, so this module compiles only
   because these forms have no site of [mul], [fmul] or [bit]. The sites
   outside the opens stay. *)

let product a b = a * b
let local a b = Float_ops.(a * b)

let let_open a b =
  let open Float_ops in
  a mod b

let banged a b =
  let open! Float_ops in
  a land b

let strings a b = Float_ops.(a *. b)
let listed a b = Float_ops.[ a * b ]
let arrayed a b = Float_ops.[| a * b |]

let applied a b =
  let open Float_ops.Make (struct end) in
  a * b

let unpacked (type a) (module P : Float_ops.Ops with type t = a) (x : a) =
  P.(x * x)

class squares =
  let open Float_ops in
  object
    method square (x : float) = x * x
  end

module Opened = struct
  open Float_ops

  let inside a b = a * b
end

let quotient a b = a / b

module Included = struct
  include Float_ops

  let inside a b = a * b
end

let fquotient a b = a /. b

module Square (X : Float_ops.Ops) = struct
  include X

  let square a = a * a
end

let shifted a b = a lsl b

include Float_ops

let after a b = a * b
