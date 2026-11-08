# Releasing

The checklist for cutting a windtrap release. Two packages ship
together from this repository: `windtrap` (the library, the runner,
the `windtrap` binary) and `ppx_windtrap` (the expect/inline PPX and
the coverage and mutation backends, pinned to `windtrap` with
`(= :version)`).

## Bars to verify, all of them, before tagging

- [ ] `dune build`: zero warnings; warnings are treated as broken
      implementation, never silenced.
- [ ] `dune runtest`: green, which includes the examples (the manual's
      runnable mirror, one per chapter), the PPX expansion pins, and the
      conformance corpus.
- [ ] The migration pages (`doc/manual/migrating-from-0.1.md` and
      `doc/manual/migrating-from-0.2.md`) compile against the tree by
      hand. Nothing compiles them, so every replacement spelling is
      checked by reading, or not at all.
- [ ] `dune fmt`: clean.
- [ ] Conformance bar (`test/conformance/RESULTS.md`): every pass-set
      file passes unchanged and every unsupported construct is refused,
      both `@runtest` outcomes; `test/conformance/counts.expected`
      reports the byte-identical share of the corrections. If a count
      moved since the last release, the release notes say why.
- [ ] Both semantics-preservation suites green (`test/unit/semantics/coverage/`
      and `test/unit/semantics/mutate/`), which nothing waives (the
      coverage and mutant guarantees in `architecture.md`).
- [ ] Instrumented smoke run:
      `SKIP_PACKAGE_SESSIONS=true dune runtest --force --instrument-with ppx_windtrap.coverage`
      still green with no change in outcomes, counts or exit codes, then
      `dune exec windtrap -- coverage` reports the tree. Dune 3.23.1
      and 3.24 report a dependency cycle for a session that depends on
      `(package windtrap)` under the backend (`test/cram/run/dune`), and
      the variable skips these sessions, as in CI's coverage job.
- [ ] Docs current: `doc/manual/` pages against `lib/windtrap.mli`
      (the `.mli` is the truth), the migration page against the surface,
      the README against reality.
- [ ] `SKILL.md` against the manual: it names
      commands, flags and stanzas, and nothing checks it.
- [ ] Every command a `doc/manual/` page or the README shows is re-run
      against its example, and its output is compared with the page's
      block. Durations, seeds and absolute paths may differ; any other
      difference is fixed on the page. A block that shows a failure
      needs the edit its page describes, reverted afterwards.
- [ ] The instrumented commands of `coverage.md`, `mutation.md` and
      `examples/x-blueprint/README.md` are re-run in a copy of the
      example outside the checkout, as a user's project runs them. In
      the checkout, `--instrument-with` also instruments windtrap's own
      `lib/`, and the reports list its files. Copy the example's
      directory out, add a `dune-project` whose package depends on
      `windtrap` and `ppx_windtrap` and that pins both to the checkout
      (the blueprint's README shows the `pin` stanza), run
      `dune pkg lock`, then run the page's commands from the copy's
      root. The lock records the checkout's commit, so commit first and
      lock again after every commit.

## Versioning

The public surface is `lib/windtrap.mli` plus the CLI/env contract and
the exit codes. Breaking any of it, or any of the twelve guarantees in
`architecture.md`, is a major version and reopens the design first.
Additive surface (new verbs, generators, flags) is a minor version;
fixes are a patch. `windtrap` and `ppx_windtrap` version in lockstep;
never release one without the other.

The ppx_expect conformance envelope is part of the contract:
narrowing it (a formerly-HONORED construct now rejected) is breaking.
Re-pinning the corpus to a newer upstream is a release-notes item,
with the re-measured numbers (`testing.md`, "The conformance corpus").

## Cutting the release

1. `CHANGES.md` (see `changelog.md`, "At release"):
   1. If a conformance count moved, add a fragment with a line for it,
      in the area "Baselines and expect tests".
   2. From the root of the repository, run
      `dune exec ./dev/changelog/changelog.exe -- join CHANGES.md changes`.
      The tool makes the open entry (`## Unreleased`) and deletes the
      fragments.
   3. Rename `## Unreleased` to `## vX.Y.Z YYYY-MM-DD`. This heading is
      the first heading of the file after the title. If the tool gave
      an error, correct the cause and run the tool again. If the tool
      gave no error and made no open entry, `changes/` has no fragment:
      write the entry by hand.
   4. Write the opening paragraph and the highlights above the areas.
   5. Commit `CHANGES.md` and the deleted fragments in one commit.
2. Bump nothing in source: the version comes from the git tag
   (`dune-release` and dune substitute it). Opam metadata lives in
   `dune-project` (`generate_opam_files`); if it changed, `dune build`
   regenerates the checked-in `.opam` files; commit them. The one
   exception is `flake.nix`: set its `version` to the new version.
3. `dune-release tag` (annotated tag from `CHANGES.md`), then
   `dune-release distrib`; the tarball build must be clean from a
   pristine checkout, both packages.
4. `dune-release publish` (GitHub release + docs), then
   `dune-release opam pkg` and `dune-release opam submit`, one
   opam-repository PR carrying both packages.
5. Watch opam-repository CI: it builds on platforms and compilers we
   do not test locally (the floor is OCaml 5.0: no
   newer-stdlib-only functions without a guard). Fix-forward on the
   PR is normal; force-pushing the tag is not. If the tarball is
   wrong, cut a `.1` patch release.
6. After merge: verify `opam install windtrap ppx_windtrap` from the
   default repository on a clean switch, and that the examples build
   against the installed packages.

## Support policy

windtrap 0.1 stays published on opam; nobody is force-upgraded
(`doc/manual/migrating-from-0.1.md` is the bridge). Patch releases of the
current series fix bugs without surface change; there is no backport
branch unless a security-grade defect appears in 0.1.
