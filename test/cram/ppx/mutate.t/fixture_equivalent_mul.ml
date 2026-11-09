(* Arid sites of [mul], [fmul] and [bit]: the replacement gives the value
   of the original on every operand. [x * 1], [x / 1], [x * -1] and
   [x / -1] are [x] or [-x], [min_int] too, and the float forms are the
   same under IEEE 754. A shift by [0] or of [0] does not change. [a land a]
   and [a lor a] are [a]. *)

let one x = x * 1
let div_one x = x / 1
let minus x = x * -1
let div_minus x = x / -1
let hex_one x = x * 0x1
let fone x = x *. 1.
let fdiv_one x = x /. 1.0
let fminus x = x *. -1.
let fdiv_minus x = x /. -1.
let shift x = x lsl 0
let shr x = x lsr 0
let sar x = x asr 0
let zero_shift n = 0 lsl n
let same_and a = a land a
let same_or a = a lor a

(* Not arid: the mutant differs. *)
let one_left x = 1 * x
let mod_one x = x mod 1
let mod_minus x = x mod -1
let by_zero x = x * 0
let zero_left x = 0 * x
let or_zero x = x lor 0
let and_all x = x land -1
let xor_zero x = x lxor 0
let same_xor a = a lxor a
let fone_left x = 1. *. x
let fzero x = x *. 0.
let constrained x = x * (1 : int)

(* An arid site ends the chain of its operator, so [a * b] keeps [div]. *)
let chain a b = a * b * 1
