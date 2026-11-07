### Coverage

- `windtrap coverage --json` writes each malformed UTF-8 sequence of a
  path as U+FFFD, and DEL as `\u007f`, as the `--json` document of a run
  does. Thus the document is always valid JSON.

### Mutation testing

- Two rewrites join the catalogue: `none` replaces `Some e` with `None`,
  and `tail` replaces `h :: t` with `t`. A list literal has one `tail`
  site, at its bracket, and so does a chain of `::`. Neither rewrite has
  a site in code that runs when the module is initialized, or in the
  right-hand side of a `let rec` outside its functions and `lazy`
  bodies. A file that
  declares a constructor `Some`, `None` or `::` has neither
  (doc/manual/mutation.md#what-is-mutated).
- The rewriter gives no mutant where the syntax shows the mutant
  equivalent: `x + 0`, `x - 0`, `a && a`, `a || a` and the condition of
  `if c then e else e`. Such a site has no identifier and no verdict,
  and no report counts it (doc/manual/mutation.md#what-is-mutated).
- The rewriter gives no mutant in the arguments of a `Logs` function
  that logs a message. It gives none to an integer or boolean literal
  in the arguments of `failwith` or `invalid_arg`. A test can kill such
  a mutant if it reads the message, but no test should pin the text of a
  message. A statement in
  these arguments keeps its mutants. A file that declares a module
  `Logs` loses the first rule. A file that binds `failwith` or
  `invalid_arg` loses the second.
- `--arm` refuses a mutant that `[@mutate off]` dismisses, and exits 1.
  The message names the reason. Before, the run armed no guard and ended
  on `mutant not evaluated`.
- The dry run finds each test that reaches a mutation site, also when
  the test evaluates the site on several domains at the same time. The
  test must synchronize with these domains when it starts and when it
  finishes, as a domain that the test spawns and joins does. Before, the
  dry run could give such a mutant a count of 0 or below, or a count
  that included the evaluations of earlier tests, and thus an incorrect
  budget.
- Each suite of an executable writes its own verdict file. Before, the
  suite that finished last replaced the one file of its executable. As a
  result, `windtrap mutants` could call a killed mutant a survivor. This
  applied to a main that calls `Windtrap.run` with more than one suite
  name, and to the partitions of an inline-test library, which dune runs
  at the same time.
- `windtrap mutants` merges the files of all suites, and counts the
  files of one executable as one executable. Its `not mutation-tested`
  rows and its unknown reasons name the suite, as in
  `t.exe (suite lts)`, and its outcome line counts the suites that are
  not mutation-tested. A later refused row whose mutants an earlier row
  counts says `no other mutant unknown`.
- A failure before the first evaluation of a mutant's site does not
  kill the mutant. Until that evaluation, the mutant's run executes the
  code without the mutant, so the failure has another cause, for example
  a schedule of domains or the clock. The run does not stop there. It
  runs the next reaching test. A mutant whose run did not evaluate its
  site is not evaluated, and the report names the failure under it, as
  `a failure that the mutant did not cause: calc › memo`. Before, such a
  mutant was killed. An evaluation in a process that a test forks counts
  for this rule.
- An `--arm` run uses the same rule. When no selected test ran the site
  and a test failed, it ends on
  `mutant not evaluated: no selected test ran the site, so the mutant did not cause the failure.`
  When only tests before the first evaluation failed, it ends on
  `mutant survived: the armed site was evaluated 2 times, and only tests before its first evaluation failed.`
  When only a forked process evaluated the site and no test failed, it
  ends on
  `mutant survived: only a forked process evaluated the armed site and no test failed.`
  Before, an `--arm` run in which only a forked process evaluated the
  site ended on `mutant not evaluated`. Under `-x`, an `--arm` run stops
  at the first failure that kills the mutant.
- The outcome line of a mutation run and of `windtrap mutants` ends
  with the mutation score, as `score 66.7% (6/9)`. The score is the
  percentage of killed mutants among those killed, survived and not
  evaluated. An unknown mutant does not count
  (doc/manual/mutation.md#gating-on-the-score).
- `windtrap mutants --min PCT` gates on the score. The command then
  exits 1 when the score is below `PCT`, and not for a survivor alone.
  A suite that was not mutation-tested fails the merge also under the
  gate.
- `windtrap mutants --json` prints the merge as one document: the
  counts, the score, the verdict files, and each mutant with its
  verdict. A survivor has the tests that ran it, and an unknown mutant
  has its reason (doc/manual/mutation.md#exporting-the-verdicts).
- `windtrap mutants` exits 1 with the reason on standard error when the
  write of its report or document to standard output fails with an
  error, for example on a full disk. Before, an uncaught exception gave
  exit code 2. A closed pipe ends the process by SIGPIPE, as before,
  unless the parent ignores that signal.
- `--skip-killed` and its mirror `WINDTRAP_SKIP_KILLED` let a mutation
  run skip a reached mutant that the verdict file of another suite
  killed. The executable of that file must not have changed since it
  wrote the file. The rewriter must have read the same source file for
  the two executables, and the mutant must be the same. The verdict file records the mutant as
  killed elsewhere, with the executable of that file. The report names
  each verdict file that the run used, and the outcome line counts the
  skipped mutants as not tested. The run uses only the files on disk
  after its dry run, so run the fast suites first. Two suites with the
  option that run at the same time can skip one mutant because of each
  other, so run them one after the other, for example with
  `dune runtest -j 1`
  (doc/manual/mutation.md#skipping-the-mutants-that-another-suite-killed).
- `windtrap mutants` counts a mutant killed elsewhere as killed when
  another file of the killing executable kills it, or when no other file
  of that executable holds it. In the second case, a note on standard
  error tells which run to do again. In every other case the skip does
  not count. The merge leaves out every skip that does not count, and
  the other records then give the verdict. The mutant is unknown when
  they give no verdict of a reached mutant. When no file of the merge
  kills the mutant directly, a note tells to run the suite that skipped
  it again.
- (breaking) `ppx_windtrap.mutate` registers the digest of each source
  file that it reads, and the catalogue gives it with each mutant:
  `Mutate.register` takes `~digest`, and `Mutate.mutant` has
  `source_digest`. Thus code that an earlier `ppx_windtrap.mutate`
  instrumented does not compile or link against this runtime. Build it
  again. Under dune the build does this automatically.
- A mutation run lists the mutants whose verdict changed since the last
  run of the same suite, in an `unstable (N)` section, as
  `calc.ml:10:16:ge   survived → killed`. The run compares only the
  verdicts killed, survived and not evaluated, of the same mutant on the
  same source. An unknown verdict, a mutant that no test reached or
  that ran outside tests, and a skipped mutant do not appear. The next
  run compares with the last verdict that is an outcome. A narrowed, a
  refused or an interrupted run shows no section, and so does a run
  whose file cannot be written. `windtrap mutants` gives, for each
  verdict file, the last change that the file records for each mutant,
  with the executable and the suite of the file. Under a scope, that
  change can come from a run before the last one. `--json` adds the
  array `unstable`. The section does not change the score or the exit
  code. When a run drops the records outside its scope, because the
  earlier file is of another build or one of the two runs is refused,
  the previous verdicts of these mutants go away. The next full run
  then lists no change of these mutants
  (doc/manual/mutation.md#unstable-verdicts).
- (breaking) The verdict file format is `windtrap-mutants-v13`. Each
  record keeps the digest of the source file of its mutant and the
  previous verdict of its mutant, and a skipped mutant is killed
  elsewhere. A file of an earlier format is refused. Delete
  `_build/_mutants` and run the suites again.
- `--mutate-workers` and its mirror `WINDTRAP_MUTATE_WORKERS` let a
  stateful test on several domains spawn its worker domains under
  `--mutate` and `--arm`, as without mutation testing. Thus a test can
  kill a mutant that only a concurrent order of the calls shows. A kill
  can then depend on a schedule. Under `-j`, the job of a mutant that
  such a test reaches runs alone, and so does the determinism probe. The
  `reproduce:`, `arm:` and `replay:` commands of the run keep the flag,
  but the commands of `windtrap mutants` do not have it. If neither the
  command line nor a mirror gives `--mutate` or `--arm`, the flag on the
  command line is a usage error. To opt a suite in through its dune stanza, use
  `(setenv WINDTRAP_MUTATE_WORKERS 1 ...)`
  (doc/manual/mutation.md#stateful-tests-on-several-domains).
- The deadline of a job of the mutation run does not count the start
  of a worker that replaces a worker that retired, for example after a
  test that spawned a domain. Each start leaves out at most the
  deadline, so a start that hangs ends the job. Before, a job with many
  such tests could pass its deadline, and the determinism probe refused
  the run.
- `--mutate-retry N` and its mirror `WINDTRAP_MUTATE_RETRY` run the job
  of a survivor again, up to N more times (0 to 100, default 0), each in
  a fresh worker. After the first run, only a kill changes the verdict.
  A retry that does not evaluate the site or that ends early leaves the
  survivor, and its block gives one line for that retry. The retries run
  in passes, each up to `-j` jobs at once, and the report prints each
  survivor in the last pass, in catalogue order. The title of a survivor
  gives its runs, as in `(3 runs)`. The verdict file does not keep the
  runs, so `windtrap mutants` does not show them. If neither the command
  line nor a mirror gives `--mutate`, the flag on the command line is a
  usage error (doc/manual/mutation.md#running-a-survivor-again).
- Under `--mutate-retry N` with `N` above 0, a mutation run does a check
  of each kill that names a test. The check runs the tests of the kill
  up to and with the killing test, with no mutant, up to 3 times, each
  in a fresh worker. When the killing test fails in one of these runs,
  a kill in the first run is unknown, with the reason
  `its killing test <test> also fails with no mutant: <failure>`. When
  the check of a kill in a retry fails, the mutant stays a survivor. An
  unknown mutant is not part of the score, so a flaky test makes the
  denominator smaller. One list of tests gets one check, and each run
  has the deadline of the job of the kill. The checks run after the retries, in
  passes of up to `-j` runs at once. The verdict file format does not
  change (doc/manual/mutation.md#flaky-kills).
