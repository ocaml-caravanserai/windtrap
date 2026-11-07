The changelog tool (doc/dev/changelog.md) does a check of the fragments in
a directory and joins them into the changelog.

  $ exe=$PWD/changelog.exe
  $ cl() { "$exe" "$@"; }
  $ mkdir changes

A fragment has one or more area headings, each with its lines. A line in
a code block can start with "#".

  $ cat > changes/good.md <<'EOF'
  > ### Running tests
  > 
  > - `--foo` is new:
  > 
  >   ```sh
  >   # a comment
  >   ```
  > 
  > ### Coverage
  > 
  > - `--bar` is new.
  > EOF
  $ cl check changes

The check gives exit code 1 and a message for each type of error.

  $ ck() { rm -f changes/x.md; printf "$1" > changes/x.md; cl check changes; }
  $ ck '### Mutations\n\n- x.\n'
  changes/x.md:1: unknown area "Mutations" (doc/dev/changelog.md lists them)
  [1]
  $ ck '###  Coverage\n\n- x.\n'
  changes/x.md:1: unknown area " Coverage" (doc/dev/changelog.md lists them)
  [1]
  $ ck 'Text.\n### Coverage\n\n- x.\n'
  changes/x.md:1: the fragment does not start with an area heading
  [1]
  $ ck '\n'
  changes/x.md:1: the fragment does not start with an area heading
  [1]
  $ ck '### Coverage\n\n### Assertions\n\n- x.\n'
  changes/x.md:1: area "Coverage" does not start with a line "- "
  [1]
  $ ck '### Coverage\n\nx.\n'
  changes/x.md:1: area "Coverage" does not start with a line "- "
  [1]
  $ ck '### Coverage\n\n- x.\n## v1\n'
  changes/x.md:4: a heading that is not an area heading
  [1]
  $ ck '### Coverage\n\n- x.\n\n  # Notes\n'
  changes/x.md:5: a heading that is not an area heading
  [1]
  $ ck '### Coverage\n\n- x:\n\n  ```\n  y\n'
  changes/x.md:5: a code block that does not end
  [1]

The check and the join read only the files whose names end with ".md"
and do not start with a dot. Dune copies these files into _build, so
the check in "dune build @runtest" sees the same fragments as the join.

  $ rm changes/x.md
  $ printf 'junk\n' > changes/.x.md
  $ printf 'junk\n' > 'changes/a.md~'
  $ printf 'junk\n' > changes/notes
  $ mkdir changes/old.md
  $ touch changes/dune
  $ cl check changes

The join adds an open entry above the first release. In each area, the
lines come in the order of the file names. The areas come in the order
of the list. Then the join deletes the fragments.

  $ rm changes/good.md
  $ printf '### Mutation testing\n\n- From b.\n' > changes/b.md
  $ printf '### Mutation testing\n\n- From a,\n  two lines.\n\n### Declaring tests\n\n- New.\n' > changes/a.md
  $ printf '### Mutation testing\n\n- From 0.\n' > changes/0-old.md
  $ printf '# Changelog\n\n## v0.1.0 2026-01-01\n\n- Released line.\n' > CHANGES.md
  $ cl join CHANGES.md changes
  $ cat CHANGES.md
  # Changelog
  
  ## Unreleased
  
  ### Declaring tests
  
  - New.
  
  ### Mutation testing
  
  - From 0.
  - From a,
    two lines.
  - From b.
  
  ## v0.1.0 2026-01-01
  
  - Released line.
  $ ls -A changes
  .x.md
  a.md~
  dune
  notes
  old.md

If the changelog has an open entry, the join gives exit code 1 and
changes no file.

  $ printf '### Coverage\n\n- Good.\n' > changes/a.md
  $ cp CHANGES.md before
  $ cl join CHANGES.md changes
  CHANGES.md: it has a "## Unreleased" entry; rename it first
  [1]
  $ cmp before CHANGES.md

If one fragment has an error, the join changes no file.

  $ printf '# Changelog\n\n## v0.1.0 2026-01-01\n\n- Released line.\n' > CHANGES.md
  $ cp CHANGES.md before
  $ printf '### Coverage\n\nBad.\n' > changes/b.md
  $ cl join CHANGES.md changes
  changes/b.md:1: area "Coverage" does not start with a line "- "
  [1]
  $ cmp before CHANGES.md
  $ ls changes/a.md changes/b.md
  changes/a.md
  changes/b.md

With no fragment, the join does not change the changelog.

  $ rm changes/a.md changes/b.md
  $ cl join CHANGES.md changes
  $ cmp before CHANGES.md

With no command, the tool shows the usage and gives exit code 2.

  $ cl
  usage: changelog check DIR
         changelog join CHANGES DIR
  [2]
