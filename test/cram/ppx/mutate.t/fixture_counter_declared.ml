(* A module that the file declares with the name of a module of the list
   is not Stdlib's. [Atomic.incr a] and a counter under [Int.( ... )] have
   no site. A bare counter outside the opens keeps its site. *)

module Atomic = struct
  type t = int ref

  let make n : t = ref n
end

module Int = struct end

let atomic (a : int Stdlib.Atomic.t) = Atomic.incr a
let opened r = Int.(incr r)
let bare r = incr r
