(* In Stdlib scope, the guard of [ari] pins its operands to [ints] or
   [floats], so that an operand gets the expected type of the application.
   Under an opaque [open], [+] can take other types, and the guard does not
   pin. *)

module M = struct
  let x = 1
end

let pinned a b = a + b
let opened a b = M.(a + b)
let let_opened a b =
  let open M in
  a +. b
