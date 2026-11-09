(* [mul], [fmul] and [bit]: one function for each operator. The guard is
   that of [ari], with the operands pinned to [ints] or [floats]. [mod],
   [xor] and [asr] name the operator of the source, so that [a / b mod c]
   has two sites at one byte. *)

let times a b = a * b
let divide a b = a / b
let modulo a b = a mod b
let ftimes a b = a *. b
let fdivide a b = a /. b
let both a b = a land b
let either a b = a lor b
let differ a b = a lxor b
let left a b = a lsl b
let right a b = a lsr b
let arith a b = a asr b

(* A chain of one operator has one site. Two operators, two sites. *)
let chain a b c = a * b * c
let mixed a b c = a * b / c
let two a b c = a / b mod c
let masked a b c = (a land b) lxor c
let shifted a b c = (a asr b) lsr c

(* [lsl] is right associative: [x lsl 1 lsl 2] is [x lsl (1 lsl 2)]. *)
let nested x = x lsl 1 lsl 2
let bracketed x = (x lsl 1) lsl 2

(* A prefix application is a site, at its bracket. A partial or a
   qualified operator is no site. *)
let prefix a b = ( * ) a b
let partial l = List.map (( * ) 2) l
let qualified a b = Stdlib.( * ) a b

(* An operand of [*] has no [int] site, but an operand of [lsl] has one. *)
let scaled x = x * 2
let quadrupled x = x lsl 2

(* Code that runs at load has its site, as for [ari]. *)
let size = 4 * 1024
let dismissed a b = (a * b) [@mutate off "the product is a size"]
let by_zero x = x * 0
let logged a b = Logs.debug (fun m -> m "%d" (a * b))
let failed a b = failwith (string_of_int (a * b))
