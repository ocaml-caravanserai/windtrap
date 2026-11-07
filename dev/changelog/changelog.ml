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

let is_blank line = String.trim line = ""

let rec drop_blank = function
  | l :: rest when is_blank l -> drop_blank rest
  | lines -> lines

(* Each area of a fragment with its lines, in the order of the fragment. *)
let parse path =
  let sections = ref [] in
  List.iteri
    (fun i line ->
      let n = i + 1 in
      if String.starts_with ~prefix:"### " line then begin
        let area = String.sub line 4 (String.length line - 4) in
        if not (List.mem area areas) then
          error path n "unknown area %S (doc/dev/changelog.md lists them)" area;
        sections := (area, n, ref []) :: !sections
      end
      else
        match !sections with
        | [] ->
            if not (is_blank line) then
              error path n "the fragment does not start with an area heading"
        | (_, _, body) :: _ ->
            if
              not
                (is_blank line
                || String.starts_with ~prefix:"- " line
                || String.starts_with ~prefix:"  " line)
            then
              error path n
                "a line that does not start with \"- \" or two spaces";
            body := (if is_blank line then "" else line) :: !body)
    (read_lines path);
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

(* The files of [dir] whose names end with .md and do not start with a
   dot. *)
let fragments dir =
  Sys.readdir dir |> Array.to_list
  |> List.filter (fun f -> f.[0] <> '.')
  |> List.sort compare
  |> List.filter_map (fun f ->
      let path = dir ^ "/" ^ f in
      if Sys.is_directory path then
        raise (Error (path ^ ": a directory, not a fragment"))
      else if Filename.check_suffix f ".md" then Some path
      else None)

let join changes dir =
  let paths = fragments dir in
  let parsed = List.map parse paths in
  let lines = read_lines changes in
  if List.mem "## Unreleased" lines then
    raise (Error (changes ^ " has a \"## Unreleased\" entry. Rename it first."));
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
