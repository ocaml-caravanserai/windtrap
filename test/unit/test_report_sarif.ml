(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Windtrap
module Sections = Windtrap.Private.Report_sections
module Sarif = Windtrap.Private.Report_sarif

let mutant ?source ?(line = 1) ?(col = 14) ?(end_line = line) ?(end_col = 19)
    ?(before = "a + b") ?(after = "a - b") () : Sections.mutant =
  {
    id = Printf.sprintf "lib/calc.ml:%d:%d:add" line col;
    file = "lib/calc.ml";
    line;
    col;
    end_line;
    end_col;
    before;
    after;
    source;
  }

let witness ?exe test = { Sections.test; loc = None; exe }

let survivor ?(m = mutant ()) witnesses =
  Sarif.Survived { Sections.mutant = m; witnesses }

let unknown ?(m = mutant ()) reason =
  Sarif.Unknown
    {
      Sections.mutant = m;
      reason;
      invocation = `Mirrors;
      counted_as_killed = false;
    }

let not_evaluated ?(m = mutant ()) failed =
  Sarif.Not_evaluated { Sections.mutant = m; invocation = `Mirrors; failed }

(* A JSON text, as RFC 8259 gives it, with the values that a document holds:
   objects, arrays, strings and non-negative integers. *)
let valid_json s =
  let n = String.length s in
  let rec ws i =
    if i < n && String.contains " \t\n\r" s.[i] then ws (i + 1) else i
  in
  let expect c i = if i < n && s.[i] = c then i + 1 else raise Exit in
  let rec string i =
    if i >= n then raise Exit
    else
      match s.[i] with
      | '"' -> i + 1
      | '\\' -> (
          if i + 1 >= n then raise Exit
          else
            match s.[i + 1] with
            | '"' | '\\' | '/' | 'b' | 'f' | 'n' | 'r' | 't' -> string (i + 2)
            | 'u' ->
                if
                  i + 6 <= n
                  && String.for_all
                       (function
                         | '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' -> true
                         | _ -> false)
                       (String.sub s (i + 2) 4)
                then string (i + 6)
                else raise Exit
            | _ -> raise Exit)
      | c when c < ' ' -> raise Exit
      | _ -> string (i + 1)
  in
  let number i =
    let j = ref i in
    while !j < n && '0' <= s.[!j] && s.[!j] <= '9' do
      incr j
    done;
    if !j = i then raise Exit else !j
  in
  let rec value i =
    let i = ws i in
    if i >= n then raise Exit
    else
      match s.[i] with
      | '{' -> members (ws (i + 1)) ~first:true
      | '[' -> elements (ws (i + 1)) ~first:true
      | '"' -> string (i + 1)
      | _ -> number i
  and members i ~first =
    if first && i < n && s.[i] = '}' then i + 1
    else
      let i = ws (string (expect '"' (ws i))) in
      let i = ws (value (expect ':' i)) in
      if i < n && s.[i] = ',' then members (i + 1) ~first:false
      else expect '}' i
  and elements i ~first =
    if first && i < n && s.[i] = ']' then i + 1
    else
      let i = ws (value i) in
      if i < n && s.[i] = ',' then elements (i + 1) ~first:false
      else expect ']' i
  in
  String.is_valid_utf_8 s
  && match ws (value 0) with i -> i = n | exception Exit -> false

(* Columns *)

let columns =
  [
    ("ASCII, the first byte", "let x = 1", 0, Some 1);
    ("ASCII, a byte inside", "let x = 1", 4, Some 5);
    ("ASCII, the end of the line", "let x = 1", 9, Some 10);
    ("the empty line", "", 0, Some 1);
    ("after a two-byte character", "(* \u{e9} *) x", 6, Some 6);
    ("inside a two-byte character", "\u{e9}x", 1, Some 1);
    ("after a three-byte character", "\u{20ac}x", 3, Some 2);
    ("inside a three-byte character", "a\u{20ac}x", 3, Some 2);
    ("the end of a line with several", "\u{e9}\u{20ac}\u{1d11e}", 9, Some 4);
    ("a malformed byte is one code point", "\xffx", 1, Some 2);
    ("an offset above the line", "abc", 4, None);
    ("a negative offset", "abc", -1, None);
  ]

let source = "let add a b = a + b\nlet s = \"\u{e9}\u{20ac}\" ^ x ^ y\n"

let regions =
  [
    ( "without a source, the lines only",
      mutant (),
      [ ("startLine", 1); ("endLine", 1) ] );
    ( "an ASCII line",
      mutant ~source (),
      [
        ("startLine", 1); ("startColumn", 15); ("endLine", 1); ("endColumn", 20);
      ] );
    ( "a line with non-ASCII characters before the mutant",
      mutant ~source ~line:2 ~col:18 ~end_col:23 ~before:"x ^ y" (),
      [
        ("startLine", 2); ("startColumn", 16); ("endLine", 2); ("endColumn", 21);
      ] );
    ( "a span over two lines",
      mutant ~source ~line:1 ~col:14 ~end_line:2 ~end_col:7 (),
      [
        ("startLine", 1); ("startColumn", 15); ("endLine", 2); ("endColumn", 8);
      ] );
    ( "a line that the source does not have",
      mutant ~source ~line:3 (),
      [ ("startLine", 3); ("endLine", 3) ] );
    ( "a column after the end of its line",
      mutant ~source ~end_col:40 (),
      [ ("startLine", 1); ("endLine", 1) ] );
  ]

(* Messages *)

let messages =
  [
    ( "a survivor with one test",
      survivor [ witness "t/one" ],
      "mutant survived: a + b \u{2192} a - b; 1 test ran this line and did not \
       fail" );
    ( "a survivor with several tests",
      survivor [ witness "t/one"; witness "t/two" ],
      "mutant survived: a + b \u{2192} a - b; 2 tests ran this line and none \
       failed" );
    ( "a survivor with tests in two executables",
      survivor
        [
          witness ~exe:"a.exe" "t/one";
          witness ~exe:"a.exe" "t/two";
          witness ~exe:"b.exe" "t/three";
        ],
      "mutant survived: a + b \u{2192} a - b; 3 tests in 2 executables ran \
       this line and none failed" );
    ( "a survivor with no reaching test",
      survivor [],
      "mutant survived: a + b \u{2192} a - b" );
    ( "an unknown mutant",
      unknown "t.exe: its run passed its deadline of 1.0s",
      "mutant unknown: a + b \u{2192} a - b; t.exe: its run passed its \
       deadline of 1.0s" );
    ( "a mutant that was not evaluated",
      not_evaluated None,
      "mutant not evaluated: a + b \u{2192} a - b" );
    ( "a mutant that was not evaluated, with a failure",
      not_evaluated (Some "t/one"),
      "mutant not evaluated: a + b \u{2192} a - b; a failure that the mutant \
       did not cause: t/one" );
  ]

(* URIs *)

let uris =
  [
    ("a plain path", "lib/calc.ml", "lib/calc.ml");
    ("the unreserved characters", "a-b.c_d~e/F9", "a-b.c_d~e/F9");
    ("a space", "my lib/a.ml", "my%20lib/a.ml");
    ("a percent sign", "100%.ml", "100%25.ml");
    ("a non-ASCII character", "\u{e9}.ml", "%C3%A9.ml");
    ("reserved characters", "a:b?c#d[e]@f", "a%3Ab%3Fc%23d%5Be%5D%40f");
    ("a backslash", "lib\\a.ml", "lib%5Ca.ml");
  ]

(* The document *)

let results =
  [
    { Sarif.rewrite = "sub"; verdict = survivor [ witness "t/one" ] };
    { rewrite = "add"; verdict = unknown "t.exe: its run crashed" };
    {
      rewrite = "sub";
      verdict = not_evaluated ~m:(mutant ~source ~line:2 ~col:18 ()) None;
    };
  ]

let expected_document =
  {|{ "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    { "tool": {
        "driver": {
          "name": "windtrap",
          "informationUri": "https://github.com/invariant-hq/windtrap",
          "version": "1.2.3",
          "rules": [
            { "id": "add",
              "shortDescription": { "text": "mutant of the rewrite add" } },
            { "id": "sub",
              "shortDescription": { "text": "mutant of the rewrite sub" } } ] } },
      "columnKind": "unicodeCodePoints",
      "results": [
        { "ruleId": "sub", "ruleIndex": 1, "level": "warning",
          "message": { "text": "mutant survived: a + b → a - b; 1 test ran this line and did not fail" },
          "locations": [
            { "physicalLocation": {
                "artifactLocation": { "uri": "lib/calc.ml" },
                "region": { "startLine": 1, "endLine": 1 } } } ] },
        { "ruleId": "add", "ruleIndex": 0, "level": "note",
          "message": { "text": "mutant unknown: a + b → a - b; t.exe: its run crashed" },
          "locations": [
            { "physicalLocation": {
                "artifactLocation": { "uri": "lib/calc.ml" },
                "region": { "startLine": 1, "endLine": 1 } } } ] },
        { "ruleId": "sub", "ruleIndex": 1, "level": "note",
          "message": { "text": "mutant not evaluated: a + b → a - b" },
          "locations": [
            { "physicalLocation": {
                "artifactLocation": { "uri": "lib/calc.ml" },
                "region": { "startLine": 2, "startColumn": 16, "endLine": 2, "endColumn": 17 } } } ] } ] } ] }
|}

let document () =
  let doc = Sarif.document ~version:"1.2.3" results in
  is_true ~msg:"valid JSON" (valid_json doc);
  equal string expected_document doc

let no_version () =
  let doc = Sarif.document results in
  equal string
    (String.concat "\n"
       (List.filter
          (fun l -> String.trim l <> {|"version": "1.2.3",|})
          (String.split_on_char '\n' expected_document)))
    doc

let empty () =
  let doc = Sarif.document [] in
  is_true ~msg:"valid JSON" (valid_json doc);
  is_true ~msg:"no rule"
    (Option.is_some
       (Windtrap.Private.Text.first_occurrence ~pattern:{|"rules": [ ]|} doc));
  is_true ~msg:"no result"
    (Option.is_some
       (Windtrap.Private.Text.first_occurrence ~pattern:{|"results": [ ]|} doc))

(* Strings that JSON escapes stay valid in each field. *)
let escapes () =
  let hard = "a \"q\" \\ \t\001\xff" in
  let m =
    {
      (mutant ~source:hard ~before:hard ~after:hard ()) with
      file = "dir/" ^ hard;
    }
  in
  let doc =
    Sarif.document ~version:hard
      [
        { Sarif.rewrite = hard; verdict = survivor ~m [ witness hard ] };
        { rewrite = "x"; verdict = unknown ~m hard };
        { rewrite = "x"; verdict = not_evaluated ~m (Some hard) };
      ]
  in
  is_true ~msg:"valid JSON" (valid_json doc)

let validator () =
  List.iter
    (fun (text, valid) -> equal ~msg:text bool valid (valid_json text))
    [
      ({|{ "a": [1, "xé"] }|}, true);
      ({|{ "a": [ ] }|}, true);
      ({|{ "a": 1, }|}, false);
      ({|[1 2]|}, false);
      ("\"a\tb\"", false);
      ({|{ "a": 1 } x|}, false);
    ]

let () =
  exit
    (run "report_sarif"
       [
         group "Locations"
           [
             cases "column"
               ~id:(fun (n, _, _, _) -> n)
               columns
               (fun (_, line, offset, e) ->
                 equal (option int) e (Sarif.column line offset));
             cases "region"
               ~id:(fun (n, _, _) -> n)
               regions
               (fun (_, m, e) ->
                 equal (list (pair string int)) e (Sarif.region m));
             cases "uri"
               ~id:(fun (n, _, _) -> n)
               uris
               (fun (_, path, e) -> equal string e (Sarif.uri path));
           ];
         group "Messages"
           [
             cases "message"
               ~id:(fun (n, _, _) -> n)
               messages
               (fun (_, v, e) -> equal string e (Sarif.message v));
           ];
         group "Document"
           [
             test
               "the rules are sorted, and each result gives the index of its \
                rule"
               document;
             test "without a version, the driver has no version" no_version;
             test "with no result, the arrays are empty" empty;
             test "the document is valid JSON with strings that need escapes"
               escapes;
             test "the JSON check refuses a text that is not JSON" validator;
           ];
       ])
