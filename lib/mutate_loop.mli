(*---------------------------------------------------------------------------
   Copyright (c) 2026 Invariant Systems. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** The mutation loop: the parent process of a mutation run.

    {!execute_and_report} is the one call through which a run becomes a mutation
    run, and the entry point of a suite makes it in place of {!Report.run}. The
    process that makes it runs no test, a mutant's least of all: the dry run,
    the probe, the mutants and [--arm] run in worker processes ([Supervisor]).

    The module decides which mutants survived, in which order and with which
    reaching tests. What a run tests or arms arrives on [config.mutation]
    ({!Run.type-mutation}), which {!Cli} resolves.

    @canonical Windtrap.Private.Mutate_loop *)

(** {1:running Running} *)

val execute_and_report :
  suite:string ->
  Run.config ->
  Test_tree.t list ->
  (Run.outcome, Run.startup_error) result
(** [execute_and_report ~suite config tests] is {!Report.run} over the same
    arguments, in the mode that [config.mutation] names, and the caller finishes
    its work on the result as it does after {!Report.run}.
    - Under {!Run.No_mutation} it is [Report.run ~suite config tests] and
      nothing else, in an instrumented build as in any other.
    - Under {!Run.Armed} it is the {{!section-armed}armed run}.
    - Under {!Run.Loop} it is the {{!section-loop}loop}.

    A loop that ran whole is [Ok] of its dry run, whatever it found: only
    [windtrap mutants], which merges the verdict files of every suite, gates on
    survivors. A loop that refused to start or could not go on, and an [--arm]
    identifier that is refused, are [Error (Run.Mutation_refused reason)], whose
    exit code is [1]. Each says its reason on standard error, and none falls
    back to a default and runs on. *)

(** {1:loop The loop}

    The loop proceeds in this order.
    + It fixes the population, which is the catalogue of the executable
      ({!val:Windtrap_runtime.Mutate.catalogue}) narrowed to the scope, without
      the mutants that [[@mutate off]] dismisses. The scope ({!Run.scope}) is
      the list of source-path prefixes that [--mutate] gave, the lines of
      [--lines] or [--diff], and the rewrite filter of [--rewrites] or
      [--skip-rewrites]. A mutant is in scope when three conditions are true.
      The list is empty, or one prefix is a prefix of its recorded file
      ([String.starts_with]). It lies on those lines, if there are lines. The
      filter keeps the rewrite of its identifier. A mutant out of scope is
      neither tested nor recorded.
    + It runs the dry run, which is {!Report.run} with [Supervisor.execute] over
      [config] with [junit] cleared, its workers telling it which tests evaluate
      each mutant. Every other field is that of [config], [baseline] included,
      so the dry run of a [--mutate -u] run accepts what a [-u] run accepts. A
      site that no test reached and that was evaluated outside every test, at
      module initialization or in a fixture release, is evaluated outside tests
      ({!Windtrap_runtime.Verdicts.Outside_tests}). A site that only tests
      marked xfail evaluated is unreached.
    + Under the [skip_killed] of the scope, it reads the other verdict files and
      skips each reached mutant that one of them killed ({b Killed elsewhere}
      below). A skipped mutant gets no job.
    + Under the [sample] of the scope, it keeps only the reached mutants that
      the skip leaves and that the sample holds ({b Sampling} below). A mutant
      out of the sample gets no job.
    + Under [config.incremental], it reads the verdict file of the last run of
      the suite and reuses the verdict of each reached mutant that the skip and
      the sample leave, when the evidence did not change ({b Incremental reuse}
      below). A reused mutant gets no job.
    + It runs the jobs ([Supervisor.fresh]), each in a worker of its own, which
      ran no test before it: the determinism probe, which is the tests that the
      dry run executed, unarmed, and then one job per reached mutant that it
      does not skip, in the order of the catalogue, with the mutant armed and
      its reaching tests up to the first failure in or after the test that first
      evaluated the armed site. Up to [config.jobs] run at once, and they are
      given in that order. A job that holds a test that spawned a pool of worker
      domains in the dry run ([config.mutate_workers]) runs alone. The probe
      agrees iff it executed as many tests, skipped as many and counted no
      failure.
    + Under [config.mutate_retry = n] above [0], it runs up to [n] more passes
      ({b Retries} below), and then up to [3] passes that check the kills
      ({b Flaky kills} below).
    + Once the last job is given it writes the verdict file.

    A job starts from module initialization, so what the dry run left, a table
    it filled or a lazy value it forced, is not there: the mutant is judged on
    what its tests do. Nothing that a job prints is visible, its baselines are
    checked read-only and no correction is recorded.

    The root seed is {!Cli.mutation_seed} unless [--seed] gives one
    ({!Cli.settings}), so a property draws the same cases in the dry run, the
    probe and every job, and on every run of one binary.

    {b Verdicts.} A mutant is {!Windtrap_runtime.Verdicts.Killed} when a test of
    its job failed in or after the test that first evaluated the armed site. It
    is killed too when a fixture release or a function of [at_exit] failed, and
    the job evaluated the site at any time. Until the first evaluation, the job
    runs the code of the program without the mutant. Thus a test that fails
    before it has another cause, and the job does not stop there. It is
    {!Windtrap_runtime.Verdicts.Unknown} when its job ended before its tests
    did: its worker was killed by a signal or exited, code under test calling
    [exit] included, or it passed its deadline or its memory limit
    ([config.mutate_memory]). Otherwise it is
    {!Windtrap_runtime.Verdicts.Not_evaluated} when its job did not evaluate the
    armed site, as when the dry run reached the site in a test only because of
    what an earlier test had done, and survived when it did. The report lists a
    not-evaluated and an unknown mutant with the [--arm] command that runs it
    again, and names it no survivor. Under a not-evaluated mutant, the report
    names the first test of its job that failed, or a fixture release, as a
    failure that the mutant did not cause. For this rule, an evaluation in a
    process that a test forks counts ([Supervisor.arm]). The dry run does not
    see such an evaluation. A job whose worker cannot map the byte that shows it
    counts each failure, as when it could not tell. Under [config.crash_kills],
    the report counts an unknown mutant of a deadline, a crash or a memory limit
    as killed ({!Report_sections.val-counted_as_killed}). Its verdict stays
    unknown.

    {b Retries.} Each pass after the first runs again the jobs of the mutants
    that survived the pass before it, with the same cases, deadline and budget,
    each in a fresh worker, up to [config.jobs] at once, in the order of the
    catalogue. A job that runs alone in the first pass runs alone in each pass.
    The first run gives the verdict as a run with no retry does. After it, only
    a kill that its check trusts replaces the survivor. A retry that does not
    evaluate the site or that ends early leaves the mutant a survivor, and the
    next retry runs. A mutant survives when its first run survives and no retry
    kills it. The report commits its block when the job of its last run is
    given, or when the check of a kill in a retry fails, with the number of runs
    when it is above [1], and one line for each retry that did not evaluate the
    site, ended early or gave a kill that the check does not trust, with why
    ({!Report.mutation_survivor}). A retry that hangs costs its deadline. The
    verdict file records [config.mutate_retry] and the pass that gave each
    verdict, not the early lines. The live line names a mutant of a later pass
    as it did in the first pass.

    {b Flaky kills.} Under [config.mutate_retry] above [0], a kill whose job
    names a killing test waits for a check. The killing test is the first test
    that has a counted failure, is not marked xfail, and comes in or after the
    test that first evaluated the site. A kill by a fixture release alone names
    no test and gets no check. The check runs the cases of the job, which are
    the reaching tests of the mutant, up to and with the killing test. It runs
    them with no mutant and with no stop at a failure, in a fresh worker. Two
    kills whose checks run the same cases share one check.

    The checks run after the last retry pass, in up to [3] passes
    ([check_runs]). Each pass runs once each check that has not failed, up to
    [config.jobs] at once, in the catalogue order of the first mutant that waits
    for the check. A check that holds a test that spawned a pool runs alone. A
    run of a check has the longest deadline of the jobs that wait for it, so a
    killing test that fails at its own timeout also fails in the check. The live
    line names the first mutant that waits for a check at each of its runs.

    A check fails when the killing test has a counted failure in one of its
    runs, also when the run then passes its deadline or loses its worker. A run
    that ends before the killing test ends gives no failure. When the check
    fails, a kill in the first run is {!Windtrap_runtime.Verdicts.Unknown}, with
    the reason ["its killing test <path> also fails with no mutant: <failure>"].
    The failure is the headline of the first failure of the test in that run
    ({!Report_sections.headline}). Otherwise the kill stays.

    When the check of a kill in a retry fails, the mutant stays a survivor, and
    the loop runs no more retries of it. Its block prints after the blocks of
    the last retry pass. The report gives the survivors in the order of their
    blocks, and [reproduce:] arms the first.

    {b Killed elsewhere.} Under the [skip_killed] of {!Run.scope}
    ([--skip-killed]), the loop reads the regular files with the extension
    [.mutants] in the directory of {!Windtrap_runtime.Verdicts.output_file},
    except its own file, in name order. It does not use a refused file, a file
    that does not load, a file that names no executable, or a file whose
    {!Windtrap_runtime.Instr.type-freshness} is not [Fresh]. It names each of
    the last three in a warning on standard error. A reached mutant gets no job
    when a used file gives it {!Windtrap_runtime.Verdicts.Killed}, and that
    record has the source digest of the mutant of this executable
    ({!Windtrap_runtime.Mutate.mutant.source_digest}), not [None], and its
    renderings and extent. A {!Windtrap_runtime.Verdicts.Killed_elsewhere}
    record does not skip a mutant. The mutant gets a [Killed_elsewhere] record
    that names the executable of that file, the smaller one in [String.compare]
    order when several files kill it. The report counts the mutant as not
    tested. Above the outcome line and its [reproduce:] line, one line gives the
    number of skipped mutants and the executable of each used file, with the
    number of skips that it gave. The loop uses the files as they are on disk
    after the dry run. The time that it takes to read them does not count in the
    deadline of a job.

    {b Sampling.} Under the [sample] [Some (percent, seed)] of {!Run.scope}
    ([--sample]), a reached mutant that the skip leaves is in the sample when
    {!Windtrap_runtime.Verdicts.in_sample} holds for [percent], [seed] and its
    identifier. The other such mutants get a
    {!Windtrap_runtime.Verdicts.Not_sampled} record, and the report counts them
    as not sampled ({!Report_sections.type-sample}). The sample of the report is
    [Uniform], and its [judged] is the mutants that the skip leaves. Above the
    outcome line and its [reproduce:] line, after the line of the reused
    verdicts, one line gives the percent and the seed
    ({!Report_sections.sample_line}). The verdict file records the sample. A
    mutant out of the sample is never reused, and the job of a mutant in the
    sample is the job of a run with no sample.

    {b Incremental reuse.} Under [config.incremental] ([--incremental]), after
    the dry run, the loop loads {!Windtrap_runtime.Verdicts.output_file} of its
    executable and suite, which any build can have written. It does not use a
    file of another suite. A file that does not load, an earlier format
    included, gives a warning on standard error, and the loop then replaces it.
    No file gives no warning. A reached mutant that the skip leaves keeps the
    verdict of that file when {!Windtrap_runtime.Verdicts.reuse} accepts it:
    - The file is not refused, and it has a record of the mutant with the source
      digest, not [None], the renderings and the extent of this run.
    - The record is a kill that names a test, and the killing test reaches the
      mutant in this dry run. The tests of the job of this run, up to the
      killing test, are those of the kill, in the same order. Or the record is a
      survivor, and the same set of tests reaches the mutant.
    - Each of these tests has the same digest in the file and in this run. The
      digest of a test is the MD5 of the digest of its source file
      ({!test_digest}), of its declared limit and of its declared retries. A
      test with no location, or whose file the loop cannot read, has no digest.
    - The effort of the record covers the effort of this run
      ({!Windtrap_runtime.Verdicts.effort_covers}): the same {!settings}, and
      enough retries. Under [config.mutate_retry] above [0], a kill is reused
      only from a run that had retries too. A kill from the [k]-th retry is
      reused only when [config.mutate_retry] is [k] or more.

    A reused mutant gets no job, no retry and no check. Once the probe agrees,
    the loop commits each reused kill in the first pass, and each reused
    survivor in the last pass. The loop commits a reused verdict before the job
    of the next mutant in catalogue order. When the last pass does not run, a
    reused survivor comes after the retries. Thus, for the same verdicts, the
    blocks print in the order of a run that tests each mutant. A reused survivor
    prints its block, with [(reused)] after its title.

    One type of survivor is an exception. A kill in a retry can give a survivor
    when its check does not trust the kill. In a run that tests each mutant,
    this survivor prints when its check ends, after the last pass. When the loop
    reuses it, it prints in the last pass. Except for this survivor, the
    [reproduce:] line arms the same survivor.

    A probe that disagrees, or a signal before the probe ends, commits none. A
    later signal stops the commits after the stopped job, as it stops the jobs.
    But when the run ends with each verdict known, the loop commits the reused
    verdicts that remain.

    Above the outcome line and its [reproduce:] line, after the line of
    [--skip-killed], one line gives the number of verdicts that the run reused,
    as in [reused: 2 verdicts from the last run]. It prints in a finished and in
    an interrupted report, also when the number is [0]. A narrowed run reuses
    too, and saves no verdict. When no file of this build exists, it writes a
    refused file, so the next run reuses no verdict.

    {b Tests marked xfail.} A test marked xfail ({!Test_tree.val-xfail}) reaches
    no mutant and kills none. The dry run and the probe run it, no mutant's job
    runs it, and no survivor names it.

    {b Limits.} Nothing bounds a whole run. A job that passes its deadline or
    its memory limit has its process group killed, and the loop goes on. The
    deadline is the time that the dry run took, read on the monotonic clock
    ({!Os.val-counter}), plus a share for the tests of the job. The share is ten
    times ([deadline_multiplier]) what the dry run measured for those tests, and
    at least one second. The probe's tests are every executed test. A worker
    retires after a test that spawned a domain, and a new worker runs the rest
    of the job. Its start, up to the end of its module initialization, does not
    count toward the deadline.

    The runaway budget of a job ({!Windtrap_runtime.Mutate.arm}) is
    [(hits * 8) + 1000] ([budget_of]) for a site that the dry run evaluated
    [hits] times.

    {b Memory records.} When [WINDTRAP_DEBUG_MEMORY] is set, the loop writes
    lines about its memory on standard error, as [doc/dev/testing.md] tells.

    {b The verdict file.} The file holds one record per reached mutant, one
    [Outside_tests] record per mutant of the population evaluated outside tests,
    and one [Unreached] record per unreached one. A skipped mutant has a
    [Killed_elsewhere] record, and a mutant out of the sample a [Not_sampled]
    record. Each record has the source digest of its mutant
    ({!Windtrap_runtime.Verdicts.record_of_mutant}), the effort of the run that
    gave its verdict and a mark. A reused record keeps the effort of the run
    that tested the mutant. A kill that names a test has the digest of the tests
    of its job up to the killing test. The file has the digest of each test of
    the suite that has one, also without [config.incremental]. The file is
    written to {!Windtrap_runtime.Verdicts.output_file} of the executable and
    the suite, by {!Windtrap_runtime.Verdicts.save}, which records the suite.
    Under a scope, the records of the files outside it stay when the file there
    was written by this build ({!Windtrap_runtime.Verdicts.writer_identity}) for
    the same suite with the same sample, or with no sample in the two runs, and
    the suite was tested. They are dropped otherwise. The sample does not narrow
    the scope, so a sampled run writes [Not_sampled] over the records of the
    last run for the mutants out of its sample. A file that cannot be written
    ([Sys_error]) is one sentence on standard error above the outcome line.

    Only a loop that ran whole, over the whole suite, writes its verdicts. A run
    whose selection narrows the suite says so on standard error above the
    outcome line. It leaves a file that this build wrote for the suite, and
    otherwise writes a refused file, as below, so the merge names the suite.
    [filter], [exclude], [tags], [exclude_tags], [failed_only], [shard] and an
    active focus narrow the suite. The scope of [--mutate] does not.

    {b Unstable verdicts.} Before it writes its file, the loop reads the file
    that it replaces, of any build, when that file records the same suite. Each
    record of this run gets its previous outcome from it
    ({!Windtrap_runtime.Verdicts.with_previous}). A record kept from outside the
    scope stays as it was. When the file is written, the report lists each
    record of this run whose outcome changed
    ({!Windtrap_runtime.Verdicts.changed}), in catalogue order, in the unstable
    section ({!Report_sections.type-unstable}). A skipped mutant is not listed,
    because a skip is no outcome. A run that writes no file of its verdicts
    lists none: a narrowed run, a refused run, a run that a signal stopped
    before its last verdict, and a run whose file cannot be written. A reused
    verdict is not listed ({!Windtrap_runtime.Verdicts.changed}). The list does
    not change the score or the result.

    {b What the environment asks.} The facade's [WINDTRAP_MUTATE] rule holds
    when [config.broadcast.mutate] does: an empty population and a selection
    that keeps no test ({!Run.list_selection}) are no refusal, and the result is
    that of the ordinary run under {!Run.No_mutation}, before which an empty
    population says why on standard error. Every other refusal stands.

    {b Refusals.} Each of these is [Error (Run.Mutation_refused reason)] with
    one sentence on standard error ({!Os.say}), and but the first and the empty
    population each writes the verdict file as refused, with the reason
    ({!Windtrap_runtime.Verdicts.save}): its records hold the population as
    unknown, or, past a whole green dry run, the reached mutants as unknown and
    the others as that dry run found them. They are tried in this order:
    - The platform is Windows, where windtrap starts no worker process.
    - [WINDTRAP_DEBUG_MEMORY] is set to a value that is not empty and that
      [int_of_string] does not read as a positive integer.
    - This process cannot start the jobs' workers ([Supervisor.can_spawn]): it
      spawned a domain, so it cannot fork, and a new start of the executable
      would not reach this run.
    - The dry run is refused at startup. {!Report.run} has said why.
    - No test ran in the dry run, or it is red.
    - The population is empty. This is no refusal when the scope's lines name no
      line. It is also no refusal when the lines name a file of the catalogue
      but hold no site that the rewrite filter keeps. The same applies when the
      rewrite filter keeps no site of a scope that has sites. Then the loop says
      so on standard error and is [Ok] of its dry run, with no verdict file. A
      dry run that is red comes first, and is refused.
    - The probe disagrees with the dry run, and the sentence names the tests
      that failed in it, or its worker ended early or passed its deadline or its
      memory limit. *)

(** {1:armed The armed run}

    Under {!Run.Armed} the identifier is read by
    {!Windtrap_runtime.Mutate.id_of_string} and armed by
    {!Windtrap_runtime.Mutate.arm}, here and in each worker of an ordinary
    [Supervisor.execute] run.
    - An identifier that is malformed, ambiguous, or
      {!Windtrap_runtime.Mutate.Unmatched} within a file that this executable
      catalogues is [Error (Run.Mutation_refused _)], with the sentence of
      {!Windtrap_runtime.Mutate.pp_arm_error} on standard error, before anything
      runs.
    - A mutant that {!Windtrap_runtime.Mutate.arm} gives with [dismissed] set to
      [Some reason] is [Error (Run.Mutation_refused _)] before anything runs.
      Its site has no guard, so an armed run of it is the unarmed run. The
      sentence on standard error names the dismissal and the reason.
    - {!Windtrap_runtime.Mutate.Uncatalogued} is no refusal. The same sentence
      goes to standard error before the transcript, and the result is that of
      the ordinary run under {!Run.No_mutation}.
    - With the mutant armed, it runs {!Report.run} with [baseline] set to
      {!Baseline.Check}, so it records no correction.
    - Its verdict leaves out the tests marked xfail, as the loop does. The
      unexpected pass of such a test fails the run and kills no mutant, and a
      site that only such tests evaluated is not reached
      ({!Report.mutation_not_reached}).
    - A test that fails kills the mutant when it or an earlier test, in the
      order of the selection, evaluated the armed site. An evaluation outside
      every test counts as one before every test. A test whose worker ended
      during the test has unknown evaluations, and its failure counts. A fixture
      release that fails kills the mutant when the run evaluated the site at any
      time. The mutant is armed with [Supervisor.arm], so an evaluation in a
      forked process counts. The evaluations of a test count only when the run
      reports its row. An evaluation outside every test always counts, also one
      in the fixture release of a test that ran past the stop of the run. Under
      [-x] the run stops at the first failure that kills the mutant.

    The result of an armed run is that of {!Report.run}, so its exit code is
    that of the ordinary run, [2] included, and it writes its JUnit file. *)

(** {1:signals Signals}

    From the end of the dry run until its verdict file is written, the loop
    handles [SIGINT], [SIGTERM] and [SIGHUP]. One that arrives while a job runs
    ends every job, with its process group, and the mutants not yet given get no
    verdict. Nor does a survivor that waits for its next run, or a kill that
    waits for its check, and the loop starts no other pass. The report names the
    mutant of the next job that a pass of mutants gives, or the probe, as
    interrupted while it is tested. When the signal comes during a pass of
    checks or between two passes, it names the first mutant in catalogue order
    with no verdict: a survivor as one that waits for its next run, and a kill
    as one that waits for its check. A signal that comes before a pass installs
    its handlers stops the pass before its first job
    ([Supervisor.fresh ~stopped]). The loop then reports what it found, writes
    no verdict file, and dies by the same signal last, so its parent sees a
    death by signal and no [at_exit] function runs.

    A signal that arrives once the last job of the last pass was given stops
    nothing. The verdict file is written, a second signal excepted, and the
    report ends as usual. The loop then dies by that signal, and says nothing
    more.

    [SIGPIPE] is handled over the same span. When the reader of standard output
    has gone away, the write that finds it gone fails. The loop then stops as it
    does for the other signals, except that it says nothing and tries no closing
    report, and it dies by [SIGPIPE]. When the process was started with
    [SIGPIPE] ignored, the [Sys_error] of the failed write escapes
    {!execute_and_report} instead. *)

(** {1:evidence Evidence}

    The values that the loop records for each verdict and compares under
    [config.incremental], exposed for a test. *)

val settings : Run.config -> string
(** [settings config] is the lowercase hexadecimal MD5 of one injective spelling
    of the settings of [config] that change what a test does in a job: the
    windtrap version ({!Cli.version}), [seed], [prop_count], [replay], the
    choices of [case_file], [mutate_workers], [timeout], [default_timeout] and
    [mutate_memory]. Each value has a tag and a length, so no two configurations
    that differ in one of them share a spelling. *)

val test_digest : string -> string option
(** [test_digest file] is the lowercase hexadecimal MD5 of the source file
    [file] of a test, as its location names it. It reads the file under
    {!Os.project_root} first ({!Os.reconstruct}) and then as given, and it reads
    only a regular file. A file that it cannot read gives [None]. *)

(** {1:effects Effects}

    Beyond the effects of {!Report.run} and [Supervisor.fresh], the loop reads
    the verdict file of its executable and suite and writes it. For the source
    line of a survivor it reads the recorded file of the mutant, under
    {!Os.project_root} first and then as given. Under [skip_killed], it lists
    the directory of its verdict file after the dry run, reads the other regular
    files with the extension [.mutants] in it, and reads the executable that
    each such file names. After the dry run, it reads the source file of each
    test that has a location, once for each file, under {!Os.project_root}
    first. Under [config.incremental], it reads its verdict file after the dry
    run. The time of these reads does not count in the deadline of a job. *)
