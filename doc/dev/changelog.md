# The changelog

`CHANGES.md` is written for users. It has one entry per release, newest
first, and the entry for the next release is open at the top while the
work happens. A pull request does not add its lines to `CHANGES.md`. It
adds them in a fragment, and the release joins the fragments into the
open entry.

## Headings

A released entry is headed `## vX.Y.Z YYYY-MM-DD`, the tag's date.
`dune-release tag` reads the version from the first heading of the
file, so nothing stands above it. The open entry is headed
`## Unreleased`, and it exists only while it has lines: at release it is
renamed to the version's heading.

## While working

A change that a user can see gives a line in the changelog. Examples are
a new or changed value, flag, variable, file format, output line, exit
code, error message or default. A change that a user cannot see (an
internal refactor, a test, a comment, the development process) gives no
line.

The line goes into a fragment, in the same commit as the change. Do not
add the line to `CHANGES.md`. Thus, two pull requests that are open at
the same time do not both change `CHANGES.md`.

### Fragments

A fragment is a Markdown file in `changes/`. A pull request that gives
lines adds one fragment, with the name of its branch, for example
`changes/mutate-retry.md`. When the pull request gives more lines, add
them to the same fragment.

A fragment has the form of the open entry, without the `## Unreleased`
heading. It has one or more area headings, and each area heading has its
lines:

```markdown
### Mutation testing

- `--mutate-retry N` does a check of each kill that names a test.
```

Each area heading names an area of the list in "Lines", with the same
spelling. A fragment has no text before its first area heading. A line
of a fragment must not start with `#`, except an area heading. This rule
includes a line in a code block.

`dune build @runtest` does a check of each fragment (`changes/dune`).
The check finds these errors:

- A fragment without an area heading
- An unknown area
- An area without lines
- A first line of an area that does not start with `- `
- Text before the first area heading
- A heading that is not an area heading.

The lines that `CHANGES.md` has under `## Unreleased` stay there. To
change one of these lines, edit `CHANGES.md`. To change a line of a
fragment, edit the fragment.

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

First, join the fragments into the open entry:

```sh
dune exec ./dev/changelog/changelog.exe -- join CHANGES.md changes
```

The changelog tool adds the lines of each fragment under the heading of
their area.
In an area, the lines of the fragments come after the lines that the
entry has, in the order of the file names. The tool writes the areas in
the order of the list, and adds the `## Unreleased` heading if the entry
does not exist. Then it deletes the fragments. If a fragment has an
error, the tool changes no file. Read the result, and change the order of
the lines if necessary.

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
