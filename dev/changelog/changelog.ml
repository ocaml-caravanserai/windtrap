(* Checks changelog fragments and joins them into CHANGES.md
   (doc/dev/changelog.md). *)

let areas =
  [
    "Declaring tests";
    "Assertions";
    "Property testing";
    "Stateful testing";
    "Baselines and expect tests";
    "Resources and process state";
    "Running tests";
    "Coverage";
    "Mutation testing";
    "Packages and libraries";
  ]

exception Error of string

let error path line fmt =
  Printf.ksprintf
    (fun s -> raise (Error (Printf.sprintf "%s:%d: %s" path line s)))
    fmt

let read_lines path =
  let lines =
    String.split_on_char '\n'
      (In_channel.with_open_bin path In_channel.input_all)
  in
  match List.rev lines with "" :: rest -> List.rev rest | _ -> lines

(* A line without the indent of at most three spaces that CommonMark
   permits before a heading or a fence. *)
let unindent line =
  let n = String.length line in
  let rec go i = if i < 3 && i < n && line.[i] = ' ' then go (i + 1) else i in
  let i = go 0 in
  String.sub line i (n - i)

let is_heading line =
  let s = unindent line in
  let n = String.length s in
  let rec hashes i = if i < n && s.[i] = '#' then hashes (i + 1) else i in
  let h = hashes 0 in
  h >= 1 && h <= 6 && (h = n || s.[h] = ' ' || s.[h] = '\t')

let fence line =
  let s = unindent line in
  if String.starts_with ~prefix:"```" s then Some '`'
  else if String.starts_with ~prefix:"~~~" s then Some '~'
  else None

let is_blank line = String.trim line = ""

let rec drop_blank = function
  | l :: rest when is_blank l -> drop_blank rest
  | lines -> lines

(* Each area of a fragment with its lines, in the order of the fragment. *)
let parse path =
  let sections = ref [] and open_fence = ref None in
  List.iteri
    (fun i line ->
      let n = i + 1 in
      match (!open_fence, !sections) with
      | Some (c, _), (_, _, body) :: _ ->
          if fence line = Some c then open_fence := None;
          body := line :: !body
      | _ when String.starts_with ~prefix:"### " line ->
          let area = String.sub line 4 (String.length line - 4) in
          if not (List.mem area areas) then
            error path n "unknown area %S (doc/dev/changelog.md lists them)"
              area;
          sections := (area, n, ref []) :: !sections
      | _ when is_heading line ->
          error path n "a heading that is not an area heading"
      | _, [] ->
          if not (is_blank line) then
            error path n "the fragment does not start with an area heading"
      | _, (_, _, body) :: _ ->
          Option.iter (fun c -> open_fence := Some (c, n)) (fence line);
          body := line :: !body)
    (read_lines path);
  Option.iter
    (fun (_, n) -> error path n "a code block that does not end")
    !open_fence;
  if !sections = [] then
    error path 1 "the fragment does not start with an area heading";
  List.rev_map
    (fun (area, n, body) ->
      let body =
        List.rev (drop_blank (List.rev (drop_blank (List.rev !body))))
      in
      (match body with
      | l :: _ when String.starts_with ~prefix:"- " l -> ()
      | _ -> error path n "area %S does not start with a line \"- \"" area);
      (area, body))
    !sections

(* The files of [dir] whose names end with .md and do not start with a dot:
   the files that dune copies into _build for the check. *)
let fragments dir =
  Sys.readdir dir |> Array.to_list
  |> List.filter (fun f ->
      Filename.check_suffix f ".md"
      && f.[0] <> '.'
      && not (Sys.is_directory (Filename.concat dir f)))
  |> List.sort compare
  |> List.map (fun f -> dir ^ "/" ^ f)

let join changes dir =
  let paths = fragments dir in
  let parsed = List.map parse paths in
  let lines = read_lines changes in
  if List.mem "## Unreleased" lines then
    raise
      (Error (changes ^ ": it has a \"## Unreleased\" entry; rename it first"));
  if parsed <> [] then begin
    let lines_of area =
      List.concat_map
        (List.concat_map (fun (a, b) -> if a = area then b else []))
        parsed
    in
    let entry =
      List.concat_map
        (fun area ->
          match lines_of area with
          | [] -> []
          | body -> ("### " ^ area) :: "" :: (body @ [ "" ]))
        areas
    in
    let rec insert = function
      | l :: rest when not (String.starts_with ~prefix:"## " l) ->
          l :: insert rest
      | rest -> ("## Unreleased" :: "" :: entry) @ rest
    in
    Out_channel.with_open_bin changes (fun oc ->
        List.iter (fun l -> output_string oc (l ^ "\n")) (insert lines));
    List.iter Sys.remove paths
  end

let () =
  try
    match List.tl (Array.to_list Sys.argv) with
    | [ "check"; dir ] -> List.iter (fun p -> ignore (parse p)) (fragments dir)
    | [ "join"; changes; dir ] -> join changes dir
    | _ ->
        prerr_endline
          "usage: changelog check DIR\n       changelog join CHANGES DIR";
        exit 2
  with Error msg | Sys_error msg ->
    prerr_endline msg;
    exit 1
