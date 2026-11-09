(* A file that binds [/] loses the [mul] family, [*] and [mod] included,
   so no guard applies [/] to [int]. The operand [2] of [x * 2] keeps its
   [int] site. [ari], [fmul] and [bit] keep their sites. *)

let ( / ) = Filename.concat
let path a b = a / b
let area a b = a * b
let rest a b = a mod b
let scaled x = x * 2
let sum a b = a + b
let diff a b = a - b
let ftimes a b = a *. b
let both a b = a land b
