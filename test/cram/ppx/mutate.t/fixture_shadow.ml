(* A file that visibly rebinds an operator gets no sites for that
   family, and only that family: the armed arm of [ari], as of [mul],
   [fmul] and [bit], names an operator the source did not write, so it
   must not be emitted where [+] means something else. [cmp] and [con]
   keep their sites here. For [ari], the rewriter does not see what an
   [open] brings in. Such an operator gives one compile error at its
   location in the source, and [[@@@mutate exclude_file]] removes it. *)

module Vec = struct
  type t = { x : int; y : int }

  let ( + ) a b = { x = a.x + b.x; y = a.y + b.y }
end

let move a b = Vec.( + ) a b
let ordered a b = if a < b then 1 else 0
let both a b = a && b
let untouched a b = a - b
