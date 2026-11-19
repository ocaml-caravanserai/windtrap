(* A class body with an [inherit] can get an instance variable named [incr]
   from the parent, which the rewriter does not see. Its counters have no
   site. A class body with no [inherit] keeps its sites. *)

class base = object end

class child r =
  object
    inherit base
    method up = incr r
  end

let immediate r =
  object
    inherit base
    method up = incr r
  end

class plain r =
  object
    method up = incr r
  end
