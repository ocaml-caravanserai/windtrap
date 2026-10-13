(* [same body as the next case]: a case without a guard whose body is that
   of the next case, when the next case is [_], gives the same value
   dropped. A case that binds a variable, a case with a guard and a next
   case other than [_] keep their mutants. *)

let kind = function `A -> 0 | _ -> 0
let bound = function Some _x -> 0 | _ -> 0
let guarded p = function `A when p -> 0 | _ -> 0
let named = function `A -> 0 | x -> ignore x; 0
let call f = function `A -> f () | _ -> f ()
let handler f = try f () with Not_found -> 0 | _ -> 0
let raised f =
  match f () with v -> v | exception Not_found -> 0 | exception _ -> 0
