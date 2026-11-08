(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Verdicts *)

type reaching_test = string list

type unknown_reason =
  | Deadline of { seconds : float }
  | Crashed of { signal : int option; status : int option; how : string }
  | Memory of { mb : int }
  | Flaky_kill of { test : reaching_test; failure : string }
  | Other of string

let seconds s =
  if s < 10. then Printf.sprintf "%.1fs" s else Printf.sprintf "%.0fs" s

let reason_text = function
  | Deadline { seconds = s } -> "its run passed its deadline of " ^ seconds s
  | Crashed { how; _ } -> "its run " ^ how
  | Memory { mb } ->
      Printf.sprintf "its run passed its memory limit of %d MB" mb
  | Flaky_kill { failure; _ } -> failure
  | Other reason -> reason

type verdict =
  | Killed of { by : reaching_test list }
  | Killed_elsewhere of { exe : string }
  | Unknown of unknown_reason
  | Survived of { first : reaching_test; others : reaching_test list }
  | Not_evaluated
  | Not_sampled
  | Outside_tests
  | Unreached

(* A collection builds each survivor it holds here, so its reaching tests
   are sorted and without duplicates. *)
let survived ts =
  match List.sort_uniq (List.compare String.compare) ts with
  | [] ->
      invalid_arg
        "Windtrap_runtime.Verdicts.survived: a survivor names at least one test"
  | first :: others -> Survived { first; others }

let killed by = Killed { by = List.sort_uniq (List.compare String.compare) by }

(* The order in which verdicts outrank one another in a merge. *)
let rank = function
  | Killed _ -> 7
  | Killed_elsewhere _ -> 6
  | Unknown _ -> 5
  | Not_evaluated -> 4
  | Not_sampled -> 3
  | Survived _ -> 2
  | Outside_tests -> 1
  | Unreached -> 0

(* The verdict of a mutant that one executable saw as [a] and another as
   [b]. Both are held by a collection, so a survivor and a kill are already
   sorted. Of two reasons or two killers, the smaller stays, so the merge does
   not depend on the order. *)
let merge_verdict a b =
  match (a, b) with
  | Survived x, Survived y ->
      survived (x.first :: y.first :: (x.others @ y.others))
  | Killed x, Killed y -> killed (x.by @ y.by)
  | Unknown x, Unknown y ->
      let order =
        match String.compare (reason_text x) (reason_text y) with
        | 0 -> compare x y
        | c -> c
      in
      if order <= 0 then a else b
  | Killed_elsewhere x, Killed_elsewhere y ->
      if String.compare x.exe y.exe <= 0 then a else b
  | ( ( Killed _ | Killed_elsewhere _ | Unknown _ | Not_evaluated | Not_sampled
      | Survived _ | Outside_tests | Unreached ),
      ( Killed _ | Killed_elsewhere _ | Unknown _ | Not_evaluated | Not_sampled
      | Survived _ | Outside_tests | Unreached ) ) ->
      if rank a >= rank b then a else b

type outcome = [ `Killed | `Survived | `Not_evaluated ]

let outcome = function
  | Killed _ -> Some `Killed
  | Survived _ -> Some `Survived
  | Not_evaluated -> Some `Not_evaluated
  | Killed_elsewhere _ | Unknown _ | Not_sampled | Outside_tests | Unreached ->
      None

(* The sample *)

(* The spelling of [Seed.to_string]. *)
let seed_token seed = Printf.sprintf "s1:%016Lx" seed

let in_sample ~percent ~seed (id : Mutate.id) =
  percent >= 100.
  ||
  let digest =
    Digest.string (seed_token seed ^ "\000" ^ Mutate.id_to_string id)
  in
  Int64.shift_right_logical (String.get_int64_be digest 0) 2
  < Int64.of_float (percent /. 100. *. 0x1p62)

(* Collections *)

type effort = { retries : int; pass : int; settings : string }

let effort_covers kind ~judged ~asked =
  String.equal judged.settings asked.settings
  &&
  match kind with
  | `Killed ->
      (asked.retries = 0 || judged.retries > 0)
      && judged.pass - 1 <= asked.retries
  | `Survived -> asked.retries <= judged.retries

let add_name b s = Printf.bprintf b "%d %s" (String.length s) s

let add_test b names =
  Printf.bprintf b "%d" (List.length names);
  List.iter (Printf.bprintf b " %a" add_name) names

let prefix_digest paths =
  let b = Buffer.create 256 in
  Printf.bprintf b "%d" (List.length paths);
  List.iter (Printf.bprintf b "\n%a" add_test) paths;
  Digest.to_hex (Digest.string (Buffer.contents b))

type record = {
  id : Mutate.id;
  end_line : int;
  end_col : int;
  before : string;
  after : string;
  source_digest : string option;
  verdict : verdict;
  previous : outcome option;
  effort : effort;
  prefix : string option;
  reused : bool;
}

let names_a_test = function
  | Killed { by = _ :: _ } -> true
  | Killed { by = [] }
  | Killed_elsewhere _ | Unknown _ | Survived _ | Not_evaluated | Not_sampled
  | Outside_tests | Unreached ->
      false

let record_of_mutant ~effort ?prefix (m : Mutate.mutant) verdict =
  {
    id = m.id;
    end_line = m.end_line;
    end_col = m.end_col;
    before = m.before;
    after = m.after;
    source_digest = m.source_digest;
    verdict;
    previous = None;
    effort;
    prefix = Option.map prefix_digest prefix;
    reused = false;
  }

let changed r =
  match (r.previous, outcome r.verdict) with
  | Some was, Some is when was <> is && not r.reused -> Some (was, is)
  | _ -> None

module Id_map = Map.Make (struct
  type t = Mutate.id

  let compare = Mutate.compare_id
end)

(* Each record is bound under its own [id]. *)
type t = record Id_map.t

let empty = Id_map.empty

(* Two records of one mutant disagree on its rendering, its end or its source
   only across builds of one source, and nothing says which build the reader
   has open. The smaller rendering wins, then the smaller end and source
   digest, which keeps [add] and [merge] commutative and associative. *)
let combine a b =
  let key r = (r.before, r.after, r.end_line, r.end_col, r.source_digest) in
  let kept = if compare (key a) (key b) <= 0 then a else b in
  let outcome_rank = function
    | `Killed -> 2
    | `Not_evaluated -> 1
    | `Survived -> 0
  in
  let previous =
    match (a.previous, b.previous) with
    | None, p | p, None -> p
    | Some x, Some y -> Some (if outcome_rank x >= outcome_rank y then x else y)
  in
  (* The effort, the prefix and the mark come from the record of the higher
     rank. Of two records of one rank, the smaller effort and prefix, and the
     mark only when the two have it. *)
  let effort, prefix, reused =
    match Int.compare (rank a.verdict) (rank b.verdict) with
    | 0 ->
        let effort, prefix = min (a.effort, a.prefix) (b.effort, b.prefix) in
        (effort, prefix, a.reused && b.reused)
    | c ->
        let r = if c > 0 then a else b in
        (r.effort, r.prefix, r.reused)
  in
  {
    kept with
    verdict = merge_verdict a.verdict b.verdict;
    previous;
    effort;
    prefix;
    reused;
  }

let add t r =
  let r =
    match r.verdict with
    | Survived s -> { r with verdict = survived (s.first :: s.others) }
    | Killed { by } -> { r with verdict = killed by }
    | Killed_elsewhere _ | Unknown _ | Not_evaluated | Not_sampled
    | Outside_tests | Unreached ->
        r
  in
  (* Only a kill that names a test has a prefix. *)
  let r = if names_a_test r.verdict then r else { r with prefix = None } in
  Id_map.update r.id
    (function None -> Some r | Some prior -> Some (combine prior r))
    t

let records t = List.map snd (Id_map.bindings t)
let merge a b = Id_map.union (fun _ a b -> Some (combine a b)) a b

(* After a verdict that is no outcome, the outcome before it stays, so that
   a skip or an unknown verdict between two runs hides no change. *)
let with_previous ~prior t =
  let same p r =
    Option.is_some r.source_digest
    && p.source_digest = r.source_digest
    && p.end_line = r.end_line && p.end_col = r.end_col
    && String.equal p.before r.before
    && String.equal p.after r.after
  in
  Id_map.map
    (fun r ->
      let previous =
        match Id_map.find_opt r.id prior with
        | Some p when same p r -> (
            match outcome p.verdict with
            | Some _ as was -> was
            | None -> p.previous)
        | Some _ | None -> None
      in
      { r with previous })
    t

(* Verdict files *)

let format =
  {
    Instr.magic = "windtrap-mutants-v16";
    kind = "verdict";
    dir = "mutants";
    ext = "mutants";
    remedy = "delete the stale verdict files, then re-run the mutation tests";
    who = "Windtrap_runtime.Verdicts";
  }

type error = Instr.error =
  | Unknown_format of { path : string; header : string }
  | Unreadable of { path : string; reason : string }
  | Corrupt of { path : string; reason : string }

let pp_error ppf e = Instr.pp_error format ppf e

type identity = Instr.identity = { exe : string; digest : string }

(* The digest, not the modification time, tells that the executable on disk
   is not the writer: dune's shared cache restores an artifact with its
   original timestamps. *)
let writer_identity ~exe =
  Option.map
    (fun digest -> { exe = Instr.exe_identity ~exe; digest })
    (Instr.file_digest exe)

(* A digest, because a suite name can hold "/" or differ from another only
   in case. *)
let output_file ~exe ~suite =
  Printf.sprintf "%s-%s.%s"
    (Instr.output_dir format ~exe)
    (Digest.to_hex (Digest.string suite))
    format.ext

type file = {
  verdicts : t;
  identity : identity option;
  suite : string option;
  refused : string option;
  sample : (float * int64) option;
  test_digests : (reaching_test * string) list;
}

let compare_test = List.compare String.compare
let equal_test = List.equal String.equal

module Test_map = Map.Make (struct
  type t = reaching_test

  let compare = compare_test
end)

let lookup digests =
  let map =
    List.fold_left
      (fun map (test, digest) -> Test_map.add test digest map)
      Test_map.empty digests
  in
  fun test -> Test_map.find_opt test map

let rec through test = function
  | [] -> []
  | path :: paths ->
      if equal_test path test then [ path ] else path :: through test paths

let reuse ~last ~recorded ~digest ~effort ~reaching (m : Mutate.mutant) =
  let unchanged test =
    match (recorded test, digest test) with
    | Some was, Some is -> String.equal was is
    | Some _, None | None, (Some _ | None) -> false
  in
  let same (p : record) =
    Option.is_some m.source_digest
    && p.source_digest = m.source_digest
    && p.end_line = m.end_line && p.end_col = m.end_col
    && String.equal p.before m.before
    && String.equal p.after m.after
  in
  let compared (p : record) =
    match p.verdict with
    | Killed { by = [ test ] }
      when List.exists (equal_test test) reaching
           && effort_covers `Killed ~judged:p.effort ~asked:effort ->
        let prefix = through test reaching in
        if p.prefix = Some (prefix_digest prefix) then Some prefix else None
    | Survived { first; others }
      when effort_covers `Survived ~judged:p.effort ~asked:effort
           && List.equal equal_test (first :: others)
                (List.sort_uniq compare_test reaching) ->
        Some reaching
    | Killed _ | Killed_elsewhere _ | Unknown _ | Survived _ | Not_evaluated
    | Not_sampled | Outside_tests | Unreached ->
        None
  in
  match (last.refused, Id_map.find_opt m.id last.verdicts) with
  | None, Some p when same p -> (
      match compared p with
      | Some tests when List.for_all unchanged tests ->
          Some
            {
              (record_of_mutant ~effort:p.effort m p.verdict) with
              prefix = p.prefix;
              reused = true;
            }
      | Some _ | None -> None)
  | (Some _ | None), _ -> None

(* The records after the header. Every number is in decimal, and a name is
   [<byte length> <bytes>], so it may hold any byte:

     [suite <name>]
     tested | refused <reason>
     sample none | sample <percent> <seed>
     <test count>
     <test> <digest>
     <record count>
     <file> <line> <col> <end line> <end col> <rewrite> <before> <after> <source> <verdict> <previous> <retries> <pass> <settings> <prefix> <mark>

   with one [<test> <digest>] line for each test digest, in the order of the
   tests, and one record line for each record, in [Mutate.compare_id] order.
   [<source>] is a name: the digest of the source file that the instrumenter
   read, or empty when the instrumenter could not read it. A test is [<k>]
   and then its [k] names. [<percent>] is a hexadecimal float above 0 and
   below 100, and [<seed>] is [s1:] and 16 lowercase hexadecimal digits.
   [<verdict>] is [unreached], [outside_tests], [killed <n>] and then [n]
   killing tests, [killed_elsewhere <exe>] with a name that is not empty,
   [not_evaluated], [not_sampled] in a file with a sample, [unknown <reason>], or
   [survived <n>] and then [n] reaching tests, with [n] above 0. [<reason>]
   is [deadline <seconds>] with a hexadecimal float, [crashed <signal>
   <status> <how>] where each of the two is [none] or an integer,
   [memory <mb>], [flaky_kill <test> <failure>] or [other <text>], where
   [<how>], [<failure>] and [<text>] are names. [<previous>] is [none], or
   [was] and then [killed], [survived] or [not_evaluated]. [<retries>] and
   [<pass>] are numbers, [<pass>] from 1 to [<retries>] + 1. [<digest>] and
   [<settings>] are 32 lowercase hexadecimal digits, and so is [<prefix>],
   or [none]. Only a kill that names a test has a prefix. [<mark>] is
   [fresh], or [reused] on a survivor or on a kill that names a test. [load]
   reads this grammar and nothing else, and refuses a rewrite outside
   [Mutate.rewrites], which no report could render. *)
let load path =
  let read_test c =
    List.init (Instr.read_count c "test path length") (fun _ ->
        Instr.read_name c "test name")
  in
  let read_digest c what =
    match Instr.read_word c what with
    | word when Instr.is_digest word -> word
    | word -> Instr.parse_fail "%S is not a %s" word what
  in
  let read_int c what =
    match Instr.read_word c what with
    | "none" -> None
    | word -> (
        match int_of_string_opt word with
        | Some n -> Some n
        | None -> Instr.parse_fail "invalid %s %S" what word)
  in
  let read_reason c =
    match Instr.read_word c "reason" with
    | "deadline" -> (
        let word = Instr.read_word c "deadline" in
        match float_of_string_opt word with
        | Some seconds when Float.is_finite seconds && seconds >= 0. ->
            Deadline { seconds }
        | Some _ | None -> Instr.parse_fail "invalid deadline %S" word)
    | "crashed" ->
        let signal = read_int c "signal" in
        let status = read_int c "exit status" in
        let how = Instr.read_name c "crash" in
        Crashed { signal; status; how }
    | "memory" -> Memory { mb = Instr.read_nat c "memory limit" }
    | "flaky_kill" ->
        let test = read_test c in
        let failure = Instr.read_name c "failure" in
        Flaky_kill { test; failure }
    | "other" -> Other (Instr.read_name c "reason")
    | word -> Instr.parse_fail "unknown reason %S" word
  in
  let read_verdict ~sampled c =
    match Instr.read_word c "verdict" with
    | "unreached" -> Unreached
    | "killed" ->
        let n = Instr.read_count c "killing test count" in
        killed (List.init n (fun _ -> read_test c))
    | "killed_elsewhere" ->
        let exe = Instr.read_name c "killing executable" in
        if exe = "" then Instr.parse_fail "empty killing executable";
        Killed_elsewhere { exe }
    | "not_evaluated" -> Not_evaluated
    | "not_sampled" ->
        if not sampled then
          Instr.parse_fail "a not_sampled record in a file with no sample";
        Not_sampled
    | "outside_tests" -> Outside_tests
    | "unknown" -> Unknown (read_reason c)
    | "survived" ->
        let n = Instr.read_count c "reaching test count" in
        if n = 0 then
          Instr.parse_fail
            "a survivor names no test (survived is not unreached)";
        survived (List.init n (fun _ -> read_test c))
    | word -> Instr.parse_fail "unknown verdict %S" word
  in
  let read_previous c =
    match Instr.read_word c "previous outcome" with
    | "none" -> None
    | "was" -> (
        match Instr.read_word c "previous outcome" with
        | "killed" -> Some `Killed
        | "survived" -> Some `Survived
        | "not_evaluated" -> Some `Not_evaluated
        | word -> Instr.parse_fail "unknown previous outcome %S" word)
    | word -> Instr.parse_fail "unknown previous outcome %S" word
  in
  let read_sample c =
    (match Instr.read_word c "sample line" with
    | "sample" -> ()
    | word -> Instr.parse_fail "expected the sample line, found %S" word);
    match Instr.read_word c "sample" with
    | "none" -> None
    | word -> (
        let percent =
          match float_of_string_opt word with
          | Some p when p > 0. && p < 100. -> p
          | Some _ | None -> Instr.parse_fail "invalid sample percent %S" word
        in
        let token = Instr.read_word c "sample seed" in
        match Scanf.sscanf_opt token "s1:%Lx%!" Fun.id with
        | Some seed when String.equal (seed_token seed) token ->
            Some (percent, seed)
        | Some _ | None -> Instr.parse_fail "invalid sample seed %S" token)
  in
  let read_record ~sampled c =
    let file = Instr.read_name c "file name" in
    if file = "" then Instr.parse_fail "empty file name";
    let line = Instr.read_nat c "line" in
    if line < 1 then Instr.parse_fail "line %d is not 1-based" line;
    let col = Instr.read_nat c "column" in
    let end_line = Instr.read_nat c "end line" in
    let end_col = Instr.read_nat c "end column" in
    if end_line < line || (end_line = line && end_col < col) then
      Instr.parse_fail "end %d:%d before start %d:%d" end_line end_col line col;
    let rewrite = Instr.read_name c "rewrite" in
    if not (List.mem rewrite Mutate.rewrites) then
      Instr.parse_fail "unknown rewrite %S" rewrite;
    let id = { Mutate.file; line; col; rewrite } in
    let before = Instr.read_name c "before" in
    let after = Instr.read_name c "after" in
    let source_digest =
      match Instr.read_name c "source digest" with
      | "" -> None
      | digest when Instr.is_digest digest -> Some digest
      | digest -> Instr.parse_fail "%S is not a source digest" digest
    in
    let verdict = read_verdict ~sampled c in
    let previous = read_previous c in
    let retries = Instr.read_nat c "retries" in
    let pass = Instr.read_nat c "pass" in
    if pass < 1 || pass - 1 > retries then
      Instr.parse_fail "pass %d is not from 1 to %d" pass (retries + 1);
    let settings = read_digest c "settings digest" in
    let prefix =
      match Instr.read_word c "prefix" with
      | "none" -> None
      | word when Instr.is_digest word ->
          if not (names_a_test verdict) then
            Instr.parse_fail "a prefix on a verdict that names no killing test";
          Some word
      | word -> Instr.parse_fail "%S is not a prefix" word
    in
    let reused =
      match Instr.read_word c "mark" with
      | "fresh" -> false
      | "reused" -> (
          match verdict with
          | Survived _ -> true
          | verdict when names_a_test verdict -> true
          | _ -> Instr.parse_fail "a reused verdict that cannot be reused")
      | word -> Instr.parse_fail "unknown mark %S" word
    in
    {
      id;
      end_line;
      end_col;
      before;
      after;
      source_digest;
      verdict;
      previous;
      effort = { retries; pass; settings };
      prefix;
      reused;
    }
  in
  let rec read_digests c acc n =
    if n = 0 then List.rev acc
    else
      let test = read_test c in
      (match acc with
      | (prior, _) :: _ when compare_test prior test >= 0 ->
          Instr.parse_fail "test digests out of order or repeated"
      | _ -> ());
      read_digests c ((test, read_digest c "test digest") :: acc) (n - 1)
  in
  let rec read_records ~sampled c t n =
    if n = 0 then t
    else
      let r = read_record ~sampled c in
      if Id_map.mem r.id t then
        Instr.parse_fail "duplicate record for %s" (Mutate.id_to_string r.id);
      read_records ~sampled c (add t r) (n - 1)
  in
  match Result.bind (Instr.read_file path) (Instr.start format ~path) with
  | Error e -> Error e
  | Ok c -> (
      try
        let identity = Instr.read_identity c in
        let suite, status =
          match Instr.read_word c "status" with
          | "suite" ->
              let suite = Instr.read_name c "suite" in
              (Some suite, Instr.read_word c "status")
          | word -> (None, word)
        in
        let refused =
          match status with
          | "tested" -> None
          | "refused" -> Some (Instr.read_name c "refusal")
          | word -> Instr.parse_fail "unknown status %S" word
        in
        let sample = read_sample c in
        let test_digests =
          read_digests c [] (Instr.read_count c "test count")
        in
        let verdicts =
          read_records ~sampled:(Option.is_some sample) c empty
            (Instr.read_count c "record count")
        in
        Instr.finish c;
        Ok { verdicts; identity; suite; refused; sample; test_digests }
      with Instr.Parse_error reason -> Error (Corrupt { path; reason }))

let save ?identity ?suite ?refused ?sample ?(test_digests = []) path t =
  (match sample with
  | Some (percent, _) when not (percent > 0. && percent < 100.) ->
      invalid_arg
        "Windtrap_runtime.Verdicts.save: a sample percent is not above 0 and \
         below 100"
  | Some _ | None -> ());
  let test_digests =
    List.sort (fun (a, _) (b, _) -> compare_test a b) test_digests
  in
  let rec check = function
    | (a, _) :: ((b, _) :: _ as rest) ->
        if equal_test a b then
          invalid_arg "Windtrap_runtime.Verdicts.save: two digests of one test";
        check rest
    | [ _ ] | [] -> ()
  in
  check test_digests;
  if not (List.for_all (fun (_, d) -> Instr.is_digest d) test_digests) then
    invalid_arg
      "Windtrap_runtime.Verdicts.save: a test digest is not 32 lowercase \
       hexadecimal digits";
  let add_int b = function
    | None -> Buffer.add_string b "none"
    | Some n -> Printf.bprintf b "%d" n
  in
  let add_reason b = function
    | Deadline { seconds } -> Printf.bprintf b "deadline %h" seconds
    | Crashed { signal; status; how } ->
        Printf.bprintf b "crashed %a %a %a" add_int signal add_int status
          add_name how
    | Memory { mb } -> Printf.bprintf b "memory %d" mb
    | Flaky_kill { test; failure } ->
        Printf.bprintf b "flaky_kill %a %a" add_test test add_name failure
    | Other reason -> Printf.bprintf b "other %a" add_name reason
  in
  let add_verdict b = function
    | Unreached -> Buffer.add_string b "unreached"
    | Killed { by } ->
        Printf.bprintf b "killed %d" (List.length by);
        List.iter (Printf.bprintf b " %a" add_test) by
    | Killed_elsewhere { exe } ->
        Printf.bprintf b "killed_elsewhere %a" add_name exe
    | Not_evaluated -> Buffer.add_string b "not_evaluated"
    | Not_sampled -> Buffer.add_string b "not_sampled"
    | Outside_tests -> Buffer.add_string b "outside_tests"
    | Unknown reason -> Printf.bprintf b "unknown %a" add_reason reason
    | Survived s ->
        let tests = s.first :: s.others in
        Printf.bprintf b "survived %d" (List.length tests);
        List.iter (Printf.bprintf b " %a" add_test) tests
  in
  let add_previous b = function
    | None -> Buffer.add_string b "none"
    | Some `Killed -> Buffer.add_string b "was killed"
    | Some `Survived -> Buffer.add_string b "was survived"
    | Some `Not_evaluated -> Buffer.add_string b "was not_evaluated"
  in
  let b = Buffer.create 1024 in
  Instr.add_header format b identity;
  Option.iter (Printf.bprintf b "suite %a\n" add_name) suite;
  (match refused with
  | None -> Buffer.add_string b "tested\n"
  | Some reason -> Printf.bprintf b "refused %a\n" add_name reason);
  (match sample with
  | None -> Buffer.add_string b "sample none\n"
  | Some (percent, seed) ->
      Printf.bprintf b "sample %h %s\n" percent (seed_token seed));
  Printf.bprintf b "%d\n" (List.length test_digests);
  List.iter
    (fun (test, digest) -> Printf.bprintf b "%a %s\n" add_test test digest)
    test_digests;
  Printf.bprintf b "%d\n" (Id_map.cardinal t);
  Id_map.iter
    (fun (id : Mutate.id) r ->
      Printf.bprintf b "%a %d %d %d %d %a %a %a %a %a %a %d %d %s %s %s\n"
        add_name id.file id.line id.col r.end_line r.end_col add_name id.rewrite
        add_name r.before add_name r.after add_name
        (Option.value r.source_digest ~default:"")
        add_verdict r.verdict add_previous r.previous r.effort.retries
        r.effort.pass r.effort.settings
        (Option.value r.prefix ~default:"none")
        (if r.reused then "reused" else "fresh"))
    t;
  Instr.write_file path (Buffer.contents b)
