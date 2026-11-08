(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The libraries of this directory are instrumented in every build, so that
   they compile is the check on the generated code: fatal warnings, a
   shadowed [not] and [bool], the typing order and the expected type of an
   operand. This suite checks what compiling cannot: with nothing armed each
   function computes its original result, and an armed mutant computes the
   rewrite its site names. *)

open Windtrap
module Mutate = Windtrap_runtime.Mutate
module Oracle = Windtrap_mutate_forced.Oracle
module Forced = Windtrap_mutate_forced.Forced
module Own_unit = Windtrap_mutate_forced.Own_unit
module No_guard = Windtrap_mutate_forced.No_guard
module Arid = Windtrap_mutate_forced.Arid
module Loose = Windtrap_mutate_loose.Loose
module Disambiguate = Windtrap_mutate_disambiguate.Disambiguate
module Expected_type = Windtrap_mutate_disambiguate.Expected_type

let strf = Printf.sprintf

(* Arming *)

(* [arm] disarms the armed mutant before it resolves, so arming an identifier
   of no catalogued file leaves nothing armed. *)
let disarm () =
  let nowhere =
    { Mutate.file = "<nowhere>.ml"; line = 1; col = 0; rewrite = "not" }
  in
  match Mutate.arm nowhere with
  | Error (Mutate.Uncatalogued _) -> ()
  | Ok _ | Error (Malformed _ | Unmatched _ | Ambiguous _) ->
      fail "an identifier of no catalogued file armed a mutant"

let mutants_of file =
  List.filter
    (fun (m : Mutate.mutant) -> String.equal (Filename.basename m.id.file) file)
    (Mutate.catalogue ())

let pp_ids ppf mutants =
  let id ppf (m : Mutate.mutant) =
    Format.pp_print_string ppf (Mutate.id_to_string m.id)
  in
  Format.pp_print_list ~pp_sep:Format.pp_print_space id ppf mutants

(* [armed ~file ~rewrite ~before ?after f] is [f ()] with the one mutant of
   [file] that has this rewrite and these texts armed. Finding it by its
   texts keeps the rendered texts under test. *)
let armed ~file ~rewrite ~before ?after f =
  let named (m : Mutate.mutant) =
    String.equal m.id.rewrite rewrite
    && String.equal m.before before
    && Option.fold ~none:true ~some:(String.equal m.after) after
  in
  let m =
    require_match ~msg:"one mutant has this rewrite and this text" ~pp:pp_ids
      (function [ m ] -> Some m | _ -> None)
      (List.filter named (mutants_of file))
  in
  ignore (require_ok ~pp:Mutate.pp_arm_error (Mutate.arm m.id) : Mutate.mutant);
  Fun.protect ~finally:disarm f

let ints = List.map Int.to_string
let bools = List.map Bool.to_string
let floats = List.map Float.to_string
let spot (s : Oracle.spot) = ints [ s.col; s.row; s.layer ]

(* [traced f] is the operands [f] evaluated, in order. *)
let traced f =
  ignore (f ());
  String.concat "," (Oracle.record ())

(* The corpora's values *)

let rect = { Disambiguate.Layout.x = 10; y = 20; width = 30; height = 40 }
let collide = { Disambiguate.Rect.x = 10; y = 20; width = 30; height = 40 }
let line = { Disambiguate.Line.start = 2; end_ = 7 }
let empty_line = { Disambiguate.Line.start = 7; end_ = 7 }

let item =
  let sides left right =
    { Disambiguate.Sides.left; right; top = 0.; bottom = 0. }
  in
  { Disambiguate.padding = sides 1. 2.; border = sides 3. 4. }

let point y = { Expected_type.Point.x = 0; y }

(* Disarmed *)

let originals =
  [
    ("neg_pick true", "1", fun () -> Int.to_string (Oracle.neg_pick true));
    ("cmp_lt 2 2", "0", fun () -> Int.to_string (Oracle.cmp_lt 2 2));
    ("cmp_le 2 2", "1", fun () -> Int.to_string (Oracle.cmp_le 2 2));
    ( "con_and false true",
      "false",
      fun () -> Bool.to_string (Oracle.con_and false true) );
    ( "con_or true false",
      "true",
      fun () -> Bool.to_string (Oracle.con_or true false) );
    ("ari_add 5 3", "8", fun () -> Int.to_string (Oracle.ari_add 5 3));
    ("ari_sub 5 3", "2", fun () -> Int.to_string (Oracle.ari_sub 5 3));
    ("del_count", "1", fun () -> Int.to_string (Oracle.del_count ()));
    ("del_then true", "7", fun () -> Int.to_string (Oracle.del_then true));
    ("del_last true", "10", fun () -> Int.to_string (Oracle.del_last true));
    ("del_while 3", "3", fun () -> Int.to_string (Oracle.del_while 3));
    ("del_for 4", "10", fun () -> Int.to_string (Oracle.del_for 4));
    ("Loose.sum_for 4", "10", fun () -> Int.to_string (Loose.sum_for 4));
    ("Loose.sum_while 4", "10", fun () -> Int.to_string (Loose.sum_while 4));
    ("Own_unit.count 3", "5", fun () -> Int.to_string (Own_unit.count 3));
    ("int_up", "41", fun () -> Int.to_string (Oracle.int_up ()));
    ("int_down", "1", fun () -> Int64.to_string (Oracle.int_down ()));
    ( "bool_flip",
      "true",
      fun () ->
        Option.fold ~none:"none" ~some:Bool.to_string (Oracle.bool_flip ()) );
    ( "none_some 1",
      "1",
      fun () ->
        Option.fold ~none:"none" ~some:Int.to_string (Oracle.none_some 1) );
    ( "tail_cons 1 [ 2 ]",
      "1,2",
      fun () -> String.concat "," (ints (Oracle.tail_cons 1 [ 2 ])) );
    ( "the operands of none_order",
      "e",
      fun () -> traced (fun () -> Oracle.none_order 1) );
    ( "the operands of tail_order",
      "t,h",
      fun () -> traced (fun () -> Oracle.tail_order 1 [ 2 ]) );
    ( "keep_one corner 5",
      "5,2,3",
      fun () -> String.concat "," (spot (Oracle.keep_one Oracle.corner 5)) );
    ( "keep_two corner 5 6",
      "5,6,3",
      fun () -> String.concat "," (spot (Oracle.keep_two Oracle.corner 5 6)) );
    ( "the operands of keep_order",
      "p,w,c",
      fun () -> traced (fun () -> Oracle.keep_order Oracle.corner 5 6) );
    ( "the operands of cmp_order",
      "r,l",
      fun () -> traced (fun () -> Oracle.cmp_order 1 2) );
    ( "the operands of ari_order",
      "r,l",
      fun () -> traced (fun () -> Oracle.ari_order 1 2) );
    ( "the right operand of con_short false",
      "",
      fun () -> traced (fun () -> Oracle.con_short false true) );
    ( "the right operand of con_short true",
      "r",
      fun () -> traced (fun () -> Oracle.con_short true true) );
    ("clip", "130", fun () -> Int.to_string (Disambiguate.clip rect 0 0 100 100));
    ("span", "5", fun () -> Int.to_string (Disambiguate.span line));
    ("inverted", "0", fun () -> Int.to_string (Disambiguate.inverted line));
    ( "horizontal",
      "10.",
      fun () -> Float.to_string (Disambiguate.horizontal item) );
    ( "clip_collide",
      "130",
      fun () -> Int.to_string (Disambiguate.clip_collide collide 5 0 100 100) );
    ( "before_green Red",
      "1",
      fun () ->
        Int.to_string (Expected_type.before_green Expected_type.Color.Red) );
    ( "before_green Green",
      "0",
      fun () ->
        Int.to_string (Expected_type.before_green Expected_type.Color.Green) );
    ( "past_green Blue",
      "1",
      fun () ->
        Int.to_string (Expected_type.past_green Expected_type.Color.Blue) );
    ( "past_green Green",
      "0",
      fun () ->
        Int.to_string (Expected_type.past_green Expected_type.Color.Green) );
    ( "within Green",
      "true",
      fun () -> Bool.to_string (Expected_type.within Expected_type.Color.Green)
    );
    ( "within Blue",
      "false",
      fun () -> Bool.to_string (Expected_type.within Expected_type.Color.Blue)
    );
    ( "below { x = 0; y = 5 }",
      "1",
      fun () -> Int.to_string (Expected_type.below (point 5)) );
    ( "below { x = 0; y = 10 }",
      "0",
      fun () -> Int.to_string (Expected_type.below (point 10)) );
    ( "is_green Green",
      "1",
      fun () -> Int.to_string (Expected_type.is_green Expected_type.Color.Green)
    );
    ( "a dismissed site's cap 20",
      "20",
      fun () -> Int.to_string (No_guard.cap 20) );
  ]

let disarmed =
  group "Disarmed"
    [
      cases "with nothing armed, a function computes its original result"
        ~id:(fun (name, _, _) -> name)
        originals
        (fun (_, expected, actual) -> equal string expected (actual ()));
    ]

(* Armed *)

type arming = {
  file : string;
  rewrite : string;
  before : string;
  observe : unit -> string list; (* values where the two readings differ *)
  mutated : string list;
}

let oracle rewrite before observe mutated =
  { file = "oracle.ml"; rewrite; before; observe; mutated }

let truth_table f =
  bools [ f true true; f true false; f false true; f false false ]

(* Each comparison is read at the boundary, where it and its rewrite differ,
   and away from it, where they agree. *)
let armings =
  [
    oracle "not" "flag"
      (fun () -> ints [ Oracle.neg_pick true; Oracle.neg_pick false ])
      [ "0"; "1" ];
    oracle "le" "a < b"
      (fun () -> ints [ Oracle.cmp_lt 2 2; Oracle.cmp_lt 3 2 ])
      [ "1"; "0" ];
    oracle "lt" "a <= b"
      (fun () -> ints [ Oracle.cmp_le 2 2; Oracle.cmp_le 1 2 ])
      [ "0"; "1" ];
    oracle "ge" "a > b"
      (fun () -> ints [ Oracle.cmp_gt 2 2; Oracle.cmp_gt 1 2 ])
      [ "1"; "0" ];
    oracle "gt" "a >= b"
      (fun () -> ints [ Oracle.cmp_ge 2 2; Oracle.cmp_ge 3 2 ])
      [ "0"; "1" ];
    oracle "neq" "a = b"
      (fun () -> ints [ Oracle.cmp_eq 2 2; Oracle.cmp_eq 1 2 ])
      [ "0"; "1" ];
    oracle "eq" "a <> b"
      (fun () -> ints [ Oracle.cmp_ne 2 2; Oracle.cmp_ne 1 2 ])
      [ "1"; "0" ];
    oracle "or" "a && b"
      (fun () -> truth_table Oracle.con_and)
      (bools [ true; true; true; false ]);
    oracle "and" "a || b"
      (fun () -> truth_table Oracle.con_or)
      (bools [ true; false; false; false ]);
    oracle "sub" "a + b" (fun () -> ints [ Oracle.ari_add 5 3 ]) [ "2" ];
    oracle "add" "a - b" (fun () -> ints [ Oracle.ari_sub 5 3 ]) [ "8" ];
    oracle "fsub" "a +. b" (fun () -> floats [ Oracle.ari_fadd 5. 3. ]) [ "2." ];
    oracle "fadd" "a -. b" (fun () -> floats [ Oracle.ari_fsub 5. 3. ]) [ "8." ];
    oracle "del" "incr dropped" (fun () -> ints [ Oracle.del_count () ]) [ "0" ];
    oracle "del" "shown := 7" (fun () -> ints [ Oracle.del_then true ]) [ "0" ];
    oracle "del" "steps := ((!steps) * 10)"
      (fun () -> ints [ Oracle.del_last true ])
      [ "1" ];
    oracle "del" "incr seen" (fun () -> ints [ Oracle.del_while 3 ]) [ "0" ];
    oracle "del" "total := ((!total) + i)"
      (fun () -> ints [ Oracle.del_for 4 ])
      [ "0" ];
    {
      file = "loose.ml";
      rewrite = "del";
      before = "add_to total i";
      observe = (fun () -> ints [ Loose.sum_for 4 ]);
      mutated = [ "0" ];
    };
    {
      file = "loose.ml";
      rewrite = "del";
      before = "add_to total (!i)";
      observe = (fun () -> ints [ Loose.sum_while 4 ]);
      mutated = [ "0" ];
    };
    oracle "int" "41" (fun () -> ints [ Oracle.int_up () ]) [ "42" ];
    oracle "int" "1L"
      (fun () -> [ Int64.to_string (Oracle.int_down ()) ])
      [ "0" ];
    oracle "bool" "true"
      (fun () ->
        [ Option.fold ~none:"none" ~some:Bool.to_string (Oracle.bool_flip ()) ])
      [ "false" ];
    oracle "none" "Some x"
      (fun () ->
        [ Option.fold ~none:"none" ~some:Int.to_string (Oracle.none_some 1) ])
      [ "none" ];
    oracle "tail" "h :: t"
      (fun () -> ints (Oracle.tail_cons 1 [ 2; 3 ]))
      [ "2"; "3" ];
    (* Armed, the two encodings that bind their operands still evaluate each
       once, right to left, and the connective runs its right operand when the
       rewrite says so. *)
    oracle "le" "(note \"l\" a) < (note \"r\" b)"
      (fun () -> [ traced (fun () -> Oracle.cmp_order 1 2) ])
      [ "r,l" ];
    oracle "sub" "(note \"l\" a) + (note \"r\" b)"
      (fun () -> [ traced (fun () -> Oracle.ari_order 1 2) ])
      [ "r,l" ];
    oracle "or" "a && (note \"r\" b)"
      (fun () ->
        [
          traced (fun () -> Oracle.con_short false true);
          traced (fun () -> Oracle.con_short true true);
        ])
      [ "r"; "" ];
    (* Armed, a [none] or [tail] mutant evaluates what its [after] text holds
       and no more. *)
    oracle "none" "Some (note \"e\" x)"
      (fun () -> [ traced (fun () -> Oracle.none_order 1) ])
      [ "" ];
    oracle "tail" "(note \"h\" h) :: (note \"t\" t)"
      (fun () -> [ traced (fun () -> Oracle.tail_order 1 [ 2 ]) ])
      [ "t" ];
    {
      file = "disambiguate.ml";
      rewrite = "add";
      before = "rect.Rect.x - x0";
      observe =
        (fun () -> ints [ Disambiguate.clip_collide collide 5 0 100 100 ]);
      mutated = [ "140" ];
    };
    {
      file = "disambiguate.ml";
      rewrite = "add";
      before = "line.Line.end_ - line.start";
      observe = (fun () -> ints [ Disambiguate.span line ]);
      mutated = [ "9" ];
    };
    {
      file = "disambiguate.ml";
      rewrite = "le";
      before = "line.Line.end_ < line.start";
      observe =
        (fun () ->
          ints [ Disambiguate.inverted line; Disambiguate.inverted empty_line ]);
      mutated = [ "0"; "1" ];
    };
    {
      file = "disambiguate.ml";
      rewrite = "fsub";
      before =
        "(((child.padding).left +. (child.padding).right) +. \
         (child.border).left) +. (child.border).right";
      observe = (fun () -> floats [ Disambiguate.horizontal item ]);
      mutated = [ "2." ];
    };
    {
      file = "expected_type.ml";
      rewrite = "le";
      before = "c < Green";
      observe =
        (fun () ->
          ints [ Expected_type.before_green Expected_type.Color.Green ]);
      mutated = [ "1" ];
    };
    {
      file = "expected_type.ml";
      rewrite = "le";
      before = "p < { x = 0; y = 10 }";
      observe = (fun () -> ints [ Expected_type.below (point 10) ]);
      mutated = [ "1" ];
    };
  ]

(* The two [keep] sites of one update have one [before] text, so a row of
   [keep] names its site by its [after] text too. *)
let kept =
  let row before after observe mutated = (before, after, observe, mutated) in
  [
    row "{ p with col = n }" "p"
      (fun () -> spot (Oracle.keep_one Oracle.corner 5))
      [ "1"; "2"; "3" ];
    row "{ p with col = a; row = b }" "{ p with row = b }"
      (fun () -> spot (Oracle.keep_two Oracle.corner 5 6))
      [ "1"; "6"; "3" ];
    row "{ p with col = a; row = b }" "{ p with col = a }"
      (fun () -> spot (Oracle.keep_two Oracle.corner 5 6))
      [ "5"; "2"; "3" ];
    (* Armed, the update does not evaluate the value of the dropped
       field. *)
    row "{ (note \"p\" p) with col = (note \"c\" a); row = (note \"w\" b) }"
      "{ (note \"p\" p) with row = (note \"w\" b) }"
      (fun () -> [ traced (fun () -> Oracle.keep_order Oracle.corner 5 6) ])
      [ "p,w" ];
  ]

let kept_name (before, after, _, _) = strf "%s, armed keep to %s" before after

let kept_row (before, after, observe, mutated) =
  equal (list string) mutated
    (armed ~file:"oracle.ml" ~rewrite:"keep" ~before ~after observe)

let arming_name a = strf "%s: %s, armed %s" a.file a.before a.rewrite

let armed_row a =
  equal (list string) a.mutated
    (armed ~file:a.file ~rewrite:a.rewrite ~before:a.before a.observe)

let armed_mutants =
  group "Armed"
    [
      cases "an armed mutant computes the rewrite its site names"
        ~id:arming_name armings armed_row;
      cases "an armed keep mutant computes the update its site names"
        ~id:kept_name kept kept_row;
    ]

(* Every mutant *)

(* [forced ()] reads the functions of forced.ml that its mutants change. *)
let forced () =
  strf "%d %d %.1f %b %b %b %b %d %d %d %d %b" (Forced.sum 2 3)
    (Forced.diff 9 4) (Forced.fsum 1.5 2.5) (Forced.both true false)
    (Forced.either false true) (Forced.window 0 10 5)
    (Forced.chain true true false)
    (Forced.below 1 2) (Forced.same 1 1) (Forced.at_least 3 3)
    (Forced.scaled 2 3)
    (Forced.search (fun x -> x > 2) [ 1; 2; 3 ])

let every_forced_mutant () =
  let original = forced () in
  let reading (m : Mutate.mutant) =
    ignore
      (require_ok ~pp:Mutate.pp_arm_error (Mutate.arm m.id) : Mutate.mutant);
    let armed = forced () in
    disarm ();
    (Mutate.id_to_string m.id, armed, forced ())
  in
  let readings = List.map reading (mutants_of "forced.ml") in
  let ids keep =
    List.filter_map
      (fun ((id, _, _) as r) -> if keep r then Some id else None)
      readings
  in
  not_equal ~msg:"the mutants that change the reading" (list string) []
    (ids (fun (_, armed, _) -> armed <> original));
  equal ~msg:"the mutants that leave a change after disarming" (list string) []
    (ids (fun (_, _, after) -> after <> original))

let every_mutant =
  group "Every mutant"
    [
      test "arming a mutant changes a reading and disarming restores it"
        every_forced_mutant;
    ]

(* Arid sites *)

let arid_reading () =
  Arid.logged 4;
  strf "%d %d %b %d %d %d" (Arid.zero 4) (Arid.chain 5 3) (Arid.same true)
    (Arid.branches false 7) (Arid.message 2)
    (Queue.take Windtrap_mutate_forced.Logs.logged)

let arid_sites () =
  let site (m : Mutate.mutant) = strf "%s %s" m.id.rewrite m.before in
  equal string "4 8 true 7 2 8" (arid_reading ());
  equal (list string)
    [ "sub a + b"; "le n < 0" ]
    (List.map site (mutants_of "arid.ml"))

(* [x + 0] is at line 11, column 13, of arid.ml. *)
let arid_unmatched () =
  let file =
    match mutants_of "arid.ml" with
    | m :: _ -> m.id.file
    | [] -> fail "arid.ml has no catalogued mutant"
  in
  match Mutate.arm { Mutate.file; line = 11; col = 13; rewrite = "sub" } with
  | Error (Mutate.Unmatched _) -> ()
  | Ok _ | Error (Malformed _ | Uncatalogued _ | Ambiguous _) ->
      disarm ();
      fail "the identifier of an arid site armed a mutant"

let arid =
  group "Arid sites"
    [
      test "the catalogue holds no arid site" arid_sites;
      test "the identifier of an arid site arms no mutant" arid_unmatched;
      test "the left operand of an arid chain keeps its mutant" (fun () ->
          equal string "2"
            (armed ~file:"arid.ml" ~rewrite:"sub" ~before:"a + b" (fun () ->
                 Int.to_string (Arid.chain 5 3))));
    ]

(* A file that declares the constructors of a guard *)

(* The test reads [size], so that the module is linked and registers its
   sites. *)
let lost_families () =
  let rewrite (m : Mutate.mutant) = m.id.rewrite in
  equal int 3 Windtrap_mutate_forced.Own_constructors.size;
  equal (list string) [ "ge"; "int" ]
    (List.map rewrite (mutants_of "own_constructors.ml"))

let lost =
  group "Lost families"
    [
      test "a file that declares Some and (::) has no none and no tail mutant"
        lost_families;
    ]

let () =
  exit
    (run "mutate registration"
       [ disarmed; armed_mutants; every_mutant; arid; lost ])
