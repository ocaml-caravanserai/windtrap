(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Mutation verdicts: what a run made of each mutant, and the [.mutants] file
    that carries the verdicts of one suite of an executable to the merge.

    The mutation loop writes one verdict file for each suite of a test
    executable. [windtrap mutants] loads the files of a project and combines
    them with {!merge}, under which a mutant that is killed anywhere is killed.
    Nothing here runs when the module loads or when the process exits. *)

(** {1:verdicts Verdicts}

    A verdict is one of seven cases, and never a boolean or an exit code. What a
    run could not decide is {!Unknown}, which outranks a survivor, so a mutant
    that no run judged never reads as survived. *)

type reaching_test = string list
(** The type for a test that evaluated a mutant, by its path: the names of its
    groups, the outermost first, and then its own, as [["arithmetic"; "adds"]].
*)

(** The type for the reasons of an {!Unknown} verdict. *)
type unknown_reason =
  | Deadline of { seconds : float }
      (** The run passed its deadline of [seconds]. *)
  | Crashed of { signal : int option; status : int option; how : string }
      (** The worker of the run ended first: by a signal, with an exit status,
          by an exit that code under test called, or before it served. [signal]
          is the OCaml number of the signal that killed or stopped it, and
          [status] is its exit status. The two are [None] when no status was
          read. [how] is the phrase of the end, such as
          ["was killed by SIGSEGV"]. *)
  | Memory of { mb : int }  (** The run passed its memory limit of [mb] MB. *)
  | Flaky_kill of { test : reaching_test; failure : string }
      (** The check of a kill found that the killing test [test] also fails with
          no mutant. [failure] is the phrase of the failure. *)
  | Other of string
      (** Each other reason, as the text says: a red dry run, a suite that is
          not deterministic, a selection that narrows the suite, or a refused
          suite. *)

val reason_text : unknown_reason -> string
(** [reason_text r] is the text of [r] that the reports print, such as
    ["its run passed its deadline of 2.5s"]. *)

(** The type for verdicts. A survivor always names a reaching test, because a
    mutant that no test reached is {!Outside_tests} or {!Unreached}. *)
type verdict =
  | Killed of { by : reaching_test list }
      (** In the run that armed the mutant, a reaching test failed in or after
          the test that first evaluated the armed site. Or a fixture release
          failed, and the run evaluated the site at any time. [by] is the
          killing tests, sorted and without duplicates: the first such failing
          test of each run that killed the mutant. It is [[]] when a kill names
          no test, as for a kill by a fixture release. *)
  | Killed_elsewhere of { exe : string }
      (** No run of this suite armed the mutant, because the verdict file of
          another suite gave it {!Killed}, with the source digest, the
          renderings and the extent of this run. [exe] is the identity on that
          file ({!Instr.type-identity}), and it is not [""]. Only a loop under
          [--skip-killed] gives it. *)
  | Unknown of unknown_reason
      (** No verdict, and the reason tells why: the run that armed the mutant
          ended before its tests did, by a crash, an exit, its deadline or its
          memory limit, or the executable could not be mutation-tested, as when
          its dry run is red, its suite is not deterministic or its selection
          narrows it. *)
  | Survived of { first : reaching_test; others : reaching_test list }
      (** The armed site was evaluated, no reaching test failed after its first
          evaluation, and no fixture release failed. A test that failed before
          the first evaluation does not count. [first] and [others] are the
          reaching tests, sorted and without duplicates, and [first] is the
          first. *)
  | Not_evaluated
      (** The armed site was not evaluated. The dry run evaluated the site and
          the child did not, as when the dry run cached the result of the site
          in a table or a forced lazy value. A test or a fixture release that
          failed in the child did not fail because of the mutant, and does not
          kill it. *)
  | Outside_tests
      (** No test reached the site, and the dry run evaluated it outside every
          test, at module initialization or in a fixture release. The loop
          starts no worker for the mutant. *)
  | Unreached
      (** No test reached the site, and the dry run did not evaluate it outside
          every test either. The loop starts no worker for the mutant. *)

val survived : reaching_test list -> verdict
(** [survived ts] is the {!Survived} verdict whose reaching tests are [ts],
    sorted and without duplicates. Raises [Invalid_argument] if [ts] is empty.
*)

val killed : reaching_test list -> verdict
(** [killed ts] is the {!Killed} verdict whose killing tests are [ts], sorted
    and without duplicates. *)

type outcome = [ `Killed | `Survived | `Not_evaluated ]
(** The type for the outcomes: the verdicts that the tests of a suite give to a
    mutant that they run, without their details. *)

val outcome : verdict -> outcome option
(** [outcome v] is [Some `Killed] for {!Killed}, [Some `Survived] for
    {!Survived}, [Some `Not_evaluated] for {!Not_evaluated}, and [None] for the
    other verdicts. A {!Killed_elsewhere} verdict is no outcome, because no test
    of the suite ran the mutant. *)

(** {1:collections Collections} *)

type effort = {
  retries : int;
      (** The [--mutate-retry] count of the run that gave the verdict. *)
  pass : int;
      (** The pass of that run that gave the verdict: [1] for the first run of
          the mutant, and [k] for its [k - 1]-th retry. *)
  settings : string;
      (** The lowercase hexadecimal MD5 of the settings of that run that change
          what a test does ([Mutate_loop.settings]). *)
}
(** The type for what a run did to give a verdict. A later run reuses a verdict
    only when it asks for no more ({!effort_covers}). *)

val effort_covers :
  [ `Killed | `Survived ] -> judged:effort -> asked:effort -> bool
(** [effort_covers kind ~judged ~asked] is [true] when a verdict of [kind] that
    a run of the effort [judged] gave holds for a run of the effort [asked]. The
    two must have the same [settings]. For a kill, [asked.retries] is [0] or
    [judged.retries] is above [0], because only a run with retries checks a
    kill, and [judged.pass - 1] is at most [asked.retries], because a run with
    fewer retries does not run that pass. For a survivor, [asked.retries] is at
    most [judged.retries]. [asked.pass] is not read. *)

val prefix_digest : reaching_test list -> string
(** [prefix_digest paths] is the lowercase hexadecimal MD5 of an injective
    spelling of [paths], in order: the tests of a job up to and with its killing
    test. *)

val through : reaching_test -> reaching_test list -> reaching_test list
(** [through test paths] is [paths] up to and with the first [test], or [paths]
    when [test] is not in it. *)

type record = {
  id : Mutate.id;  (** The identifier of the mutant. *)
  end_line : int;  (** The [end_line] of its site ({!Mutate.type-site}). *)
  end_col : int;  (** The [end_col] of its site. *)
  before : string;  (** The source text of the original expression. *)
  after : string;  (** The source text of the armed expression. *)
  source_digest : string option;
      (** The {!Mutate.mutant.source_digest} of the mutant: the lowercase
          hexadecimal MD5 of the source file that the instrumenter read, or
          [None]. A loop under [--skip-killed] compares it with the digest of
          the mutant of its own executable. *)
  verdict : verdict;  (** What the run made of the mutant. *)
  previous : outcome option;
      (** The last outcome that the suite gave to the same mutant before this
          run, or [None]. {!with_previous} sets it. *)
  effort : effort;
      (** The effort of the run that gave [verdict]. For a reused verdict it is
          the effort of the run that tested the mutant. *)
  prefix : string option;
      (** For a {!Killed} that names a test, the {!prefix_digest} of the tests
          of its job up to and with the killing test, when it is known. {!add}
          drops it for every other verdict. *)
  reused : bool;
      (** [true] when a run took [verdict] from the verdict file of the last run
          ({!reuse}) and did not test the mutant. {!reuse} gives only a
          {!Killed} that names one test and a {!Survived}. *)
}
(** The type for the record of one mutant. A record is self-describing: it
    carries the two renderings and the extent that a report draws the mutant
    with, so a report needs no catalogue and outlives the executable that
    produced it. *)

val record_of_mutant :
  effort:effort ->
  ?prefix:reaching_test list ->
  Mutate.mutant ->
  verdict ->
  record
(** [record_of_mutant ~effort ?prefix m v] is the record of [m] with the verdict
    [v], the effort [effort], no previous outcome and no mark. Its prefix is the
    {!prefix_digest} of [prefix], or [None] without [prefix]. {!add} drops the
    prefix of a verdict that is not a {!Killed} that names a test. [m.dismissed]
    is dropped. *)

val changed : record -> (outcome * outcome) option
(** [changed r] is [Some (was, is)] when [r.previous] is [Some was],
    {!val-outcome} of [r.verdict] is [Some is], [was] is not [is], and [r] is
    not reused. It is [None] if not. A reused verdict is no change, because this
    run did not test the mutant. *)

type t
(** The type for verdict collections: finite maps from {!Mutate.type-id} to
    {!type-record}, ordered by {!Mutate.compare_id}. They are immutable. *)

val empty : t
(** [empty] is the collection with no record. *)

val add : t -> record -> t
(** [add t r] is [t] with [r] recorded. A {!Survived} or {!Killed} verdict is
    sorted on its way in, and the prefix of a verdict that is not a {!Killed}
    that names a test is dropped. When [t] already holds a record under [r.id],
    the smaller [(before, after, end_line, end_col, source_digest)] in
    lexicographic order is kept, and the two verdicts combine into the verdict
    of a mutant that one executable saw one way and another the other way. It is
    {!Killed} if either is, with the killing tests of both. Otherwise it is
    {!Killed_elsewhere} if either is, with the smaller [exe] in [String.compare]
    order when both are. Otherwise it is {!Unknown} if either is, with the
    reason whose {!reason_text} is smaller in [String.compare] order when both
    are, and the smaller reason in [compare] order for two equal texts, then
    {!Not_evaluated} if either is, then {!Survived} with the reaching tests of
    both if either is, then {!Outside_tests} if either is, and {!Unreached} if
    both are. The two previous outcomes combine in the same order, and a missing
    one leaves the other unchanged. The effort and the prefix are the smallest
    pair, in [compare] order, of the records whose verdict has the higher rank
    in this order, or of the two records when the two ranks are equal. The
    result is reused when each of these records is reused.

    [add] checks nothing of [r.id], of the end, of [r.source_digest], of the
    [exe] of a {!Killed_elsewhere}, of [r.effort], of [r.prefix] or of the mark.
    It accepts an empty [file], a [line] below [1], a negative [col], an end
    before the start, a [rewrite] outside {!Mutate.rewrites}, a digest that is
    not 32 lowercase hexadecimal digits, an empty [exe] and a record that
    {!load} refuses, and {!load} then refuses the file that {!save} writes for
    the collection. *)

val records : t -> record list
(** [records t] is the records of [t], ordered by {!Mutate.compare_id}. *)

val merge : t -> t -> t
(** [merge a b] is the union of [a] and [b], where two records that share an
    identifier are combined as {!add} does. [merge] is commutative, associative
    and idempotent, {!empty} is its unit, and an {!Unreached} verdict leaves the
    verdict it is combined with unchanged, so merging any number of files in any
    order gives one answer. The previous outcome, the effort and the prefix of a
    merged record tell nothing of one suite. A merged record is reused only when
    each merged record of the highest rank is reused. *)

val with_previous : prior:t -> t -> t
(** [with_previous ~prior t] is [t] in which each record [r] gets its previous
    outcome from the record [p] of [prior] under [r.id]. It applies only when
    [p] and [r] have the same source digest, which is not [None], the same
    renderings and the same end. The previous outcome is then {!val-outcome} of
    [p.verdict], or [p.previous] when [p.verdict] is no outcome. In all other
    cases it is [None]. Thus a skip, an unknown verdict or an unreached mutant
    between two outcomes hides no change. *)

(** {1:files Verdict files}

    Each suite of an executable has one verdict file, at {!output_file}.

    The first line of a file is the magic line [windtrap-mutants-v15], which
    carries the version of the format. A file with another first line is
    refused, never converted, and nothing is promised from one version to the
    next. *)

(** The type for the errors of reading a verdict file, which is {!Instr.error},
    where each case is described. *)
type error = Instr.error =
  | Unknown_format of { path : string; header : string }
  | Unreadable of { path : string; reason : string }
  | Corrupt of { path : string; reason : string }

val pp_error : Format.formatter -> error -> unit
(** [pp_error ppf e] is [Instr.pp_error format ppf e]. *)

type identity = Instr.identity = { exe : string; digest : string }
(** The type for the identity of the writer of a verdict file, which is
    {!Instr.identity}. *)

val format : Instr.format
(** [format] is the constants of the [.mutants] format: the magic line above,
    the data directory [mutants], the extension [mutants] and the kind
    [verdict]. *)

val writer_identity : exe:string -> identity option
(** [writer_identity ~exe] is the identity to record for the executable at
    [exe], whose [exe] is [Instr.exe_identity ~exe], or [None] when [exe] cannot
    be read. *)

val output_file : exe:string -> suite:string -> string
(** [output_file ~exe ~suite] is the verdict file of the suite [suite] of the
    executable at [exe]: [<dir>/windtrap-<hash>-<suite hash>.mutants], where
    [<dir>/windtrap-<hash>] is [Instr.output_dir format ~exe] and [<suite hash>]
    is the hexadecimal MD5 of [suite]. An executable that is renamed or moved,
    and a suite that is renamed, leave the previous file behind. *)

type file = {
  verdicts : t;  (** The records of the file. *)
  identity : identity option;  (** The recorded writer, if any. *)
  suite : string option;  (** The recorded suite, if any. *)
  refused : string option;
      (** [Some reason] when the writer could not mutation-test its suite, and
          [reason] says why. Its records then hold what it could not judge as
          {!Unknown}. *)
  test_digests : (reaching_test * string) list;
      (** The lowercase hexadecimal MD5 of what the writer knew of each test of
          the suite whose source file it could read, sorted by test with
          [List.compare String.compare], one entry for each test. A test with no
          entry has no known digest. *)
}
(** The type for what a verdict file holds. *)

val lookup : (reaching_test * string) list -> reaching_test -> string option
(** [lookup digests] is the lookup of the test digests [digests], a list as
    [file.test_digests]. It indexes the list when it is applied to [digests], so
    apply it once for each list. *)

val reuse :
  last:file ->
  recorded:(reaching_test -> string option) ->
  digest:(reaching_test -> string option) ->
  effort:effort ->
  reaching:reaching_test list ->
  Mutate.mutant ->
  record option
(** [reuse ~last ~recorded ~digest ~effort ~reaching m] is the record of [m]
    with the verdict of the last run, when the evidence of that verdict did not
    change. [last] is the verdict file of the last run, [recorded] is
    [lookup last.test_digests], [digest t] is the digest of the test [t] in this
    run, [effort] is the effort of this run and [reaching] is the reaching tests
    of [m] in this run, in the order of its job. The result is [Some r] when all
    of these hold, and [None] if not:
    + [last.refused] is [None].
    + [last.verdicts] holds a record [p] of [m.id], [m.source_digest] is not
      [None] and is [p.source_digest], and [p] has the end and the renderings of
      [m].
    + [p.verdict] is a {!Killed} that names one test [t], [t] is in [reaching],
      the {!prefix_digest} of [through t reaching] is [p.prefix], and
      {!effort_covers} [`Killed] holds for [~judged:p.effort ~asked:effort]. The
      compared tests are [through t reaching]. A kill that names several tests
      is not reused. Or [p.verdict] is a {!Survived} whose reaching tests are
      those of [reaching], as sets, and {!effort_covers} [`Survived] holds. The
      compared tests are [reaching].
    + For each compared test [t], [recorded t] is [Some d] and [digest t] is
      [Some d].

    [r] has the verdict, the effort and the prefix of [p], the fields of [m], no
    previous outcome, and the mark. A reused [p] can be reused again. [reuse]
    reads no file. *)

val load : string -> (file, error) result
(** [load path] is [Ok file] when the file at [path] is a verdict file. The file
    is read with {!Instr.read_file}, and every error names [path]. Otherwise it
    is the error of the read, [Error (Unknown_format _)] for another first line,
    or [Error (Corrupt _)] for data that is truncated or invalid:
    - a negative count, or a count larger than the input,
    - a test digest that is not 32 lowercase hexadecimal digits, or test digests
      that are not sorted or that name one test two times,
    - a missing or negative retries count, a pass below [1] or above the retries
      count plus [1], a settings word or a prefix that is not 32 lowercase
      hexadecimal digits, a prefix on a verdict that is not a {!Killed} that
      names a test, or a mark that is not [fresh] or [reused],
    - a [reused] mark on a verdict that is not a {!Survived} or a {!Killed} that
      names a test,
    - an empty file name, a line below [1] or a negative column,
    - a rewrite outside {!Mutate.rewrites}, an unknown verdict, an unknown or
      invalid reason, or a missing or unknown previous outcome,
    - a source digest that is not empty and not 32 lowercase hexadecimal digits,
    - a survivor with no reaching test, an empty killing executable, or a second
      record for one identifier,
    - a malformed identity line, a malformed suite line, a status that is
      neither [tested] nor [refused] with its reason, or bytes after the last
      record.

    Nothing is repaired, and a file with one malformed record is not read at
    all. *)

val save :
  ?identity:identity ->
  ?suite:string ->
  ?refused:string ->
  ?test_digests:(reaching_test * string) list ->
  string ->
  t ->
  unit
(** [save ?identity ?suite ?refused ?test_digests path t] writes [t] to [path]
    in the format of a verdict file, with {!Instr.write_file}. Records are
    ordered by {!Mutate.compare_id} and reaching tests are sorted, so equal
    collections give equal files. [identity] is recorded after the magic line
    when it is given, and then [suite] when it is given. A merged collection has
    no single writer and is written without the two. The status line follows:
    [tested], or [refused] and [refused]'s reason. The test digests (default
    none) follow, sorted by test.

    [load path] is then
    [Ok { verdicts = t; identity; suite; refused; test_digests }], with
    [test_digests] sorted, for every [t] whose identifiers and records {!load}
    accepts, and [Error (Corrupt _)] for any other (see {!add}). A collection
    built from the mutants of {!Mutate.val-catalogue} round-trips, unless a
    source file was registered under the name [""].

    Raises [Invalid_argument] before anything is written if [identity.exe] is
    empty, if [identity.digest] or a digest of [test_digests] is not 32
    lowercase hexadecimal digits, or if two entries of [test_digests] name one
    test, and [Sys_error] if the file cannot be written. *)
