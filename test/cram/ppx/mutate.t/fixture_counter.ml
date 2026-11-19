(* [decr] and [incr]: a counter on a pure operand. The arm has the path of
   the source, so [Atomic.( incr c )] gives [decr c]. A statement carries
   [del] and the counter at one byte. *)

let up r = incr r
let down r = decr r
let atomic_up (a : int Atomic.t) = Atomic.incr a
let atomic_down (a : int Atomic.t) = Atomic.decr a
let opened (c : int Atomic.t) = Atomic.(incr c)
let int_opened r = Int.(incr r)
let printf_opened r = Printf.(incr r)

type state = { count : int ref }

let counted s = incr s.count
let constrained r = incr (r : int ref)

let statement r x =
  incr r;
  x

let branch c r = if c then incr r

(* Code that runs at load has its site. *)
let loaded = ref 0
let () = incr loaded
let dismissed r = (incr r) [@mutate off "the count is a statistic"]

(* No site: an operand that is not pure, as a call, a record literal or a
   GADT [match], a qualified [Stdlib.incr], an application through [|>] or
   [@@], and a partial counter. *)
let effectful f = incr (f ())
let qualified r = Stdlib.incr r
let piped r = r |> incr
let applied r = incr @@ r
let partial l = List.iter incr l
let built () = incr { contents = 0 }

type _ witness = Ref : int ref witness

let gadt (type a) (w : a witness) (x : a) = incr (match w with Ref -> x)
