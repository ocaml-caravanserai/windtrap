(* A counter has a site where each opaque module is a module of the fixed
   list by its name. Another module, a longer path, a module expression
   that is not a path and each opaque form over such a module give no
   site. [Counters] is a module of another file. *)

(* Sites: a structure [open], a [let open], a class [let open] and an
   [include] of a module of the list. *)
module Opened = struct
  open Atomic

  let up (a : int Atomic.t) = incr a
end

let let_opened (a : int Atomic.t) =
  let open Atomic in
  incr a

class let_opened_class (a : int Atomic.t) =
  let open Atomic in
  object
    method up = incr a
  end

module Included = struct
  include Int

  let up r = incr r
end

(* A site: the check reads only the name of each module. Thus [Array]
   counts as a module of the list, but it is [Float.Array]. *)
let nested r = Float.(Array.(incr r))

(* No site: a module that is not in the list, under each opaque form. *)
let under_open r =
  let open Counters in
  incr r

let under_path r = Counters.(incr r)

module Under_include = struct
  include Counters

  let up r = incr r
end

class under_class r =
  let open Counters in
  object
    method up = incr r
  end

module Structure_open = struct
  open Counters

  let up r = incr r
end

(* No site: a longer path, and a module expression that is not a path. *)
let float_array r = Float.Array.(incr r)
let stdlib_atomic (a : int Atomic.t) = Stdlib.Atomic.(incr a)

module type S = sig
  type t
end

let unseen r (module C : S) =
  let open C in
  incr r

let first_class r m =
  let open (val m : S) in
  incr r
