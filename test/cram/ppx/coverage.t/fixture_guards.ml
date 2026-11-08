(* The coverage rewriter over a file that holds the mutation rewriter's guards.
   A guard is generated code and takes no mark: every node of a guard is
   ghost but its disarmed arm, which keeps its site's location, so that arm
   alone is marked. The disarmed arm of the [del] guard of a statement or
   a loop body is [e; ()]: [e] keeps its location, and [()] has a location
   at the end of [e], where the coverage rewriter keys the out-edge of [e].
   The arm [e; ()] is ghost on a statement and has the location of [e] on
   a loop body. ppx/mutate/instrument.mli lists the points that differ
   from those of the coverage rewriter alone. *)

(* The disarmed arm of an ordering or [ari] guard is marked as the branch of
   an [if], whether or not the site is a block: [a < b] is a condition, and
   [a + b] is no block at all. *)
let lt a b = if a < b then 1 else 0
let add a b = a + b

(* A block that is a [neg], an equality or a [con] site has no entry point:
   the three guards of [match], and the [then] branch of [both]. *)
let arms x p a b =
  match x with
  | 0 when p x -> "neg"
  | 1 when a = b -> "equality"
  | 2 when a && b -> "con"
  | _ -> "other"

let both c a b = if c then a && b else false

(* An application that is a [neg] site, or the left operand of a [con]
   site, has no out-edge. *)
let rec loop f x =
  while f x do
    loop f x
  done

let left f g x = ignore (f x && g x)

(* A [||] that is a site is not rewritten, and its right operand is marked
   as a branch of the guard. *)
let either a b = a || b

(* The disarmed arm of a [none] or [tail] guard keeps the location of its
   site, and is marked as the branch of an [if]. The armed arm of a [tail]
   guard is a copy of the tail with ghost locations, which has no point. *)
let wrap f x = Some (f x)
let push f g x xs = f x :: g xs

(* A statement keeps its out-edge, and a loop body keeps its entry point and
   its out-edge. In [count], the callee [f] has one byte. The coverage
   rewriter alone gives one point to the entry point and the out-edge of the
   loop body, but here they are two points. *)
let twice f x =
  f x;
  f x

let drain more step = while more () do step () done
let count f lo hi = for i = lo to hi do f i done

(* The guard of [step b] is an [if] with an [else], and its disarmed arm
   [step b] has a point that the coverage rewriter alone does not give. *)
let both_steps step a b c =
  if c then (
    step a;
    step b)
