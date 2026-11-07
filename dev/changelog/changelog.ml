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

let heading prefix line =
  let n = String.length prefix in
  if String.length line > n && String.starts_with ~prefix line then
    Some (String.sub line n (String.length line - n))
  else None

let is_blank line = String.trim line = ""

let rec drop_blank = function
  | l :: rest when is_blank l -> drop_blank rest
  | lines -> lines

let trim lines = List.rev (drop_blank (List.rev (drop_blank lines)))

(* Gives the lines before the first area heading, and each area with its
   heading's line number and its lines. *)
let split ~fragment ~path ~first lines =
  let pre = ref [] and sections = ref [] in
  List.iteri
    (fun i line ->
      let n = first + i in
      let unknown area =
        error path n "unknown area %S; the areas are: %s" area
          (String.concat ", " areas)
      in
      match (heading "### " line, !sections) with
      | Some area, _ when List.mem area areas ->
          sections := (area, n, ref []) :: !sections
      | Some area, _ :: _ -> unknown area
      | Some area, [] when fragment -> unknown area
      | None, [] when fragment && not (is_blank line) ->
          error path n "a line before the first area heading"
      | _, [] -> pre := line :: !pre
      | None, (_, _, body) :: _ ->
          if fragment && String.starts_with ~prefix:"#" line then
            error path n "a heading that is not an area heading";
          body := line :: !body)
    lines;
  ( List.rev !pre,
    List.rev_map
      (fun (area, n, body) -> (area, n, trim (List.rev !body)))
      !sections )

let parse_fragment path =
  let _, sections = split ~fragment:true ~path ~first:1 (read_lines path) in
  if sections = [] then error path 1 "no area heading";
  List.iter
    (fun (area, n, body) ->
      match body with
      | [] -> error path n "area %S has no line" area
      | l :: _ when not (String.starts_with ~prefix:"- " l) ->
          error path n "the first line of area %S does not start with \"- \""
            area
      | _ -> ())
    sections;
  List.map (fun (area, _, body) -> (area, body)) sections

let fragments dir =
  Sys.readdir dir |> Array.to_list
  |> List.filter (fun f -> Filename.check_suffix f ".md")
  |> List.sort compare
  |> List.map (fun f -> dir ^ "/" ^ f)

let join changes dir =
  let paths = fragments dir in
  let parsed = List.map parse_fragment paths in
  if parsed <> [] then begin
    let lines = Array.of_list (read_lines changes) in
    let len = Array.length lines in
    let rec find_h2 i =
      if i >= len || heading "## " lines.(i) <> None then i else find_h2 (i + 1)
    in
    let top = find_h2 0 in
    let start, stop =
      if top < len && lines.(top) = "## Unreleased" then (top, find_h2 (top + 1))
      else (top, top)
    in
    let sub a b = Array.to_list (Array.sub lines a (b - a)) in
    let entry = if stop > start then sub (start + 1) stop else [] in
    let pre, sections =
      split ~fragment:false ~path:changes ~first:(start + 2) entry
    in
    let all = List.map (fun (a, _, b) -> (a, b)) sections :: parsed in
    let body area =
      List.concat_map
        (List.concat_map (fun (a, b) -> if a = area then b else []))
        all
    in
    let pre = match trim pre with [] -> [] | l -> l @ [ "" ] in
    let areas =
      List.concat_map
        (fun area ->
          match body area with
          | [] -> []
          | b -> ("### " ^ area) :: "" :: (b @ [ "" ]))
        areas
    in
    let out =
      sub 0 start @ ("## Unreleased" :: "" :: pre) @ areas @ sub stop len
    in
    Out_channel.with_open_bin changes (fun oc ->
        List.iter (fun l -> output_string oc (l ^ "\n")) out);
    List.iter Sys.remove paths
  end

let () =
  try
    match List.tl (Array.to_list Sys.argv) with
    | "check" :: paths -> List.iter (fun p -> ignore (parse_fragment p)) paths
    | [ "join"; changes; dir ] -> join changes dir
    | _ ->
        prerr_endline
          "usage: changelog check FRAGMENT...\n\
          \       changelog join CHANGES DIR";
        exit 2
  with Error msg | Sys_error msg ->
    prerr_endline msg;
    exit 1
