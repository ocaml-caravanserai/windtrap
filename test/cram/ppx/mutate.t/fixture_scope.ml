(* [mul], [fmul] and [bit] must be in Stdlib scope: an operator under an
   opaque [open] or [include] can be another module's, so it has no site. A
   structure of the file is transparent. [ari] keeps the rule of the
   rebinding alone. *)

module M = struct
  let x = 1
end

module type S = sig
  val x : int
end

module F (X : S) = X

let before a b = a * b

(* Each form of a local open. *)
let local a b = M.(a * b)
let let_open a b = let open M in a * b
let listed a b = M.[ a * b ]
let banged a b = let open! M in a * b
let arrayed a b = M.[| a * b |]
let applied a b = let open F (M) in a * b
let packed (m : (module S)) a b =
  let module P = (val m) in
  P.(a * b)

let fcm (module P : S) a b = P.(a * b)

class k =
  let open M in
  object
    method product a b = a * b
  end

(* An open of a Stdlib module is opaque too. *)
let float_open a b = Float.(a *. b)
let int_open a b = Int.(a * b)
let list_open l b = List.(length l lsl b)
let printf_open a b = Printf.(sprintf "%d" (a * b))

(* An open or an include in a nested structure ends with it. *)
module Opened = struct
  open M

  let inside a b = a * b + x
end

module Included = struct
  include M

  let inside a b = a * b
end

let after_nested a b = a * b

(* A functor body that includes its parameter. *)
module G (X : S) = struct
  let before_include a b = a * b

  include X

  let after_include a b = a * b
end

(* An open in a region of [[@@@mutate off]] is open after the region. *)
module Region = struct
  [@@@mutate off]

  open M

  [@@@mutate on]

  let after_region a b = a * b + x
end

(* A structure of the file is transparent, but not if it includes a
   module. *)
open struct
  let y = 2
end

include struct
  let z = 3
end

let after_transparent a b = a * b + y + z

include struct
  include M
end

let after_include a b = a * b

(* [ari] keeps its [sub] site under an open, and [*] has no [div] site. *)
let mixed a b c = M.(a + b * c)

open M

let after_open a b = a * b
