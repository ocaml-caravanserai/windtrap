(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The [keep] guards of these record updates compile under fatal warnings.
   The dune file copies this file to kept_principal.ml, which compiles under
   -principal too. The type-checker reads an armed arm after the original,
   and the warning attribute of the arm disables the warnings of
   type-directed disambiguation that the original does not give. *)

type point = { x : int; y : int; name : string }

let move p dx = { p with x = dx }
let place p dx dy = { p with x = dx; y = dy }

type wide = {
  a : int;
  b : int;
  c : int;
  d : int;
  e : int;
  f : int;
  g : int;
  h : int;
  i : int;
  j : int;
}

let eight w v =
  { w with a = v; b = v; c = v; d = v; e = v; f = v; g = v; h = v }

let nine w v =
  { w with a = v; b = v; c = v; d = v; e = v; f = v; g = v; h = v; i = v }

(* The arm that drops [M.u] moves the path to [v]. *)
module M = struct
  type t = { u : int; v : int; w : int; k : int }
end

let moved (r : M.t) n = { r with M.u = n; v = n; w = n }
let both_qualified (r : M.t) n = { r with M.u = n; M.v = n }
let one_qualified (r : M.t) n = { r with M.u = n }

(* An inline record, and a constructor whose argument is a record. *)
type shape = Box of { width : int; height : int; depth : int } | Dot
type wrapped = Wrap of point

let widen s n =
  match s with Box r -> Box { r with width = n; height = n } | Dot -> Dot

let narrow s n = match s with Box r -> Box { r with width = n } | Dot -> Dot
let wrap p n = Wrap { p with x = n }
let some p n = Some { p with x = n; y = n }

(* A nested update, a call as [r], a value with an effect, and a field that
   the source puns. *)
type pair = { inner : point; outer : int; tag : string }

let nested q n = { q with inner = { q.inner with y = n }; outer = n }
let fresh origin n = { (origin ()) with y = n }

let noisy p n =
  {
    p with
    x =
      (print_int n;
       n);
    y = n;
  }

let punned (p : point) x = { p with x }

(* A polymorphic field and a mutable field. *)
type poly = {
  apply : 'a. 'a -> 'a;
  times : int;
  mutable seen : int;
  title : string;
}

let reset r n = { r with apply = (fun v -> v); times = n; seen = 0 }

(* An arm that drops the field of a type parameter does not compile, and
   [[@mutate off]] removes the sites. *)
type 'a box = { item : 'a; count : int; label : string }

let relabel (b : int box) n =
  { b with item = string_of_int b.item; count = n }
  [@mutate off "the arm keeps the type of b"]

(* [older] and [newer] have the labels [x] and [z]. The original takes the
   labels of [older], the only type with [kind], and the type-checker reads
   the arm [{ r with x = n }] with the type of the original. *)
type older = { x : int; z : int; kind : string; size : int }
type newer = { x : int; z : int; more : int }

let by_labels r n s = { r with x = n; kind = s } [@ocaml.warning "-42"]
let latest (r : newer) n = { r with x = n; z = n }
