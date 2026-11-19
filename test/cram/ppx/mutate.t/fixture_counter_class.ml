(* An instance variable named [incr] loses [decr] and [incr] for the file,
   as a binding does. *)

type counter = { mutable n : int }

let o =
  object
    val incr = fun (c : counter) -> c.n <- c.n + 1
    method bump c = incr c
  end

let up r = incr r
