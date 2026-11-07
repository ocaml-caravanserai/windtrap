# The changelog

`CHANGES.md` is written for users. It has one entry per release, newest
first. While the work happens, the lines for the next release are in
fragments in `changes/`. A pull request does not add its lines to
`CHANGES.md`. It adds them in a fragment. At release, the changelog tool
puts the lines of the fragments into a new open entry, `## Unreleased`,
at the top. Then you give this entry the heading of the version.

## Headings

A released entry is headed `## vX.Y.Z YYYY-MM-DD`, the tag's date.
`dune-release tag` reads the version from the first heading after the
`# Changelog` title, so no other heading stands between them. The open entry is headed
`## Unreleased`. It exists only during the release: the changelog tool
makes it, and then you rename it to the heading of the version.

## While working

A change that a user can see gives a line in the changelog. Examples are
a new or changed value, flag, variable, file format, output line, exit
code, error message or default. A change that a user cannot see (an
internal refactor, a test, a comment, a tool for the development of
windtrap) gives no line.

The line goes into a fragment, in the same commit as the change. Do not
add the line to `CHANGES.md`. Thus no two open pull requests change
`CHANGES.md`.

### Fragments

A fragment is a file in `changes/` whose name ends with `.md` and does
not start with a dot. A pull request that gives lines adds one fragment
with a name that no other fragment has, for example the name of its
branch with `-` in place of each `/`: `changes/mutate-retry.md`. When
the pull request gives more lines, add them to the same fragment. The
changelog tool ignores the other files of `changes/`, so a fragment
without the suffix `.md` is lost. A directory in `changes/` is an
error.

A fragment has the form of the open entry, without the `## Unreleased`
heading. It starts with an area heading, and each area heading has its
lines:

```markdown
### Mutation testing

- `--mutate-retry N` does a check of each kill that names a test.
```

An area heading is `### ` and then the name of an area of the list in
"Lines", with the same spelling and no other space. Each other line of
an area starts with `- ` (a list item) or with two spaces (text under a
list item, for example a code block). Thus each line stays in the list
of its area in `CHANGES.md`.

`dune build @runtest` does a check of the fragments (`changes/dune`).
The check finds these errors:

- A fragment that does not start with an area heading
- An unknown area
- An area whose first line does not start with `- `
- A line of an area that does not start with `- ` or two spaces
- A directory in `changes/`.

The check and the join command find the fragments with the same rule,
so they find the same fragments.

To change a line, edit the fragment that has it. Until the first release
with fragments, the lines of the pull requests before the fragments are
in `changes/0-open-entry.md`. The name of this file sorts first, so its
lines come first in each area.

### Lines

One line per change, addressed to the user, in the present tense,
stating what is now true: "`expect_file` reads its baseline relative to
the project root", not "fixed baseline path resolution". A line leads
with the item it changes, in code font, or with the noun of a rule that
spans several ("Checking is read-only; …"). A removal reads "`x` is
removed", and a variable no longer read "`X` is not read".

A change after which code or a workflow of the previous release stops
working is breaking, and its line starts with `(breaking)`.

A line is one sentence, or two joined by a semicolon when the second is
the first's consequence or the way out. What needs more is linked: the
line closes on the manual section that teaches the new form, as
`(doc/manual/baselines.md#accepting-a-change)`, the heading in GitHub's
anchor form (lowercase, spaces to `-`, other punctuation dropped). A
reporter or a patch author is thanked at the end of the line: "Thanks to
A. B. for the report (#12)."

Lines go under the area they belong to, in this order: Declaring tests,
Assertions, Property testing, Stateful testing, Baselines and expect
tests, Resources and process state, Running tests, Coverage, Mutation
testing, Packages and libraries. An empty area is omitted. The changelog
tool has the same list (`areas` in `dev/changelog/changelog.ml`). If you
change the list in this document, change `areas` also.

## At release

`release.md` gives the steps of a release. Its first step runs the join
command of the changelog tool, from the root of the repository:

```sh
dune exec ./dev/changelog/changelog.exe -- join CHANGES.md changes
```

The tool makes the open entry above the first released entry. It writes
the areas in the order of the list. In an area, the lines come in the
order of the file names of the fragments. Then the tool deletes the
fragments. If `CHANGES.md` already has a `## Unreleased` entry, or if a
fragment has an error, the tool changes no file. With no fragment, the
tool changes no file and makes no open entry. Read the result, and
change the order of the lines if necessary.

The entry opens on one short paragraph saying what got better, in the
user's terms. It lists no breaking change: each one is a `(breaking)`
line under its area. Migration notes for a breaking release live in the
manual (`doc/manual/migrating-from-<previous>.md`); the changelog is not
a migration guide.

A `### Highlights` section follows, above the areas: three to six
paragraphs, each one change that matters to most users. A paragraph
opens on a bold sentence that states the gain ("A crash or a hang fails
one test, not the run."), then says what the previous release did and
what happens now, in two to four sentences. The areas below keep every
line.
