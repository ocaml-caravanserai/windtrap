(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** The SARIF 2.1.0 document of [windtrap mutants --sarif].

    {!document} writes the document. [bin/mutate_cmd.mli] states which mutants
    give a result. The other functions are the parts of a result, for the tests.
*)

module Sections = Windtrap.Private.Report_sections

(** {1:results Results} *)

type verdict =
  | Survived of Sections.survivor
  | Unknown of Sections.unknown
  | Not_evaluated of Sections.not_evaluated
      (** The types for the verdicts that give a result. *)

type result = {
  rewrite : string;  (** The rewrite of the mutant. *)
  verdict : verdict;
}
(** The type for a mutant that gives a result. *)

val message : verdict -> string
(** [message v] is the text of the message of [v]:
    - [mutant survived: <before> → <after>; <tests>] for a survivor, where
      [<tests>] is the {!Sections.reaching_sentence} of its reaching tests. With
      no reaching test, the text stops after [<after>].
    - [mutant unknown: <before> → <after>; <reason>] for an unknown mutant, with
      its reason as the report gives it.
    - [mutant not evaluated: <before> → <after>] for a mutant that a child did
      not evaluate. When the mutant has a [failed], the text continues with
      [; a failure that the mutant did not cause: <failed>]. *)

(** {1:locations Locations} *)

val column : string -> int -> int option
(** [column line offset] is the one-based SARIF column, in code points, of the
    zero-based byte [offset] of [line]: one more than the number of code points
    that end at or before [offset]. A code point that holds [offset] is not
    counted. An [offset] of the length of [line] is the column after its last
    code point. It is [None] when [offset] is negative or above the length of
    [line]. A malformed sequence counts as one code point, as
    [String.get_utf_8_uchar] decodes it. *)

val region : Sections.mutant -> (string * int) list
(** [region m] is the fields of the region of [m], in this order: ["startLine"],
    ["startColumn"], ["endLine"] and ["endColumn"]. The columns are those of
    {!column} on the lines of the source of [m], split by
    {!Windtrap.Private.Text.split_lines}. Without the source, or when a line or
    a column does not exist in it, the region has the two lines only. *)

val uri : string -> string
(** [uri path] is [path] as a relative URI reference: each byte that is not an
    unreserved character of RFC 3986 and not [/] becomes [%XX], in uppercase
    hexadecimal. *)

(** {1:document The document} *)

val information_uri : string
(** [information_uri] is the home page of windtrap. *)

val document : ?version:string -> result list -> string
(** [document ?version results] is the SARIF 2.1.0 document of [results], in
    this order, on several lines and with a final newline. Its one run has the
    driver [windtrap], with {!information_uri}, [version] when it is given, and
    one rule for each rewrite of [results], sorted with [String.compare]. The id
    of a rule is the rewrite and its short description is
    [mutant of the rewrite <rewrite>]. The run gives its columns in
    [unicodeCodePoints].

    Each result has the id and the index of its rule, the level [warning] for a
    survivor and [note] for the other verdicts, the {!message}, and one physical
    location. That location has the {!uri} of the file of the mutant and its
    {!region}. {!Windtrap.Private.Json.string} writes each string. *)
