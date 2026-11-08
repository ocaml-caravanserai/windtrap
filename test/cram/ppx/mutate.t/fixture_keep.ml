(* [keep] drops one field of a record update. Each field is a site, and the
   armed arm is the update without that field, or [r] when the field is the
   only one. An update of more than eight fields has no site. *)

type point = { x : int; y : int }

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
}

let eight w v = { w with a = v; b = v; c = v; d = v; e = v; f = v; g = v; h = v }

let nine w v =
  { w with a = v; b = v; c = v; d = v; e = v; f = v; g = v; h = v; i = v }

(* The path of a qualified field qualifies the others. When the dropped
   field alone has a path, the path moves to the first field that stays. *)
module M = struct
  type t = { u : int; v : int; w : int }
end

let moved (r : M.t) n = { r with M.u = n; v = n; w = n }
let both_qualified (r : M.t) n = { r with M.u = n; M.v = n }
let one_qualified (r : M.t) n = { r with M.u = n }

(* An inline record: the guard goes around the constructor. *)
type shape = Box of { width : int; height : int } | Dot

let widen s n =
  match s with Box r -> Box { r with width = n; height = n } | Dot -> Dot

let narrow s n = match s with Box r -> Box { r with width = n } | Dot -> Dot

(* A nested update, a call as [r], a value with an effect, and a field that
   the source puns. *)
type pair = { inner : point; outer : int }

let nested q n = { q with inner = { q.inner with y = n }; outer = n }
let fresh origin n = { (origin ()) with y = n }
let noisy p n = { p with x = (print_int n; n); y = n }
let punned p x = { p with x }

(* No site: dismissed, in a log message, at module load, and in the
   right-hand side of a [let rec]. *)
let dismissed p n = ({ p with x = n; y = n } [@mutate off "reason"])
let logged p n = Logs.debug (fun m -> m "%d" { p with x = n }.x)
let zero = { x = 0; y = 0 }
let base = { zero with x = 1 }

type node = { id : int; next : node option }

let looped t =
  let rec n = { t with next = Some n } in
  n
