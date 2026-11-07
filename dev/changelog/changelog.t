The changelog tool (doc/dev/changelog.md) does a check of fragments and
joins them into the changelog.

  $ exe=$PWD/changelog.exe
  $ cl() { "$exe" "$@"; }

A fragment has one or more area headings, each with its lines.

  $ cat > good.md <<'EOF'
  > ### Running tests
  > 
  > - `--foo` is new.
  > 
  > ### Coverage
  > 
  > - `--bar` is new.
  > EOF
  $ cl check good.md

The check gives exit code 1 and a message for each type of error.

  $ printf '### Mutations\n\n- x.\n' > unknown.md
  $ cl check unknown.md
  unknown.md:1: unknown area "Mutations"; the areas are: Declaring tests, Assertions, Property testing, Stateful testing, Baselines and expect tests, Resources and process state, Running tests, Coverage, Mutation testing, Packages and libraries
  [1]
  $ printf 'Text.\n### Coverage\n\n- x.\n' > before.md
  $ cl check before.md
  before.md:1: a line before the first area heading
  [1]
  $ printf '\n' > none.md
  $ cl check none.md
  none.md:1: no area heading
  [1]
  $ printf '### Coverage\n\n### Assertions\n\n- x.\n' > empty.md
  $ cl check empty.md
  empty.md:1: area "Coverage" has no line
  [1]
  $ printf '### Coverage\n\nx.\n' > dash.md
  $ cl check dash.md
  dash.md:1: the first line of area "Coverage" does not start with "- "
  [1]
  $ printf '### Coverage\n\n- x.\n## v1\n' > h2.md
  $ cl check h2.md
  h2.md:4: a heading that is not an area heading
  [1]
  $ printf '### Coverage\n\n- x:\n\n```sh\n# c\n```\n' > code.md
  $ cl check code.md
  code.md:6: a heading that is not an area heading
  [1]

The check ignores the spaces around the name of an area.

  $ printf '###  Coverage \n\n- x.\n' > spaces.md
  $ cl check spaces.md

With no fragment, the check gives no error and the join does not change
the changelog.

  $ cl check
  $ mkdir changes
  $ cat > CHANGES.md <<'EOF'
  > # Changelog
  > 
  > ## Unreleased
  > 
  > Intro.
  > 
  > ### Highlights
  > 
  > A highlight.
  > 
  > ### Mutation testing
  > 
  > - Old line.
  > 
  > ## v0.1.0 2026-01-01
  > 
  > ### Coverage
  > 
  > - Released line.
  > EOF
  $ cp CHANGES.md before
  $ cl join CHANGES.md changes
  $ cmp before CHANGES.md

The join puts the lines of each area after the lines that the entry has,
in the order of the file names. It puts the areas in the order of the
list. Then it deletes the fragments. It ignores the dune file, each
hidden file, each name that ends with "~" or ".swp", and each directory
with a name that starts with "_". Dune does not copy these entries into
_build, except some hidden files.

  $ printf '### Mutation testing\n\n- From b.\n' > changes/b.md
  $ printf '### Mutation testing\n\n- From a,\n  two lines.\n\n### Declaring tests\n\n- New.\n' > changes/a.md
  $ touch changes/dune
  $ printf 'junk\n' > changes/.x.md
  $ touch 'changes/.#a.md'
  $ printf 'junk\n' > 'changes/a.md~'
  $ printf 'junk\n' > changes/a.md.swp
  $ mkdir changes/_old
  $ printf 'junk\n' > changes/_old/c.md
  $ cl join CHANGES.md changes
  $ ls -A changes
  .#a.md
  .x.md
  _old
  a.md.swp
  a.md~
  dune
  $ rm -r changes/.x.md changes/.#a.md 'changes/a.md~' changes/a.md.swp changes/_old
  $ cat CHANGES.md
  # Changelog
  
  ## Unreleased
  
  Intro.
  
  ### Highlights
  
  A highlight.
  
  ### Declaring tests
  
  - New.
  
  ### Mutation testing
  
  - Old line.
  - From a,
    two lines.
  - From b.
  
  ## v0.1.0 2026-01-01
  
  ### Coverage
  
  - Released line.

If one fragment has an error, the join changes no file.

  $ cp CHANGES.md before
  $ printf '### Coverage\n\n- Good.\n' > changes/a.md
  $ printf '### Coverage\n\nBad.\n' > changes/b.md
  $ cl join CHANGES.md changes
  changes/b.md:1: the first line of area "Coverage" does not start with "- "
  [1]
  $ cmp before CHANGES.md
  $ ls changes
  a.md
  b.md
  dune

A directory or a file without the suffix .md in the directory of
fragments gives exit code 1, for the join and for the check of the
directory. The join then changes no file.

  $ cp CHANGES.md before
  $ mkdir changes/feat
  $ cp changes/a.md changes/feat/x.md
  $ cl join CHANGES.md changes
  changes/feat: not a file with the suffix .md
  [1]
  $ cl check changes
  changes/feat: not a file with the suffix .md
  [1]
  $ rm -r changes/feat
  $ cp changes/a.md changes/mutate-retry
  $ cl join CHANGES.md changes
  changes/mutate-retry: not a file with the suffix .md
  [1]
  $ cl check changes
  changes/mutate-retry: not a file with the suffix .md
  [1]
  $ cmp before CHANGES.md
  $ ls changes
  a.md
  b.md
  dune
  mutate-retry
  $ rm changes/mutate-retry

The check of the directory does a check of each fragment in it.

  $ cl check changes
  changes/b.md:1: the first line of area "Coverage" does not start with "- "
  [1]

If the changelog has no open entry, the join adds one above the first
release.

  $ rm changes/b.md
  $ printf '# Changelog\n\n## v0.1.0 2026-01-01\n\n- Released line.\n' > CHANGES.md
  $ cl join CHANGES.md changes
  $ cat CHANGES.md
  # Changelog
  
  ## Unreleased
  
  ### Coverage
  
  - Good.
  
  ## v0.1.0 2026-01-01
  
  - Released line.

If the entry of the changelog has an error, the join changes no file.

  $ printf '### Running tests\n\n- y.\n' > changes/a.md
  $ printf '# Changelog\n\n## Unreleased\n\n### Coverage\n\n- x.\n\n### Bogus\n\n- z.\n' > CHANGES.md
  $ cp CHANGES.md before
  $ cl join CHANGES.md changes
  CHANGES.md:9: unknown area "Bogus"; the areas are: Declaring tests, Assertions, Property testing, Stateful testing, Baselines and expect tests, Resources and process state, Running tests, Coverage, Mutation testing, Packages and libraries
  [1]
  $ cmp before CHANGES.md
  $ ls changes
  a.md
  dune

A file that does not exist gives exit code 1.

  $ cl check nofile.md
  nofile.md: No such file or directory
  [1]

With no command, the tool shows the usage and gives exit code 2.

  $ cl
  usage: changelog check PATH...
         changelog join CHANGES DIR
  [2]
