(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

module Sections = Windtrap.Private.Report_sections
module Json = Windtrap.Private.Json
module Text = Windtrap.Private.Text

let strf = Printf.sprintf

(* Results *)

type verdict =
  | Survived of Sections.survivor
  | Unknown of Sections.unknown
  | Not_evaluated of Sections.not_evaluated

type result = { rewrite : string; verdict : verdict }

let change (m : Sections.mutant) = strf "%s \u{2192} %s" m.before m.after

let message = function
  | Survived s -> (
      let head = "mutant survived: " ^ change s.mutant in
      match Sections.reaching_sentence s.witnesses with
      | Some tests -> strf "%s; %s" head tests
      | None -> head)
  | Unknown u -> strf "mutant unknown: %s; %s" (change u.mutant) u.reason
  | Not_evaluated n -> (
      let head = "mutant not evaluated: " ^ change n.mutant in
      match n.failed with
      | Some failed ->
          strf "%s; a failure that the mutant did not cause: %s" head failed
      | None -> head)

let mutant = function
  | Survived { mutant; _ } | Unknown { mutant; _ } | Not_evaluated { mutant; _ }
    ->
      mutant

(* Locations *)

let column line offset =
  if offset < 0 || offset > String.length line then None
  else
    let rec count i n =
      if i >= offset then n
      else
        let next =
          i + Uchar.utf_decode_length (String.get_utf_8_uchar line i)
        in
        if next > offset then n else count next (n + 1)
    in
    Some (1 + count 0 0)

let region (m : Sections.mutant) =
  let lines = [ ("startLine", m.line); ("endLine", m.end_line) ] in
  match Option.map (fun s -> Array.of_list (Text.split_lines s)) m.source with
  | None -> lines
  | Some source -> (
      let column line offset =
        if 1 <= line && line <= Array.length source then
          column source.(line - 1) offset
        else None
      in
      match (column m.line m.col, column m.end_line m.end_col) with
      | Some start, Some end_ ->
          [
            ("startLine", m.line);
            ("startColumn", start);
            ("endLine", m.end_line);
            ("endColumn", end_);
          ]
      | _ -> lines)

let unreserved = function
  | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '-' | '.' | '_' | '~' | '/' -> true
  | _ -> false

let uri path =
  let b = Buffer.create (String.length path) in
  String.iter
    (fun c ->
      if unreserved c then Buffer.add_char b c
      else Buffer.add_string b (strf "%%%02X" (Char.code c)))
    path;
  Buffer.contents b

(* The document *)

let information_uri = "https://github.com/invariant-hq/windtrap"

let document ?version results =
  let string = Json.string in
  let rules =
    List.sort_uniq String.compare (List.map (fun r -> r.rewrite) results)
  in
  let index rewrite =
    let rec find i = function
      | r :: _ when r = rewrite -> i
      | _ :: rest -> find (i + 1) rest
      | [] -> assert false
    in
    find 0 rules
  in
  let rule id =
    strf
      "\n\
      \            { \"id\": %s,\n\
      \              \"shortDescription\": { \"text\": %s } }"
      (string id)
      (string ("mutant of the rewrite " ^ id))
  in
  let result r =
    let m = mutant r.verdict in
    let level = match r.verdict with Survived _ -> "warning" | _ -> "note" in
    strf
      "\n\
      \        { \"ruleId\": %s, \"ruleIndex\": %d, \"level\": %s,\n\
      \          \"message\": { \"text\": %s },\n\
      \          \"locations\": [\n\
      \            { \"physicalLocation\": {\n\
      \                \"artifactLocation\": { \"uri\": %s },\n\
      \                \"region\": { %s } } } ] }"
      (string r.rewrite) (index r.rewrite) (string level)
      (string (message r.verdict))
      (string (uri m.file))
      (String.concat ", "
         (List.map (fun (k, v) -> strf "%s: %d" (string k) v) (region m)))
  in
  let version =
    match version with
    | Some v -> strf "\n          \"version\": %s," (string v)
    | None -> ""
  in
  strf
    "{ \"$schema\": \"https://json.schemastore.org/sarif-2.1.0.json\",\n\
    \  \"version\": \"2.1.0\",\n\
    \  \"runs\": [\n\
    \    { \"tool\": {\n\
    \        \"driver\": {\n\
    \          \"name\": \"windtrap\",\n\
    \          \"informationUri\": %s,%s\n\
    \          \"rules\": [%s ] } },\n\
    \      \"columnKind\": \"unicodeCodePoints\",\n\
    \      \"results\": [%s ] } ] }\n"
    (string information_uri) version
    (String.concat "," (List.map rule rules))
    (String.concat "," (List.map result results))
