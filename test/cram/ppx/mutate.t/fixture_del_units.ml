(* [del] in a unit position: the then-branch of an [if] with no [else], the
   body of a loop, and the last statement of a sequence in such a position.
   The guard of a then-branch keeps the branch in tail position. *)

let count = ref 0
let bump flag = if flag then incr count

(* A sequence there carries no [del] of its own: each statement carries
   one, and the last one takes the form of the position. *)
let both flag =
  if flag then (
    incr count;
    print_int !count;
    print_newline ())

let drain pending =
  while !pending > 0 do
    decr pending
  done

let drain_noisy pending =
  while !pending > 0 do
    print_int !pending;
    decr pending
  done

let up n =
  for i = 1 to n do
    print_int i
  done

let down n =
  for i = n downto 1 do
    print_int i;
    print_newline ()
  done

(* A loop body can have a type other than [unit]. *)
let peek n =
  for _ = 1 to n do
    !count
  done

(* The recursive call stays a tail call. *)
let rec countdown n = if n > 0 then countdown (n - 1)

(* An [else] branch is no unit position. *)
let either flag = if flag then print_string "a" else print_string "b"

(* No site on [()], an [assert] or a release. *)
let nothing flag = if flag then ()
let checked flag = if flag then assert false
let finish flag oc = if flag then close_out oc

let finish_all more next =
  while more () do
    close_in (next ())
  done

(* No site in code that runs when the module is initialized. *)
let () = if Sys.word_size > 32 then print_string "loaded"

let () =
  for _ = 1 to 2 do
    print_string "loaded"
  done

(* [[@mutate off]] dismisses the site. *)
let quiet flag =
  if flag then (print_string "x" [@mutate off "the output is not checked"])

let quiet_last flag =
  if flag then (
    incr count;
    (print_string "x" [@mutate off "the output is not checked"]))

(* No site on [()] as a loop body or as the last statement of a sequence,
   and none on an opaque [lazy]. *)
let idle more =
  while more () do
    ()
  done

let bump_only flag =
  if flag then (
    incr count;
    ())

let deferred n =
  for _ = 1 to n do
    lazy count
  done
