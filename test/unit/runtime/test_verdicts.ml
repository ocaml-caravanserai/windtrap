(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Windtrap
module Instr = Windtrap_runtime.Instr
module Mutate = Windtrap_runtime.Mutate
module Verdicts = Windtrap_runtime.Verdicts

let strf = Printf.sprintf
let read path = In_channel.with_open_bin path In_channel.input_all
let id file line col rewrite = { Mutate.file; line; col; rewrite }
let zeros = String.make 32 '0'
let base_effort = { Verdicts.retries = 0; pass = 1; settings = zeros }

let record ?(before = "b") ?(after = "a") ?end_ ?source_digest ?previous
    ?(effort = base_effort) ?prefix ?(reused = false) (id : Mutate.id) verdict =
  let end_line, end_col =
    Option.value end_ ~default:(id.line, id.col + String.length before)
  in
  {
    Verdicts.id;
    end_line;
    end_col;
    before;
    after;
    source_digest;
    verdict;
    previous;
    effort;
    prefix;
    reused;
  }

let collection records = List.fold_left Verdicts.add Verdicts.empty records

(* Rows. Every string is quoted, so a row tells any two values apart. *)

let quoted names = String.concat " " (List.map (strf "%S") names)

let tests_row ts =
  String.concat ", " (List.map (fun t -> "[" ^ quoted t ^ "]") ts)

let int_row = Option.fold ~none:"none" ~some:string_of_int

let reason_row = function
  | Verdicts.Deadline { seconds } -> strf "deadline of %h s" seconds
  | Crashed { signal; status; how } ->
      strf "crashed (signal %s, status %s) %S" (int_row signal) (int_row status)
        how
  | Memory { mb } -> strf "memory of %d MB" mb
  | Flaky_kill { test; failure } ->
      strf "flaky kill by %s: %S" (tests_row [ test ]) failure
  | Other reason -> reason

let verdict_row = function
  | Verdicts.Killed { by = [] } -> "killed"
  | Killed { by } -> "killed by " ^ tests_row by
  | Killed_elsewhere { exe } -> strf "killed elsewhere by %S" exe
  | Unknown reason -> "unknown: " ^ reason_row reason
  | Survived { first; others } -> "survived by " ^ tests_row (first :: others)
  | Not_evaluated -> "not evaluated"
  | Outside_tests -> "outside tests"
  | Unreached -> "unreached"

let outcome_row = function
  | `Killed -> "killed"
  | `Survived -> "survived"
  | `Not_evaluated -> "not evaluated"

(* The effort, the prefix and the mark show only when they are not those of
   [record]. *)
let record_row (r : Verdicts.record) =
  strf "%S:%d:%d:%s (to %d:%d) %S -> %S%s: %s%s%s%s%s" r.id.file r.id.line
    r.id.col r.id.rewrite r.end_line r.end_col r.before r.after
    (Option.fold ~none:"" ~some:(strf " of %s") r.source_digest)
    (verdict_row r.verdict)
    (Option.fold ~none:"" ~some:(fun o -> " was " ^ outcome_row o) r.previous)
    (if r.effort = base_effort then ""
     else
       strf " (retries %d, pass %d, settings %S)" r.effort.retries r.effort.pass
         r.effort.settings)
    (Option.fold ~none:"" ~some:(strf " prefix %s") r.prefix)
    (if r.reused then " reused" else "")

let rows t = List.map record_row (Verdicts.records t)
let verdict = Testable.contramap verdict_row Testable.string
let records = Testable.contramap rows (list string)
let identity_row (i : Verdicts.identity) = strf "%S %s" i.exe i.digest
let identity = Testable.contramap identity_row Testable.string

let error_row = function
  | Verdicts.Unknown_format { path; header } ->
      strf "unknown format %s %S" path header
  | Unreadable { path; _ } -> "unreadable " ^ path
  | Corrupt { path; reason } -> strf "corrupt %s: %s" path reason

let load_rows = function
  | Ok { Verdicts.verdicts; identity; suite = _; refused = _; test_digests = _ }
    ->
      Ok (rows verdicts, Option.map identity_row identity)
  | Error e -> Error (error_row e)

let load_text s =
  let path = Filename.concat (temp_dir ()) "f.mutants" in
  Out_channel.with_open_bin path (fun oc -> output_string oc s);
  (path, Verdicts.load path)

let corrupt_path = function
  | Error (Verdicts.Corrupt { path; _ }) -> Some path
  | _ -> None

let saved ?identity ?suite t =
  let path = Filename.concat (temp_dir ()) "saved.mutants" in
  Verdicts.save ?identity ?suite path t;
  read path

(* Generators *)

let pp_verdict ppf v = Format.pp_print_string ppf (verdict_row v)
let pp_record ppf r = Format.pp_print_string ppf (record_row r)
let pp_records ppf t = Format.pp_print_string ppf (String.concat "\n" (rows t))
let pp_identity ppf i = Format.pp_print_string ppf (identity_row i)

(* Few names and identifiers, so that two draws often share one. *)
let small_verdict =
  let path =
    Gen.list ~size:(Gen.int_range 1 2) (Gen.of_list [ "g"; "t"; "u" ])
  in
  Gen.with_pp pp_verdict
    (Gen.frequency
       [
         (2, Gen.map Verdicts.killed (Gen.list ~size:(Gen.int_range 0 2) path));
         ( 1,
           Gen.map
             (fun exe -> Verdicts.Killed_elsewhere { exe })
             (Gen.of_list [ "x"; "y" ]) );
         ( 2,
           Gen.map
             (fun r -> Verdicts.Unknown r)
             (Gen.of_list
                Verdicts.
                  [
                    Other "x";
                    Other "its run y";
                    Crashed { signal = Some (-10); status = None; how = "y" };
                    Crashed { signal = None; status = Some 1; how = "y" };
                    Deadline { seconds = 2. };
                    Memory { mb = 8 };
                    Flaky_kill { test = [ "t" ]; failure = "x" };
                    Flaky_kill { test = [ "u" ]; failure = "x" };
                  ]) );
         (1, Gen.constant Verdicts.Not_evaluated);
         (3, Gen.map Verdicts.survived (Gen.list ~size:(Gen.int_range 1 3) path));
         (1, Gen.constant Verdicts.Outside_tests);
         (1, Gen.constant Verdicts.Unreached);
       ])

let small_digest =
  Gen.option (Gen.of_list [ String.make 32 'a'; String.make 32 'b' ])

let hex_digest =
  Gen.string_of ~size:(Gen.constant 32)
    (Gen.of_list (List.of_seq (String.to_seq "0123456789abcdef")))

let any_previous =
  Gen.option (Gen.of_list [ `Killed; `Survived; `Not_evaluated ])

(* Any effort, prefix and mark, so that the laws cover each of them. *)
let small_effort =
  Gen.map
    (fun (retries, pass, settings) -> { Verdicts.retries; pass; settings })
    (Gen.triple (Gen.int_range 0 1) (Gen.int_range 1 2)
       (Gen.of_list [ zeros; String.make 32 'f' ]))

let small_record =
  Gen.with_pp pp_record
    (Gen.map
       (fun ( (file, (line, stop), (before, after, source_digest), verdict),
              (previous, effort, prefix, reused) ) ->
         record ~before ~after ~end_:(line, stop) ?source_digest ?previous
           ~effort ?prefix ~reused (id file line 0 "lt") verdict)
       (Gen.pair
          (Gen.quad
             (Gen.of_list [ "lib/a.ml"; "lib/b.ml" ])
             (Gen.pair (Gen.int_range 1 2) (Gen.int_range 1 2))
             (Gen.triple
                (Gen.of_list [ "a"; "b" ])
                (Gen.of_list [ "a"; "b" ])
                small_digest)
             small_verdict)
          (Gen.quad any_previous small_effort small_digest Gen.bool)))

let small_collection =
  Gen.with_pp pp_records
    (Gen.map collection (Gen.list ~size:(Gen.int_range 0 6) small_record))

(* Any bytes in every name, and any identifier that load accepts. *)
let any_record =
  let name = Gen.string in
  let path = Gen.list ~size:(Gen.int_range 0 3) name in
  let int = Gen.option (Gen.int_range (-20) 300) in
  let reason =
    Gen.one_of
      [
        Gen.map
          (fun seconds -> Verdicts.Deadline { seconds })
          (Gen.float_range 0. 1e6);
        Gen.map
          (fun ((signal, status), how) ->
            Verdicts.Crashed { signal; status; how })
          (Gen.pair (Gen.pair int int) name);
        Gen.map (fun mb -> Verdicts.Memory { mb }) Gen.nat;
        Gen.map
          (fun (test, failure) -> Verdicts.Flaky_kill { test; failure })
          (Gen.pair path name);
        Gen.map (fun r -> Verdicts.Other r) name;
      ]
  in
  let verdict =
    Gen.one_of
      [
        Gen.of_list Verdicts.[ Not_evaluated; Outside_tests; Unreached ];
        Gen.map Verdicts.killed (Gen.list ~size:(Gen.int_range 0 3) path);
        Gen.map (fun e -> Verdicts.Killed_elsewhere { exe = "e" ^ e }) name;
        Gen.map (fun r -> Verdicts.Unknown r) reason;
        Gen.map Verdicts.survived (Gen.list ~size:(Gen.int_range 1 3) path);
      ]
  in
  let digest = Gen.option hex_digest in
  (* Only a kill that names a test has a prefix, and only such a kill or a
     survivor has the mark, as load demands. *)
  let reusable = function
    | Verdicts.Killed { by = _ :: _ } | Survived _ -> true
    | _ -> false
  in
  let killer = function
    | Verdicts.Killed { by = _ :: _ } -> true
    | _ -> false
  in
  Gen.map
    (fun ( ( (file, line, col, rewrite),
             (lines, stop),
             (before, after, source_digest),
             verdict ),
           (previous, (retries, pass, settings), prefix, reused) ) ->
      let end_ = (line + lines, if lines = 0 then col + stop else stop) in
      let effort =
        {
          Verdicts.retries;
          pass = 1 + (pass mod (retries + 1));
          settings = Option.value settings ~default:zeros;
        }
      in
      record ~before ~after ~end_ ?source_digest ?previous ~effort
        ?prefix:(if killer verdict then prefix else None)
        ~reused:(reused && reusable verdict)
        (id file line col rewrite) verdict)
    (Gen.pair
       (Gen.quad
          (Gen.quad
             (Gen.map (fun s -> "f" ^ s) name)
             (Gen.map succ Gen.nat) Gen.nat
             (Gen.of_list Mutate.rewrites))
          (Gen.pair Gen.nat Gen.nat)
          (Gen.triple name name digest)
          verdict)
       (Gen.quad any_previous
          (Gen.triple (Gen.int_range 0 100) Gen.nat digest)
          digest Gen.bool))

let any_identity =
  Gen.option
    (Gen.with_pp pp_identity
       (Gen.map
          (fun (exe, digest) -> { Verdicts.exe = "e" ^ exe; digest })
          (Gen.pair Gen.string hex_digest)))

(* Test digests with distinct tests, in any order. *)
let any_test_digests =
  Gen.map
    (fun entries ->
      List.sort_uniq
        (fun (a, _) (b, _) -> List.compare String.compare a b)
        entries
      |> List.rev)
    (Gen.list ~size:(Gen.int_range 0 3)
       (Gen.pair (Gen.list ~size:(Gen.int_range 0 2) Gen.string) hex_digest))

let any_file =
  Gen.quad any_identity (Gen.option Gen.string)
    (Gen.with_pp pp_records
       (Gen.map collection (Gen.list ~size:(Gen.int_range 0 5) any_record)))
    any_test_digests

(* Verdicts *)

let rank = function
  | Verdicts.Killed _ -> 6
  | Killed_elsewhere _ -> 5
  | Unknown _ -> 4
  | Not_evaluated -> 3
  | Survived _ -> 2
  | Outside_tests -> 1
  | Unreached -> 0

(* The verdict of a mutant that one executable saw as [a] and another as [b],
   as add states it. *)
let join a b =
  match (a, b) with
  | Verdicts.Survived x, Verdicts.Survived y ->
      Verdicts.survived ((x.first :: x.others) @ (y.first :: y.others))
  | Verdicts.Killed x, Verdicts.Killed y -> Verdicts.killed (x.by @ y.by)
  | Verdicts.Unknown x, Verdicts.Unknown y ->
      let key r = (Verdicts.reason_text r, r) in
      Verdicts.Unknown (snd (min (key x) (key y)))
  | Verdicts.Killed_elsewhere x, Verdicts.Killed_elsewhere y ->
      Verdicts.Killed_elsewhere { exe = min x.exe y.exe }
  | _ -> if rank a >= rank b then a else b

let combined (a, b) =
  let m = id "lib/lattice.ml" 1 0 "add" in
  let t = collection [ record m a; record m b ] in
  equal verdict (join a b)
    (require_match
       (function [ r ] -> Some r.Verdicts.verdict | _ -> None)
       (Verdicts.records t))

let reaching = function
  | Verdicts.Survived { first; others } -> Some (first :: others)
  | _ -> None

let sorted_names ts =
  equal
    (list (list string))
    (List.sort_uniq compare ts)
    (require_match ~pp:pp_verdict reaching (Verdicts.survived ts))

let lattice_examples =
  let s = Verdicts.survived in
  let e exe = Verdicts.Killed_elsewhere { exe } in
  Verdicts.
    [
      (killed [], e "x");
      (e "x", Unknown (Other "crashed"));
      (e "x", Not_evaluated);
      (e "y", e "x");
      (s [ [ "a" ] ], e "x");
      (Unreached, e "x");
      (killed [ [ "a" ] ], s [ [ "a" ] ]);
      (Unreached, killed [ [ "a" ] ]);
      (Unknown (Other "crashed"), killed []);
      (killed [ [ "b" ]; [ "a" ] ], killed [ [ "c" ]; [ "b" ] ]);
      (killed [], killed [ [ "a" ] ]);
      (killed [ [ "a" ] ], killed [ [ "a" ] ]);
      ( Unknown (Crashed { signal = Some (-10); status = None; how = "x" }),
        Unknown (Other "its run x") );
      ( Unknown (Crashed { signal = None; status = Some 1; how = "x" }),
        Unknown (Crashed { signal = Some (-10); status = None; how = "x" }) );
      (Unknown (Deadline { seconds = 2. }), Unknown (Memory { mb = 8 }));
      (Unknown (Other "crashed"), s [ [ "a" ] ]);
      (Unknown (Other "crashed"), Not_evaluated);
      (Unknown (Other "refused"), Unknown (Other "crashed"));
      (Not_evaluated, s [ [ "a" ] ]);
      (Outside_tests, s [ [ "a" ] ]);
      (Not_evaluated, Outside_tests);
      (Unreached, Outside_tests);
      (s [ [ "b" ]; [ "a" ] ], s [ [ "c" ]; [ "b" ] ]);
    ]

let outcome_cases =
  [
    ("Killed", Verdicts.killed [ [ "t" ] ], Some "killed");
    ( "Killed_elsewhere",
      Verdicts.Killed_elsewhere { exe = "default/test/a.exe" },
      None );
    ("Unknown", Verdicts.Unknown (Other "crashed"), None);
    ("Survived", Verdicts.survived [ [ "t" ] ], Some "survived");
    ("Not_evaluated", Verdicts.Not_evaluated, Some "not evaluated");
    ("Outside_tests", Verdicts.Outside_tests, None);
    ("Unreached", Verdicts.Unreached, None);
  ]

let outcome (_, verdict, expected) =
  equal (option string) expected
    (Option.map outcome_row (Verdicts.outcome verdict))

let verdicts =
  group "Verdicts"
    [
      cases "outcome is the verdict that the tests of a suite give"
        ~id:(fun (name, _, _) -> name)
        outcome_cases outcome;
      prop "survived sorts its reaching tests and drops duplicates"
        ~examples:[ [ [ "b" ]; [ "a" ]; [ "b" ] ] ]
        (Gen.list ~size:(Gen.int_range 1 4)
           (Gen.list ~size:(Gen.int_range 0 2) (Gen.of_list [ "a"; "b"; "" ])))
        sorted_names;
      test "survived raises Invalid_argument on no reaching test" (fun () ->
          raises
            (Invalid_argument
               "Windtrap_runtime.Verdicts.survived: a survivor names at least \
                one test") (fun () -> Verdicts.survived []));
    ]

(* Collections *)

let record_of_mutant () =
  let m =
    {
      Mutate.id = id "lib/calc.ml" 4 2 "sub";
      end_line = 4;
      end_col = 7;
      before = "a - b";
      after = "a + b";
      dismissed = Some "equivalent";
      source_digest = Some (String.make 32 'a');
    }
  in
  let effort = { Verdicts.retries = 2; pass = 3; settings = zeros } in
  equal string
    {|"lib/calc.ml":4:2:sub (to 4:7) "a - b" -> "a + b" of aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa: killed (retries 2, pass 3, settings "00000000000000000000000000000000")|}
    (record_row (Verdicts.record_of_mutant ~effort m (Verdicts.killed [])));
  equal string {|"lib/calc.ml":4:2:sub (to 4:7) "a - b" -> "a + b": killed|}
    (record_row
       (Verdicts.record_of_mutant ~effort:base_effort
          { m with source_digest = None }
          (Verdicts.killed [])));
  equal string
    (strf
       {|"lib/calc.ml":4:2:sub (to 4:7) "a - b" -> "a + b": killed by ["t"] prefix %s|}
       (Verdicts.prefix_digest [ [ "s" ]; [ "t" ] ]))
    (record_row
       (Verdicts.record_of_mutant ~effort:base_effort
          ~prefix:[ [ "s" ]; [ "t" ] ]
          { m with source_digest = None }
          (Verdicts.killed [ [ "t" ] ])));
  (* Only a kill that names a test keeps its prefix in a collection. *)
  List.iter
    (fun (verdict, row) ->
      let r =
        Verdicts.record_of_mutant ~effort:base_effort ~prefix:[ [ "t" ] ]
          { m with source_digest = None }
          verdict
      in
      equal string
        (strf
           {|"lib/calc.ml":4:2:sub (to 4:7) "a - b" -> "a + b": %s prefix %s|}
           row
           (Verdicts.prefix_digest [ [ "t" ] ]))
        (record_row r);
      equal (list string)
        [ {|"lib/calc.ml":4:2:sub (to 4:7) "a - b" -> "a + b": |} ^ row ]
        (rows (collection [ r ])))
    [
      (Verdicts.killed [], "killed");
      (Verdicts.survived [ [ "t" ] ], {|survived by ["t"]|});
    ]

let prefix_digests () =
  let digests =
    List.map Verdicts.prefix_digest
      [
        [];
        [ [] ];
        [ [ "a" ] ];
        [ [ "a"; "b" ] ];
        [ [ "a" ]; [ "b" ] ];
        [ [ "b" ]; [ "a" ] ];
        [ [ "a b" ] ];
        [ [ "a" ]; [] ];
      ]
  in
  List.iter (fun d -> is_true (Instr.is_digest d)) digests;
  equal int (List.length digests)
    (List.length (List.sort_uniq String.compare digests))

(* The previous outcomes of two records combine as their verdicts do, and a
   missing one leaves the other unchanged. *)
let join_previous a b =
  let verdict = function
    | `Killed -> Verdicts.killed []
    | `Survived -> Verdicts.survived [ [ "t" ] ]
    | `Not_evaluated -> Verdicts.Not_evaluated
  in
  match (a, b) with
  | None, p | p, None -> p
  | Some x, Some y -> Verdicts.outcome (join (verdict x) (verdict y))

(* Two records of one mutant keep the smaller rendering, and the verdict and
   the previous outcome both combine into, in either order. *)
let kept_rendering (a, b) =
  let key (r : Verdicts.record) =
    (r.before, r.after, r.end_line, r.end_col, r.source_digest)
  in
  let bare (r : Verdicts.record) =
    match r.verdict with
    | Verdicts.Killed { by = _ :: _ } -> r
    | _ -> { r with prefix = None }
  in
  let a = bare { a with Verdicts.id = b.Verdicts.id } and b = bare b in
  let smaller = if compare (key a) (key b) <= 0 then a else b in
  let top =
    List.filter
      (fun (r : Verdicts.record) ->
        rank r.verdict = max (rank a.verdict) (rank b.verdict))
      [ a; b ]
  in
  let effort, prefix =
    List.hd
      (List.sort compare
         (List.map (fun (r : Verdicts.record) -> (r.effort, r.prefix)) top))
  in
  let expected =
    [
      {
        smaller with
        verdict = join a.verdict b.verdict;
        previous = join_previous a.previous b.previous;
        effort;
        prefix;
        reused = List.for_all (fun (r : Verdicts.record) -> r.reused) top;
      };
    ]
  in
  equal records (collection expected) (collection [ a; b ]);
  equal records (collection expected) (collection [ b; a ])

let ordered added =
  let ids records =
    List.map (fun (r : Verdicts.record) -> Mutate.id_to_string r.id) records
  in
  equal (list string)
    (ids
       (List.sort_uniq
          (fun (a : Verdicts.record) b -> Mutate.compare_id a.id b.id)
          added))
    (ids (Verdicts.records (collection added)))

let changed_cases =
  let s = Verdicts.survived [ [ "t" ] ] in
  [
    ("no previous outcome", None, Verdicts.killed [], None);
    ( "survived to killed",
      Some `Survived,
      Verdicts.killed [],
      Some "survived, killed" );
    ("killed to survived", Some `Killed, s, Some "killed, survived");
    ( "not evaluated to killed",
      Some `Not_evaluated,
      Verdicts.killed [],
      Some "not evaluated, killed" );
    ( "survived to not evaluated",
      Some `Survived,
      Verdicts.Not_evaluated,
      Some "survived, not evaluated" );
    ("killed to killed", Some `Killed, Verdicts.killed [], None);
    ( "survived to other reaching tests",
      Some `Survived,
      Verdicts.survived [ [ "a" ]; [ "b" ] ],
      None );
    ( "survived to killed elsewhere",
      Some `Survived,
      Verdicts.Killed_elsewhere { exe = "x" },
      None );
    ("killed to unknown", Some `Killed, Verdicts.Unknown (Other "crashed"), None);
    ("survived to unreached", Some `Survived, Verdicts.Unreached, None);
    ("killed to outside tests", Some `Killed, Verdicts.Outside_tests, None);
  ]

let changed (_, previous, verdict, expected) =
  let r = record ?previous (id "lib/a.ml" 1 0 "lt") verdict in
  equal (option string) expected
    (Option.map
       (fun (was, is) -> outcome_row was ^ ", " ^ outcome_row is)
       (Verdicts.changed r))

(* A reused verdict is no change, because this run did not test the
   mutant. *)
let changed_reused () =
  List.iter
    (fun (previous, verdict) ->
      is_none
        (Verdicts.changed
           (record ~previous ~reused:true (id "lib/a.ml" 1 0 "lt") verdict)))
    [
      (`Survived, Verdicts.killed [ [ "t" ] ]);
      (`Killed, Verdicts.survived [ [ "t" ] ]);
    ]

(* The mark and the effort of two records of one mutant. *)
let combined_record a b =
  require_match
    (function [ r ] -> Some r | _ -> None)
    (Verdicts.records (collection [ a; b ]))

let marks () =
  let m = id "lib/a.ml" 1 0 "lt" in
  let kill ?reused ?effort test =
    record ?reused ?effort m (Verdicts.killed [ [ test ] ])
  in
  let low = { base_effort with retries = 1; pass = 2 } in
  let high = { base_effort with retries = 3 } in
  let row a b = record_row (combined_record a b) in
  equal string {|"lib/a.ml":1:0:lt (to 1:1) "b" -> "a": killed by ["s"], ["t"]|}
    (row (kill ~reused:true "s") (kill "t"));
  equal string
    {|"lib/a.ml":1:0:lt (to 1:1) "b" -> "a": killed by ["s"], ["t"] reused|}
    (row (kill ~reused:true "s") (kill ~reused:true "t"));
  equal string {|"lib/a.ml":1:0:lt (to 1:1) "b" -> "a": killed by ["t"]|}
    (row (record ~reused:true m (Verdicts.survived [ [ "s" ] ])) (kill "t"));
  equal string
    {|"lib/a.ml":1:0:lt (to 1:1) "b" -> "a": killed by ["s"], ["t"] (retries 1, pass 2, settings "00000000000000000000000000000000")|}
    (row (kill ~effort:high "s") (kill ~effort:low "t"));
  equal string
    {|"lib/a.ml":1:0:lt (to 1:1) "b" -> "a": killed by ["t"] (retries 3, pass 1, settings "00000000000000000000000000000000")|}
    (row
       (record ~effort:low m (Verdicts.survived [ [ "s" ] ]))
       (kill ~effort:high "t"))

let source = String.make 32 'a'

(* The collection that [with_previous] reads: one record of [m]. *)
let prior ?(source_digest = Some source) ?(before = "b") ?previous verdict =
  collection
    [ record ?source_digest ~before ?previous (id "lib/a.ml" 1 0 "lt") verdict ]

let with_previous_cases =
  let m = id "lib/a.ml" 1 0 "lt" in
  let s = Verdicts.survived [ [ "t" ] ] in
  let other = String.make 32 'b' in
  let r = record ~source_digest:source m (Verdicts.killed []) in
  [
    ("the same mutant", prior ~previous:`Killed s, r, Some "survived");
    ( "another digest",
      prior s,
      record ~source_digest:other m (Verdicts.killed []),
      None );
    ("no digest in the collection", prior s, record m (Verdicts.killed []), None);
    ("no digest in the prior", prior ~source_digest:None s, r, None);
    ("another rendering", prior ~before:"c" s, r, None);
    ( "another end",
      prior s,
      record ~source_digest:source ~end_:(2, 0) m (Verdicts.killed []),
      None );
    ( "another identifier",
      prior s,
      record ~source_digest:source (id "lib/b.ml" 1 0 "lt") (Verdicts.killed []),
      None );
    ( "a previous outcome of its own and no prior record",
      Verdicts.empty,
      record ~source_digest:source ~previous:`Survived m (Verdicts.killed []),
      None );
    ( "a prior skip keeps the outcome before it",
      prior ~previous:`Survived (Verdicts.Killed_elsewhere { exe = "x" }),
      r,
      Some "survived" );
    ( "a prior skip with no outcome before it",
      prior (Verdicts.Killed_elsewhere { exe = "x" }),
      r,
      None );
    ( "a prior unknown verdict keeps the outcome before it",
      prior ~previous:`Not_evaluated (Verdicts.Unknown (Other "crashed")),
      r,
      Some "not evaluated" );
    ( "a prior unreached mutant keeps the outcome before it",
      prior ~previous:`Survived Verdicts.Unreached,
      r,
      Some "survived" );
  ]

let with_previous (_, prior, r, expected) =
  equal
    (list (option string))
    [ expected ]
    (List.map
       (fun (r : Verdicts.record) -> Option.map outcome_row r.previous)
       (Verdicts.records (Verdicts.with_previous ~prior (collection [ r ]))))

(* The oracle: a record takes the outcome of the prior record of the same
   mutant, or the previous outcome of that record when its verdict is no
   outcome. *)
let with_previous_oracle (prior, t) =
  let expected (r : Verdicts.record) =
    let previous =
      List.find_map
        (fun (p : Verdicts.record) ->
          if
            Mutate.compare_id p.id r.id = 0
            && r.source_digest <> None
            && p.source_digest = r.source_digest
            && (p.before, p.after, p.end_line, p.end_col)
               = (r.before, r.after, r.end_line, r.end_col)
          then
            Some
              (match Verdicts.outcome p.verdict with
              | Some o -> Some o
              | None -> p.previous)
          else None)
        (Verdicts.records prior)
    in
    record_row { r with previous = Option.join previous }
  in
  equal (list string)
    (List.map expected (Verdicts.records t))
    (rows (Verdicts.with_previous ~prior t))

let with_previous_keeps_the_rest (prior, t) =
  let bare t =
    List.map
      (fun (r : Verdicts.record) -> record_row { r with previous = None })
      (Verdicts.records t)
  in
  equal (list string) (bare t) (bare (Verdicts.with_previous ~prior t))

let commutes (a, b) = equal records (Verdicts.merge a b) (Verdicts.merge b a)

let associates (a, b, c) =
  equal records
    (Verdicts.merge (Verdicts.merge a b) c)
    (Verdicts.merge a (Verdicts.merge b c))

let idempotent a = equal records a (Verdicts.merge a a)

let empty_is_unit a =
  equal records a (Verdicts.merge a Verdicts.empty);
  equal records a (Verdicts.merge Verdicts.empty a)

let merge_is_add (a, b) =
  equal records
    (List.fold_left Verdicts.add a (Verdicts.records b))
    (Verdicts.merge a b)

let unreached_is_neutral a =
  let unreached =
    collection
      (List.map
         (fun (r : Verdicts.record) -> { r with verdict = Verdicts.Unreached })
         (Verdicts.records a))
  in
  equal records a (Verdicts.merge a unreached)

let unchecked_ids =
  [
    ("an empty file", id "" 1 0 "lt");
    ("line 0", id "a.ml" 0 0 "lt");
    ("a negative column", id "a.ml" 1 (-1) "lt");
    ("an unknown rewrite", id "a.ml" 1 0 "plus");
  ]

let unchecked (_, bad) =
  let t = Verdicts.add Verdicts.empty (record bad Verdicts.Unreached) in
  let path = Filename.concat (temp_dir ()) "bad.mutants" in
  Verdicts.save path t;
  equal (list string)
    [ Mutate.id_to_string bad ]
    (List.map
       (fun (r : Verdicts.record) -> Mutate.id_to_string r.id)
       (Verdicts.records t));
  equal string path (require_match corrupt_path (Verdicts.load path))

let unchecked_records =
  [
    ( "an empty killing executable",
      record (id "a.ml" 1 0 "lt") (Verdicts.Killed_elsewhere { exe = "" }) );
    ( "a short source digest",
      record ~source_digest:"abc" (id "a.ml" 1 0 "lt") Verdicts.Unreached );
    ( "an uppercase source digest",
      record ~source_digest:(String.make 32 'A') (id "a.ml" 1 0 "lt")
        Verdicts.Unreached );
  ]

let unchecked_record (_, bad) =
  let t = Verdicts.add Verdicts.empty bad in
  let path = Filename.concat (temp_dir ()) "bad.mutants" in
  Verdicts.save path t;
  equal (list string) [ record_row bad ] (rows t);
  equal string path (require_match corrupt_path (Verdicts.load path))

let collections =
  group "Collections"
    [
      test
        "record_of_mutant keeps the identifier, the renderings, the source \
         digest, the effort and the prefix of a kill that names a test, not \
         the dismissal, and gives no mark"
        record_of_mutant;
      test "empty holds no record" (fun () ->
          equal (list string) [] (rows Verdicts.empty));
      prop
        "add combines two verdicts by Killed > Killed_elsewhere > Unknown > \
         Not_evaluated > Survived > Outside_tests > Unreached, keeps the \
         smaller killing executable, and unites the reaching tests"
        ~examples:lattice_examples
        (Gen.pair small_verdict small_verdict)
        combined;
      prop
        "add keeps the smaller (before, after, end, source digest) of two \
         records of a mutant"
        (Gen.pair small_record small_record)
        kept_rendering;
      test "add sorts a survivor's reaching tests and drops duplicates"
        (fun () ->
          let unsorted =
            Verdicts.Survived { first = [ "b" ]; others = [ [ "a" ]; [ "b" ] ] }
          in
          equal (list string)
            [
              {|"lib/a.ml":1:0:lt (to 1:1) "b" -> "a": survived by ["a"], ["b"]|};
            ]
            (rows (collection [ record (id "lib/a.ml" 1 0 "lt") unsorted ])));
      cases "changed is the change between a previous outcome and a verdict"
        ~id:(fun (name, _, _, _) -> name)
        changed_cases changed;
      test "changed is None for a reused verdict" changed_reused;
      test "prefix_digest gives each list of tests its own digest"
        prefix_digests;
      test
        "add keeps the mark when each record of the higher rank has it, and \
         the smaller effort of these records"
        marks;
      cases
        "with_previous takes the outcome of the same mutant, with the same \
         source digest that is not None"
        ~id:(fun (name, _, _, _) -> name)
        with_previous_cases with_previous;
      prop "with_previous sets the previous outcome by the rule of the mutant"
        (Gen.pair small_collection small_collection)
        with_previous_oracle;
      prop "with_previous changes no identifier, rendering, digest or verdict"
        (Gen.pair small_collection small_collection)
        with_previous_keeps_the_rest;
      prop "records are in identifier order, one for each identifier"
        (Gen.list ~size:(Gen.int_range 0 6) small_record)
        ordered;
      prop "merge is commutative"
        (Gen.pair small_collection small_collection)
        commutes;
      prop "merge is associative"
        (Gen.triple small_collection small_collection small_collection)
        associates;
      prop "merge is idempotent" small_collection idempotent;
      prop "empty is the unit of merge" small_collection empty_is_unit;
      prop "merge combines two records of a mutant as add does"
        (Gen.pair small_collection small_collection)
        merge_is_add;
      prop "an Unreached verdict leaves the verdict it is merged with unchanged"
        small_collection unreached_is_neutral;
      cases "add checks no identifier, and load refuses the file save writes"
        ~id:fst unchecked_ids unchecked;
      cases
        "add checks no killing executable and no source digest, and load \
         refuses the file save writes"
        ~id:fst unchecked_records unchecked_record;
    ]

(* Reuse *)

let effort ?(pass = 1) ?(settings = zeros) retries =
  { Verdicts.retries; pass; settings }

let covers_cases =
  let other = String.make 32 'f' in
  [
    ("a kill, judged 0, asked 0", `Killed, effort 0, effort 0, true);
    ("a kill, judged 0, asked 1", `Killed, effort 0, effort 1, false);
    ("a kill, judged 1, asked 0", `Killed, effort 1, effort 0, true);
    ("a kill, judged 1, asked 1", `Killed, effort 1, effort 1, true);
    ("a kill, judged 2, asked 1", `Killed, effort 2, effort 1, true);
    ( "a kill, other settings",
      `Killed,
      effort 0,
      effort ~settings:other 0,
      false );
    ("a kill of pass 2, asked 0", `Killed, effort ~pass:2 1, effort 0, false);
    ("a kill of pass 2, asked 1", `Killed, effort ~pass:2 1, effort 1, true);
    ("a kill of pass 3, asked 1", `Killed, effort ~pass:3 2, effort 1, false);
    ("a survivor, judged 0, asked 0", `Survived, effort 0, effort 0, true);
    ("a survivor, judged 0, asked 1", `Survived, effort 0, effort 1, false);
    ("a survivor, judged 1, asked 0", `Survived, effort 1, effort 0, true);
    ("a survivor, judged 1, asked 1", `Survived, effort 1, effort 1, true);
    ("a survivor, judged 2, asked 1", `Survived, effort 2, effort 1, true);
    ( "a survivor, other settings",
      `Survived,
      effort 0,
      effort ~settings:other 0,
      false );
  ]

let covers (_, kind, judged, asked, expected) =
  equal bool expected (Verdicts.effort_covers kind ~judged ~asked)

let src = String.make 32 'c'
let at_mutant = id "lib/a.ml" 1 0 "lt"

(* The mutant of [at_mutant], as [record] draws it. *)
let mutant ?(source_digest = Some src) ?(before = "b") ?(after = "a")
    ?(end_ = (1, 1)) () =
  {
    Mutate.id = at_mutant;
    end_line = fst end_;
    end_col = snd end_;
    before;
    after;
    dismissed = None;
    source_digest;
  }

let t1 = [ "g"; "t1" ]
let t2 = [ "g"; "t2" ]
let t3 = [ "g"; "t3" ]
let digest_of test = String.make 32 (String.get (List.nth test 1) 1)
let digests = List.map (fun t -> (t, digest_of t)) [ t1; t2; t3 ]

let last ?refused ?(test_digests = digests) records =
  {
    Verdicts.verdicts = collection records;
    identity = None;
    suite = Some "s";
    refused;
    test_digests;
  }

let kill ?(effort = effort 0) ?(source_digest = Some src) ?reused ~prefix by =
  record ?source_digest ~effort
    ~prefix:(Verdicts.prefix_digest prefix)
    ?reused at_mutant (Verdicts.killed by)

let survivor ?(effort = effort 0) ?(source_digest = Some src) ?reused tests =
  record ?source_digest ~effort ?reused at_mutant (Verdicts.survived tests)

let plain verdict = record ~source_digest:src at_mutant verdict

(* This run's digests: those of [digests], with [changes] applied. *)
let now ?(changes = []) test =
  match List.assoc_opt test changes with
  | Some changed -> changed
  | None -> List.assoc_opt test digests

let other_digest = Some (String.make 32 'e')

(* A case gives the last file, the digests and the effort of this run, the
   reaching tests and the mutant, and whether the last record is reused. *)
let reuse_cases =
  let k = kill ~prefix:[ t1 ] [ t1 ] in
  let s = survivor [ t1; t2 ] in
  let case ?(digest = fun t -> now t) ?(asked = effort 0) ?(m = mutant ()) name
      file reaching expected =
    (name, (file, digest, asked, reaching, m, expected))
  in
  let unknown r = plain (Verdicts.Unknown r) in
  [
    case "a kill by its first test" (last [ k ]) [ t1; t2 ] (Some k);
    case "a kill that names no test"
      (last [ plain (Verdicts.killed []) ])
      [ t1 ] None;
    case "a kill whose test does not reach now" (last [ k ]) [ t2 ] None;
    case "a kill whose test has another digest now"
      ~digest:(now ~changes:[ (t1, other_digest) ])
      (last [ k ]) [ t1; t2 ] None;
    case "a kill whose test has no digest now"
      ~digest:(now ~changes:[ (t1, None) ])
      (last [ k ]) [ t1; t2 ] None;
    case "a kill whose test has no entry in the last file"
      (last ~test_digests:(List.tl digests) [ k ])
      [ t1; t2 ] None;
    case "a kill whose job order changed"
      (last [ kill ~prefix:[ t1 ] [ t2 ] ])
      [ t1; t2 ] None;
    case "a kill whose earlier test in the job has another digest"
      ~digest:(now ~changes:[ (t1, other_digest) ])
      (last [ kill ~prefix:[ t1; t2 ] [ t2 ] ])
      [ t1; t2 ] None;
    case "a kill whose later test in the job has another digest"
      ~digest:(now ~changes:[ (t2, other_digest) ])
      (last [ k ]) [ t1; t2 ] (Some k);
    case "a kill by two tests"
      (last [ kill ~prefix:[ t1; t2; t3 ] [ t3; t1 ] ])
      [ t1; t2; t3 ] None;
    case "a kill whose earlier test in the job does not reach now"
      (last [ kill ~prefix:[ t1; t2 ] [ t2 ] ])
      [ t2; t3 ] None;
    case "a kill judged 0, asked 1" ~asked:(effort 1) (last [ k ]) [ t1 ] None;
    case "a kill judged 2, asked 1" ~asked:(effort 1)
      (last [ kill ~effort:(effort 2) ~prefix:[ t1 ] [ t1 ] ])
      [ t1 ]
      (Some (kill ~effort:(effort 2) ~prefix:[ t1 ] [ t1 ]));
    case "a kill judged 0, asked 0" (last [ k ]) [ t1 ] (Some k);
    case "a kill of pass 2, asked 0"
      (last [ kill ~effort:(effort ~pass:2 1) ~prefix:[ t1 ] [ t1 ] ])
      [ t1 ] None;
    case "a kill of pass 2, asked 1" ~asked:(effort 1)
      (last [ kill ~effort:(effort ~pass:2 1) ~prefix:[ t1 ] [ t1 ] ])
      [ t1 ]
      (Some (kill ~effort:(effort ~pass:2 1) ~prefix:[ t1 ] [ t1 ]));
    case "a survivor with the same tests, judged 0, asked 0" (last [ s ])
      [ t1; t2 ] (Some s);
    case "a survivor with the same tests, judged 2, asked 1" ~asked:(effort 1)
      (last [ survivor ~effort:(effort 2) [ t1; t2 ] ])
      [ t1; t2 ]
      (Some (survivor ~effort:(effort 2) [ t1; t2 ]));
    case "a survivor judged 0, asked 1" ~asked:(effort 1) (last [ s ])
      [ t1; t2 ] None;
    case "a survivor with one more test now" (last [ s ]) [ t1; t2; t3 ] None;
    case "a survivor with one test less now" (last [ s ]) [ t1 ] None;
    case "a survivor with its tests in another order and a duplicate"
      (last [ s ]) [ t2; t1; t2 ] (Some s);
    case "a survivor whose test has another digest now"
      ~digest:(now ~changes:[ (t2, other_digest) ])
      (last [ s ]) [ t1; t2 ] None;
    case "a survivor whose test has no digest now"
      ~digest:(now ~changes:[ (t2, None) ])
      (last [ s ]) [ t1; t2 ] None;
    case "a kill of other settings"
      ~asked:(effort ~settings:(String.make 32 'f') 0)
      (last [ k ]) [ t1 ] None;
    case "a survivor of other settings"
      ~asked:(effort ~settings:(String.make 32 'f') 0)
      (last [ s ]) [ t1; t2 ] None;
    case "a mutant that was not evaluated"
      (last [ plain Verdicts.Not_evaluated ])
      [ t1 ] None;
    case "an unknown verdict of a deadline"
      (last [ unknown (Deadline { seconds = 1. }) ])
      [ t1 ] None;
    case "an unknown verdict of a crash"
      (last [ unknown (Crashed { signal = None; status = None; how = "x" }) ])
      [ t1 ] None;
    case "an unknown verdict of a memory limit"
      (last [ unknown (Memory { mb = 1 }) ])
      [ t1 ] None;
    case "an unknown verdict of a flaky kill"
      (last [ unknown (Flaky_kill { test = t1; failure = "x" }) ])
      [ t1 ] None;
    case "an unknown verdict of another reason"
      (last [ unknown (Other "x") ])
      [ t1 ] None;
    case "a mutant killed elsewhere"
      (last [ plain (Verdicts.Killed_elsewhere { exe = "x" }) ])
      [ t1 ] None;
    case "a mutant evaluated outside tests"
      (last [ plain Verdicts.Outside_tests ])
      [ t1 ] None;
    case "an unreached mutant" (last [ plain Verdicts.Unreached ]) [ t1 ] None;
    case "another source digest"
      (last
         [
           kill ~source_digest:(Some (String.make 32 'd')) ~prefix:[ t1 ] [ t1 ];
         ])
      [ t1 ] None;
    case "a mutant with no source digest"
      ~m:(mutant ~source_digest:None ())
      (last [ kill ~source_digest:None ~prefix:[ t1 ] [ t1 ] ])
      [ t1 ] None;
    case "a record with no source digest"
      (last [ kill ~source_digest:None ~prefix:[ t1 ] [ t1 ] ])
      [ t1 ] None;
    case "another before" ~m:(mutant ~before:"c" ()) (last [ k ]) [ t1 ] None;
    case "another after" ~m:(mutant ~after:"c" ()) (last [ k ]) [ t1 ] None;
    case "another end" ~m:(mutant ~end_:(1, 2) ()) (last [ k ]) [ t1 ] None;
    case "no record of the identifier" (last []) [ t1 ] None;
    case "a refused last file" (last ~refused:"x" [ k ]) [ t1 ] None;
    case "a reused kill is reused again"
      (last [ kill ~effort:(effort 3) ~reused:true ~prefix:[ t1 ] [ t1 ] ])
      [ t1 ]
      (Some (kill ~effort:(effort 3) ~prefix:[ t1 ] [ t1 ]));
  ]

let reused (_, (file, digest, asked, reaching, m, expected)) =
  equal (option string)
    (Option.map
       (fun (p : Verdicts.record) ->
         record_row { p with previous = None; reused = true })
       expected)
    (Option.map record_row
       (Verdicts.reuse ~last:file
          ~recorded:(Verdicts.lookup file.test_digests)
          ~digest ~effort:asked ~reaching m))

let reuse =
  group "Reuse"
    [
      cases "effort_covers compares the retries and the settings"
        ~id:(fun (n, _, _, _, _) -> n)
        covers_cases covers;
      cases "reuse gives the last verdict only when its evidence did not change"
        ~id:fst reuse_cases reused;
      test "lookup finds each test of the list" (fun () ->
          let recorded = Verdicts.lookup digests in
          equal
            (list (option string))
            (List.map (fun t -> Some (digest_of t)) [ t1; t2; t3 ] @ [ None ])
            (List.map recorded [ t1; t2; t3; [ "g" ] ]));
      test "through ends at the first test, or keeps each path" (fun () ->
          equal
            (list (list (list string)))
            [ [ t1 ]; [ t1; t2 ]; [ t1; t2; t3 ]; [] ]
            [
              Verdicts.through t1 [ t1; t2; t1 ];
              Verdicts.through t2 [ t1; t2; t3 ];
              Verdicts.through [ "g" ] [ t1; t2; t3 ];
              Verdicts.through t1 [];
            ]);
    ]

(* Verdict files *)

let sample =
  collection
    [
      record ~before:"a - b" ~after:"a + b" (id "lib/a.ml" 1 2 "add")
        Verdicts.Unreached;
      record ~before:"p && q" ~after:"not (p && q)" ~previous:`Not_evaluated
        (id "lib/b.ml" 3 4 "not") (Verdicts.killed []);
      record ~before:"a || b" ~after:"a && b" ~previous:`Killed
        (id "lib/b.ml" 5 0 "or")
        (Verdicts.survived [ [ "y"; "z" ]; [ "x" ] ]);
      record ~before:"a + b" ~after:"a - b" (id "lib/c.ml" 7 1 "sub")
        Verdicts.Not_evaluated;
      record ~before:"a - b" ~after:"a + b" (id "lib/c.ml" 9 0 "add")
        Verdicts.Outside_tests;
      record ~before:"a < b" ~after:"a <= b" (id "lib/c.ml" 11 3 "le")
        (Verdicts.Unknown (Other "its run was killed by SIGSEGV"));
      record ~before:"a - b" ~after:"a + b" ~source_digest:(String.make 32 'c')
        (id "lib/d.ml" 1 0 "add")
        (Verdicts.Killed_elsewhere { exe = "default/test/a.exe" });
    ]

let digest = String.make 32 'a'

let kills_and_reasons =
  let at line verdict =
    record ~before:"a - b" ~after:"a + b" (id "lib/k.ml" line 0 "add") verdict
  in
  collection
    Verdicts.
      [
        at 1 (killed []);
        at 2 (killed [ [ "calc"; "adds" ] ]);
        at 3 (killed [ [ "calc"; "subs" ]; [ "adds" ]; [ "calc"; "adds" ] ]);
        at 4 (Unknown (Deadline { seconds = 2.5 }));
        at 5 (Unknown (Deadline { seconds = 0.1 }));
        at 6
          (Unknown
             (Crashed
                {
                  signal = Some Sys.sigsegv;
                  status = None;
                  how = "was killed by SIGSEGV";
                }));
        at 7
          (Unknown
             (Crashed
                {
                  signal = None;
                  status = Some 3;
                  how = "ended when code under test called exit";
                }));
        at 8 (Unknown (Crashed { signal = None; status = None; how = "ended" }));
        at 9 (Unknown (Memory { mb = 512 }));
        at 10
          (Unknown
             (Flaky_kill
                {
                  test = [ "calc"; "adds" ];
                  failure = "its killing test calc adds also fails";
                }));
        at 11 (Unknown (Other "the suite is not deterministic"));
      ]

let reason_texts =
  List.filter_map
    (fun (r : Verdicts.record) ->
      match r.verdict with
      | Verdicts.Unknown reason -> Some (Verdicts.reason_text reason)
      | _ -> None)
    (Verdicts.records kills_and_reasons)

let round_trip (identity, suite, t, test_digests) =
  let path = Filename.concat (temp_dir ()) "saved.mutants" in
  Verdicts.save ?identity ?suite ~test_digests path t;
  let loaded = Verdicts.load path in
  equal
    (result (pair (list string) (option string)) string)
    (Ok (rows t, Option.map identity_row identity))
    (load_rows loaded);
  equal (option string) suite
    (Result.fold
       ~ok:(fun (f : Verdicts.file) -> f.suite)
       ~error:(fun _ -> None)
       loaded);
  equal
    (list (pair (list string) string))
    (List.sort
       (fun (a, _) (b, _) -> List.compare String.compare a b)
       test_digests)
    (Result.fold
       ~ok:(fun (f : Verdicts.file) -> f.test_digests)
       ~error:(fun _ -> [])
       loaded)

(* A file with test digests, given unsorted, and records with each mark,
   prefix and effort. *)
let marked_round_trip () =
  let d c = String.make 32 c in
  let effort retries pass = { Verdicts.retries; pass; settings = d 'e' } in
  let t =
    collection
      [
        record ~effort:(effort 0 1) ~prefix:(d 'b') ~reused:true
          (id "lib/a.ml" 1 0 "lt")
          (Verdicts.killed [ [ "t" ] ]);
        record ~effort:(effort 100 101) (id "lib/a.ml" 2 0 "lt")
          (Verdicts.killed [ [ "t" ] ]);
        record ~effort:(effort 100 3) ~reused:true (id "lib/a.ml" 3 0 "lt")
          (Verdicts.survived [ [ "t" ]; [ "u" ] ]);
        record ~effort:(effort 1 1) (id "lib/a.ml" 4 0 "lt")
          (Verdicts.Unknown (Other "x"));
      ]
  in
  let test_digests =
    [ ([ "u" ], d '1'); ([ "g"; "t" ], d '2'); ([ "t" ], d '3') ]
  in
  List.iter
    (fun refused ->
      let path = Filename.concat (temp_dir ()) "saved.mutants" in
      Verdicts.save ?refused ~test_digests path t;
      let f = require_ok ~pp:Verdicts.pp_error (Verdicts.load path) in
      equal records t f.verdicts;
      equal (option string) refused f.refused;
      equal
        (list (pair (list string) string))
        [ ([ "g"; "t" ], d '2'); ([ "t" ], d '3'); ([ "u" ], d '1') ]
        f.test_digests)
    [ None; Some "refused" ]

let bad_test_digests =
  [
    ("a short digest", [ ([ "t" ], "abc") ]);
    ("an uppercase digest", [ ([ "t" ], String.make 32 'A') ]);
    ("two digests of one test", [ ([ "t" ], digest); ([ "t" ], digest) ]);
    ( "two digests of one test, apart",
      [ ([ "t" ], digest); ([ "u" ], digest); ([ "t" ], String.make 32 'b') ] );
  ]

let refused_test_digests (_, test_digests) =
  let dir = temp_dir () in
  raises_match (Exn.invalid_arg ~sub:"Windtrap_runtime.Verdicts") (fun () ->
      Verdicts.save ~test_digests
        (Filename.concat dir "unwritten.mutants")
        Verdicts.empty);
  equal (list string) [] (Array.to_list (Sys.readdir dir))

let order_free records =
  let dir = temp_dir () in
  let saved name t =
    let path = Filename.concat dir name in
    Verdicts.save path t;
    read path
  in
  equal string
    (saved "a.mutants" (collection records))
    (saved "b.mutants" (collection (List.rev records)))

let refusal () =
  let path = Filename.concat (temp_dir ()) "saved.mutants" in
  let reason = "the suite is not deterministic:\nfailed twice" in
  Verdicts.save ~refused:reason path sample;
  expect_exact
    (String.concat "\n"
       (List.filteri (fun i _ -> i < 3) (String.split_on_char '\n' (read path))))
  @@ __POS_OF__
       {|windtrap-mutants-v15
refused 44 the suite is not deterministic:
failed twice|};
  equal (option string) (Some reason)
    (Result.fold
       ~ok:(fun (f : Verdicts.file) -> f.refused)
       ~error:(fun _ -> None)
       (Verdicts.load path))

let replaced () =
  let path = Filename.concat (temp_dir ()) "saved.mutants" in
  Verdicts.save ~identity:{ exe = "test/a.exe"; digest } path sample;
  Verdicts.save path Verdicts.empty;
  equal
    (result (pair (list string) (option string)) string)
    (Ok ([], None))
    (load_rows (Verdicts.load path))

let bad_identities =
  [
    ("an empty exe", { Verdicts.exe = ""; digest });
    ("a short digest", { exe = "a"; digest = "abc" });
    ("an uppercase digest", { exe = "a"; digest = String.make 32 'A' });
    ( "a digest that is not hexadecimal",
      { exe = "a"; digest = String.make 32 'x' } );
  ]

let refused_identity (_, identity) =
  let dir = temp_dir () in
  raises_match (Exn.invalid_arg ~sub:"Windtrap_runtime.Verdicts") (fun () ->
      Verdicts.save ~identity
        (Filename.concat dir "unwritten.mutants")
        Verdicts.empty);
  equal (list string) [] (Array.to_list (Sys.readdir dir))

let headers =
  [
    ("the empty file", "");
    ("a coverage file", "windtrap-coverage-v3\n1\n");
    ("the upstream version before", "windtrap-mutants-v5\ntested\n0\n");
    ("the version before", "windtrap-mutants-v14\ntested\n0\n");
    ("two versions before", "windtrap-mutants-v13\ntested\n0\n");
    ("three versions before", "windtrap-mutants-v12\ntested\n0\n");
    ("a fork version before", "windtrap-mutants-v11\ntested\n0\n");
    ("a later version", "windtrap-mutants-v16\ntested\n0\n0\n");
    ("the magic in uppercase", "WINDTRAP-MUTANTS-V1\n0\n");
    ("the magic and a digit", "windtrap-mutants-v150\ntested\n0\n0\n");
    ("plain text", "hello\nworld\n");
  ]

let unknown_format (_, text) =
  let path, loaded = load_text text in
  equal string path
    (require_match
       (function
         | Error (Verdicts.Unknown_format { path; _ }) -> Some path | _ -> None)
       loaded)

let record_prefix = "windtrap-mutants-v15\ntested\n0\n1\n8 lib/a.ml "

(* The fields after the previous outcome of a valid record. *)
let tail = " 0 1 " ^ zeros ^ " none fresh"

(* A file of one record with [verdict], no previous outcome, a valid effort,
   [prefix] and [mark]. *)
let with_tail ?(prefix = "none") ?(mark = "fresh") verdict =
  strf "%s1 2 1 5 3 add 1 b 1 a 0  %s none 0 1 %s %s %s\n" record_prefix verdict
    zeros prefix mark

(* A file of one valid record, up to its effort. *)
let effort_prefix =
  record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  killed 1 1 1 t none "

(* A file with the test count and digest lines [lines], and no record. *)
let with_digests lines = "windtrap-mutants-v15\ntested\n" ^ lines ^ "0\n"

let corrupt_files =
  [
    ("the magic line alone", "windtrap-mutants-v15");
    ("a negative record count", "windtrap-mutants-v15\ntested\n0\n-1\n");
    ( "a record count past the input",
      "windtrap-mutants-v15\ntested\n0\n99999999\n" );
    ( "fewer records than the count",
      "windtrap-mutants-v15\n\
       tested\n\
       0\n\
       2\n\
       8 lib/a.ml 1 2 1 5 3 add 1 b 1 a 0  unreached none" ^ tail ^ "\n" );
    ( "an empty file name",
      "windtrap-mutants-v15\n\
       tested\n\
       0\n\
       1\n\
       0  1 2 1 5 3 add 0 0 1 b 1 a 0  unreached\n" );
    ( "a file name past the input",
      "windtrap-mutants-v15\n\
       tested\n\
       0\n\
       1\n\
       80 lib/a.ml 1 2 1 5 3 add 1 b 1 a 0  unreached\n" );
    ("line 0", record_prefix ^ "0 2 1 5 3 add 1 b 1 a 0  unreached\n");
    ("a negative line", record_prefix ^ "-3 2 1 5 3 add 1 b 1 a 0  unreached\n");
    ("a negative column", record_prefix ^ "1 -2 3 add 1 b 1 a 0  unreached\n");
    ("no end", record_prefix ^ "1 2 3 add 1 b 1 a 0  unreached\n");
    ( "an end column before the start",
      record_prefix ^ "1 2 1 1 3 add 1 b 1 a 0  unreached\n" );
    ( "an end line before the start",
      record_prefix ^ "2 2 1 5 3 add 1 b 1 a 0  unreached\n" );
    ( "a negative end column",
      record_prefix ^ "1 2 1 -5 3 add 1 b 1 a 0  unreached\n" );
    ( "a rewrite past the input",
      record_prefix ^ "1 2 1 5 30 add 1 b 1 a 0  unreached\n" );
    ( "an unknown rewrite",
      record_prefix ^ "1 2 1 5 4 plus 1 b 1 a 0  unreached\n" );
    ( "drop, which no instrumenter emits",
      record_prefix ^ "1 2 1 5 4 drop 1 b 1 a 0  unreached\n" );
    ( "a before past the input",
      record_prefix ^ "1 2 1 5 3 add 80 b 1 a 0  unreached\n" );
    ("no rendering", record_prefix ^ "1 2 1 5 3 add unreached\n");
    ( "an after past the input",
      record_prefix ^ "1 2 1 5 3 add 1 b 80 a unreached\n" );
    ("an unknown verdict", record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  errored\n");
    ("no verdict", record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0 \n");
    ("no source digest", record_prefix ^ "1 2 1 5 3 add 1 b 1 a\n");
    ( "a short source digest",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 3 abc unreached\n" );
    ( "an uppercase source digest",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 32 " ^ String.make 32 'A'
      ^ " unreached\n" );
    ( "a killing executable that is empty",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  killed_elsewhere 0 \n" );
    ( "no killing executable",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  killed_elsewhere\n" );
    ( "a survivor with no reaching test",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  survived 0\n" );
    ( "a reaching test count past the input",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  survived 99999999\n" );
    ( "a negative test path length",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  survived 1 -1\n" );
    ( "a test path shorter than its length",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  survived 2 1 1 g\n" );
    ( "a test name past the input",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  survived 1 1 80 g\n" );
    ( "a killing test count past the input",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  killed 99999999\n" );
    ( "a killing test name past the input",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  killed 1 1 80 g\n" );
    ( "a reason of the format before",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  unknown 7 crashed none\n" );
    ( "an unknown reason",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  unknown lost none\n" );
    ( "a deadline that is no number",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  unknown deadline x none\n" );
    ( "a negative deadline",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  unknown deadline -0x1p+0 none\n"
    );
    ( "a deadline that is not finite",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  unknown deadline nan none\n" );
    ( "a signal that is no number",
      record_prefix
      ^ "1 2 1 5 3 add 1 b 1 a 0  unknown crashed x none 1 a none\n" );
    ( "an exit status that is no number",
      record_prefix
      ^ "1 2 1 5 3 add 1 b 1 a 0  unknown crashed none x 1 a none\n" );
    ( "a crash with no phrase",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  unknown crashed none none\n" );
    ( "a negative memory limit",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  unknown memory -1 none\n" );
    ( "a flaky kill with no failure",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  unknown flaky_kill 1 1 t\n" );
    ( "two records of one identifier",
      "windtrap-mutants-v15\n\
       tested\n\
       0\n\
       2\n\
       8 lib/a.ml 1 2 1 5 3 add 1 b 1 a 0  unreached none" ^ tail
      ^ "\n8 lib/a.ml 1 2 1 5 3 add 1 b 1 a 0  killed 0 none" ^ tail ^ "\n" );
    ( "a malformed record after a valid one",
      "windtrap-mutants-v15\n\
       tested\n\
       0\n\
       2\n\
       8 lib/a.ml 1 2 1 5 3 add 1 b 1 a 0  killed 0 none" ^ tail
      ^ "\n8 lib/a.ml 0 2 1 5 3 add 1 b 1 a 0  unreached none" ^ tail ^ "\n" );
    ( "no previous outcome",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  killed 0\n" );
    ( "an unknown previous outcome",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  killed 0 maybe\n" );
    ( "was and no outcome",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  killed 0 was\n" );
    ( "a previous verdict that is no outcome",
      record_prefix ^ "1 2 1 5 3 add 1 b 1 a 0  killed 0 was unreached\n" );
    ("a short identity digest", "windtrap-mutants-v15\nexe abcd 1 a\n0\n");
    ("an empty identity exe", "windtrap-mutants-v15\nexe " ^ digest ^ " 0 \n0\n");
    ("no status", "windtrap-mutants-v15\n0\n");
    ("an unknown status", "windtrap-mutants-v15\nwhole\n0\n");
    ("a refusal past the input", "windtrap-mutants-v15\nrefused 80 r\n0\n");
    ("a suite past the input", "windtrap-mutants-v15\nsuite 80 s\ntested\n0\n");
    ("a suite and no status", "windtrap-mutants-v15\nsuite 1 s\n0\n");
    ( "two suite lines",
      "windtrap-mutants-v15\nsuite 1 s\nsuite 1 t\ntested\n0\n" );
    ( "a suite before the identity",
      "windtrap-mutants-v15\nsuite 1 s\nexe " ^ digest ^ " 1 a\ntested\n0\n" );
    ( "bytes after the last record",
      "windtrap-mutants-v15\ntested\n0\n0\nextra\n" );
    ("a negative test count", with_digests "-1\n");
    ("a test count past the input", with_digests "99999999\n");
    ("no test count", "windtrap-mutants-v15\ntested\n");
    ("a short test digest", with_digests "1\n1 1 t abc\n");
    ( "an uppercase test digest",
      with_digests ("1\n1 1 t " ^ String.make 32 'A' ^ "\n") );
    ("no test digest", with_digests "1\n1 1 t\n");
    ( "test digests out of order",
      with_digests ("2\n1 1 u " ^ digest ^ "\n1 1 t " ^ digest ^ "\n") );
    ( "two digests of one test",
      with_digests ("2\n1 1 t " ^ digest ^ "\n1 1 t " ^ digest ^ "\n") );
    ("no retries", effort_prefix ^ "\n");
    ( "a negative retries count",
      effort_prefix ^ "-1 1 " ^ zeros ^ " none fresh\n" );
    ("pass 0", effort_prefix ^ "0 0 " ^ zeros ^ " none fresh\n");
    ( "a pass above the retries count plus 1",
      effort_prefix ^ "1 3 " ^ zeros ^ " none fresh\n" );
    ("no settings", effort_prefix ^ "0 1\n");
    ("a short settings word", effort_prefix ^ "0 1 abc none fresh\n");
    ( "an uppercase settings word",
      effort_prefix ^ "0 1 " ^ String.make 32 'A' ^ " none fresh\n" );
    ("no prefix", effort_prefix ^ "0 1 " ^ zeros ^ "\n");
    ("a short prefix", effort_prefix ^ "0 1 " ^ zeros ^ " abc fresh\n");
    ( "a prefix on a kill that names no test",
      with_tail ~prefix:digest "killed 0" );
    ("a prefix on a survivor", with_tail ~prefix:digest "survived 1 1 1 t");
    ("no mark", effort_prefix ^ "0 1 " ^ zeros ^ " none\n");
    ("an unknown mark", effort_prefix ^ "0 1 " ^ zeros ^ " none maybe\n");
    ("a reused kill that names no test", with_tail ~mark:"reused" "killed 0");
    ("a reused unknown verdict", with_tail ~mark:"reused" "unknown other 1 x");
    ("a reused skip", with_tail ~mark:"reused" "killed_elsewhere 1 x");
    ("a reused unreached mutant", with_tail ~mark:"reused" "unreached");
    ( "a reused mutant that was not evaluated",
      with_tail ~mark:"reused" "not_evaluated" );
  ]

let corrupt (_, text) =
  let path, loaded = load_text text in
  equal string path (require_match corrupt_path loaded)

let corrupt_reasons () =
  let reason (name, text) =
    match snd (load_text text) with
    | Error (Corrupt { reason; _ }) -> strf "%s: %s" name reason
    | Error (Unknown_format _ | Unreadable _) | Ok _ -> name ^ ": not corrupt"
  in
  expect (String.concat "\n" (List.map reason corrupt_files))
  @@ __POS_OF__
       {|
    the magic line alone: expected status at offset 20
    a negative record count: negative record count
    a record count past the input: record count exceeds data
    fewer records than the count: expected file name length at offset 131
    an empty file name: empty file name
    a file name past the input: truncated file name
    line 0: line 0 is not 1-based
    a negative line: negative line
    a negative column: negative column
    no end: expected end column at offset 49
    an end column before the start: end 1:1 before start 1:2
    an end line before the start: end 1:5 before start 2:2
    a negative end column: negative end column
    a rewrite past the input: truncated rewrite
    an unknown rewrite: unknown rewrite "plus"
    drop, which no instrumenter emits: unknown rewrite "drop"
    a before past the input: truncated before
    no rendering: expected before length at offset 57
    an after past the input: truncated after
    an unknown verdict: unknown verdict "errored"
    no verdict: expected verdict at offset 68
    no source digest: expected source digest length at offset 65
    a short source digest: "abc" is not a source digest
    an uppercase source digest: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" is not a source digest
    a killing executable that is empty: empty killing executable
    no killing executable: expected killing executable length at offset 85
    a survivor with no reaching test: a survivor names no test (survived is not unreached)
    a reaching test count past the input: reaching test count exceeds data
    a negative test path length: negative test path length
    a test path shorter than its length: expected test path length at offset 85
    a test name past the input: truncated test name
    a killing test count past the input: killing test count exceeds data
    a killing test name past the input: truncated test name
    a reason of the format before: unknown reason "7"
    an unknown reason: unknown reason "lost"
    a deadline that is no number: invalid deadline "x"
    a negative deadline: invalid deadline "-0x1p+0"
    a deadline that is not finite: invalid deadline "nan"
    a signal that is no number: invalid signal "x"
    an exit status that is no number: invalid exit status "x"
    a crash with no phrase: expected crash length at offset 94
    a negative memory limit: negative memory limit
    a flaky kill with no failure: expected failure length at offset 93
    two records of one identifier: duplicate record for lib/a.ml:1:2:add
    a malformed record after a valid one: line 0 is not 1-based
    no previous outcome: expected previous outcome at offset 77
    an unknown previous outcome: unknown previous outcome "maybe"
    was and no outcome: expected previous outcome at offset 81
    a previous verdict that is no outcome: unknown previous outcome "unreached"
    a short identity digest: identity digest is not 32 hex characters at offset 25
    an empty identity exe: empty executable identity
    no status: unknown status "0"
    an unknown status: unknown status "whole"
    a refusal past the input: truncated refusal
    a suite past the input: truncated suite
    a suite and no status: unknown status "0"
    two suite lines: unknown status "suite"
    a suite before the identity: unknown status "exe"
    bytes after the last record: trailing data at offset 32
    a negative test count: negative test count
    a test count past the input: test count exceeds data
    no test count: expected test count at offset 28
    a short test digest: "abc" is not a test digest
    an uppercase test digest: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" is not a test digest
    no test digest: "0" is not a test digest
    test digests out of order: test digests out of order or repeated
    two digests of one test: test digests out of order or repeated
    no retries: expected retries at offset 89
    a negative retries count: negative retries
    pass 0: pass 0 is not from 1 to 1
    a pass above the retries count plus 1: pass 3 is not from 1 to 2
    no settings: expected settings digest at offset 92
    a short settings word: "abc" is not a settings digest
    an uppercase settings word: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" is not a settings digest
    no prefix: expected prefix at offset 125
    a short prefix: "abc" is not a prefix
    a prefix on a kill that names no test: a prefix on a verdict that names no killing test
    a prefix on a survivor: a prefix on a verdict that names no killing test
    no mark: expected mark at offset 130
    an unknown mark: unknown mark "maybe"
    a reused kill that names no test: a reused verdict that cannot be reused
    a reused unknown verdict: a reused verdict that cannot be reused
    a reused skip: a reused verdict that cannot be reused
    a reused unreached mutant: a reused verdict that cannot be reused
    a reused mutant that was not evaluated: a reused verdict that cannot be reused
    |}

let error_messages () =
  let pp e = Format.asprintf "%a" Verdicts.pp_error e in
  expect
    (String.concat "\n"
       [
         pp (Unknown_format { path = "f.mutants"; header = "junk" });
         pp
           (Unreadable
              { path = "f.mutants"; reason = "No such file or directory" });
         pp
           (Corrupt
              { path = "f.mutants"; reason = "unknown verdict \"errored\"" });
       ])
  @@ __POS_OF__
       {|
    f.mutants: not a windtrap verdict file (expected header "windtrap-mutants-v15", found "junk"); files written by other windtrap versions are not readable - delete the stale verdict files, then re-run the mutation tests
    f.mutants: cannot read verdict file: No such file or directory
    f.mutants: corrupt verdict file: unknown verdict "errored"
    |}

(* Below a build directory, the identity is not the path. *)
let writer () =
  let build = Filename.concat (temp_dir ()) "_build" in
  Sys.mkdir build 0o755;
  let exe = Filename.concat build "t.exe" in
  Out_channel.with_open_bin exe (fun oc -> output_string oc "an executable");
  let digest = require_some (Instr.file_digest exe) in
  equal (option identity)
    (Some { Verdicts.exe = Instr.exe_identity ~exe; digest })
    (Verdicts.writer_identity ~exe)

let files =
  group "Verdict files"
    [
      test
        "format is the magic line, the mutants directory and extension, and \
         the verdict kind" (fun () ->
          equal (list string)
            [ "windtrap-mutants-v15"; "mutants"; "mutants"; "verdict" ]
            Verdicts.[ format.magic; format.dir; format.ext; format.kind ]);
      test
        "save writes the magic line, the count, then the records by identifier"
        (fun () ->
          expect_exact (saved sample)
          @@ __POS_OF__
               {|windtrap-mutants-v15
tested
0
7
8 lib/a.ml 1 2 1 7 3 add 5 a - b 5 a + b 0  unreached none 0 1 00000000000000000000000000000000 none fresh
8 lib/b.ml 3 4 3 10 3 not 6 p && q 12 not (p && q) 0  killed 0 was not_evaluated 0 1 00000000000000000000000000000000 none fresh
8 lib/b.ml 5 0 5 6 2 or 6 a || b 6 a && b 0  survived 2 1 1 x 2 1 y 1 z was killed 0 1 00000000000000000000000000000000 none fresh
8 lib/c.ml 7 1 7 6 3 sub 5 a + b 5 a - b 0  not_evaluated none 0 1 00000000000000000000000000000000 none fresh
8 lib/c.ml 9 0 9 5 3 add 5 a - b 5 a + b 0  outside_tests none 0 1 00000000000000000000000000000000 none fresh
8 lib/c.ml 11 3 11 8 2 le 5 a < b 6 a <= b 0  unknown other 29 its run was killed by SIGSEGV none 0 1 00000000000000000000000000000000 none fresh
8 lib/d.ml 1 0 1 5 3 add 5 a - b 5 a + b 32 cccccccccccccccccccccccccccccccc killed_elsewhere 18 default/test/a.exe none 0 1 00000000000000000000000000000000 none fresh
|});
      test "save writes each kill and each reason" (fun () ->
          expect_exact (saved kills_and_reasons)
          @@ __POS_OF__
               {|windtrap-mutants-v15
tested
0
11
8 lib/k.ml 1 0 1 5 3 add 5 a - b 5 a + b 0  killed 0 none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 2 0 2 5 3 add 5 a - b 5 a + b 0  killed 1 2 4 calc 4 adds none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 3 0 3 5 3 add 5 a - b 5 a + b 0  killed 3 1 4 adds 2 4 calc 4 adds 2 4 calc 4 subs none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 4 0 4 5 3 add 5 a - b 5 a + b 0  unknown deadline 0x1.4p+1 none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 5 0 5 5 3 add 5 a - b 5 a + b 0  unknown deadline 0x1.999999999999ap-4 none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 6 0 6 5 3 add 5 a - b 5 a + b 0  unknown crashed -10 none 21 was killed by SIGSEGV none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 7 0 7 5 3 add 5 a - b 5 a + b 0  unknown crashed none 3 38 ended when code under test called exit none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 8 0 8 5 3 add 5 a - b 5 a + b 0  unknown crashed none none 5 ended none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 9 0 9 5 3 add 5 a - b 5 a + b 0  unknown memory 512 none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 10 0 10 5 3 add 5 a - b 5 a + b 0  unknown flaky_kill 2 4 calc 4 adds 37 its killing test calc adds also fails none 0 1 00000000000000000000000000000000 none fresh
8 lib/k.ml 11 0 11 5 3 add 5 a - b 5 a + b 0  unknown other 30 the suite is not deterministic none 0 1 00000000000000000000000000000000 none fresh
|});
      test "load reads back each kill and each reason" (fun () ->
          let path = Filename.concat (temp_dir ()) "saved.mutants" in
          Verdicts.save path kills_and_reasons;
          equal
            (result (list string) string)
            (Ok (rows kills_and_reasons))
            (Result.map fst (load_rows (Verdicts.load path))));
      test "reason_text is the text of each reason" (fun () ->
          expect (String.concat "\n" reason_texts)
          @@ __POS_OF__
               {|
            its run passed its deadline of 2.5s
            its run passed its deadline of 0.1s
            its run was killed by SIGSEGV
            its run ended when code under test called exit
            its run ended
            its run passed its memory limit of 512 MB
            its killing test calc adds also fails
            the suite is not deterministic
            |});
      test "save writes an identity after the magic line" (fun () ->
          expect_exact
            (saved ~identity:{ exe = "test/a.exe"; digest } Verdicts.empty)
          @@ __POS_OF__
               {|windtrap-mutants-v15
exe aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 10 test/a.exe
tested
0
0
|});
      test "save writes the suite after the identity, as a name" (fun () ->
          expect_exact
            (saved
               ~identity:{ exe = "test/a.exe"; digest }
               ~suite:"lib/a b.ml\n" Verdicts.empty)
          @@ __POS_OF__
               {|windtrap-mutants-v15
exe aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 10 test/a.exe
suite 11 lib/a b.ml

tested
0
0
|});
      test "save writes a refusal after the identity, and load reads it" refusal;
      test "load reads back a previous outcome of every kind" (fun () ->
          let t =
            collection
              (List.mapi
                 (fun i previous ->
                   record ?previous
                     (id "lib/a.ml" (i + 1) 0 "lt")
                     (Verdicts.Unknown (Other "crashed")))
                 [ None; Some `Killed; Some `Survived; Some `Not_evaluated ])
          in
          let path = Filename.concat (temp_dir ()) "saved.mutants" in
          Verdicts.save path t;
          equal
            (result (list string) string)
            (Ok
               [
                 {|"lib/a.ml":1:0:lt (to 1:1) "b" -> "a": unknown: crashed|};
                 {|"lib/a.ml":2:0:lt (to 2:1) "b" -> "a": unknown: crashed was killed|};
                 {|"lib/a.ml":3:0:lt (to 3:1) "b" -> "a": unknown: crashed was survived|};
                 {|"lib/a.ml":4:0:lt (to 4:1) "b" -> "a": unknown: crashed was not evaluated|};
               ])
            (Result.map fst (load_rows (Verdicts.load path))));
      prop
        "load reads back what save wrote, identity, suite and sorted test \
         digests included"
        any_file round_trip;
      test
        "load reads back each mark, prefix and effort, and the test digests \
         sorted"
        marked_round_trip;
      cases
        "save raises Invalid_argument on a malformed or repeated test digest \
         and writes nothing"
        ~id:fst bad_test_digests refused_test_digests;
      prop
        "save writes one file for a collection, whatever the order of its adds"
        (Gen.list ~size:(Gen.int_range 0 6) small_record)
        order_free;
      test "save replaces the file, identity included" replaced;
      cases
        "save raises Invalid_argument on a malformed identity and writes \
         nothing"
        ~id:fst bad_identities refused_identity;
      cases "load refuses another first line as Unknown_format, naming the path"
        ~id:fst headers unknown_format;
      cases "load refuses malformed data as Corrupt, naming the path" ~id:fst
        corrupt_files corrupt;
      test "a Corrupt reason names the field and its fault" corrupt_reasons;
      test "load of a missing file is Unreadable, naming the path" (fun () ->
          let path = Filename.concat (temp_dir ()) "missing.mutants" in
          equal string ("unreadable " ^ path)
            (Result.fold
               ~ok:(fun _ -> "loaded")
               ~error:error_row (Verdicts.load path)));
      test "pp_error names the file, the fault and what to do" error_messages;
      test
        "output_file is Instr.output_dir of format, then the digest of the \
         suite" (fun () ->
          let exe = "/w/p/_build/default/test/t.exe" in
          equal string
            (strf "%s-%s.mutants"
               (Instr.output_dir Verdicts.format ~exe)
               (Digest.to_hex (Digest.string "lib/a.ml")))
            (Verdicts.output_file ~exe ~suite:"lib/a.ml"));
      test "output_file gives each suite of an executable its own file"
        (fun () ->
          let exe = "/w/p/_build/default/test/t.exe" in
          let suites = [ ""; "adds"; "Adds"; "subs"; "lib/a.ml"; "lib_a.ml" ] in
          let files =
            List.map (fun suite -> Verdicts.output_file ~exe ~suite) suites
          in
          equal int (List.length suites)
            (List.length (List.sort_uniq String.compare files)));
      test "writer_identity is the executable's identity and digest" writer;
      test "writer_identity is None for a file that cannot be read" (fun () ->
          is_none ~pp:pp_identity
            (Verdicts.writer_identity
               ~exe:(Filename.concat (temp_dir ()) "no-such.exe")));
    ]

let () = exit (run "verdicts" [ verdicts; collections; reuse; files ])
