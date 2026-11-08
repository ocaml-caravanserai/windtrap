The gate reads the line of the merge, and not the exit code of the build.
The count adds the reached, the unreached and the outside mutants.
The line of the time and the memory changes from run to run.

  $ cat > b <<'X'
  > mutants=13
  > memory_mb=100000
  > minutes=5
  > X
  $ m='mutants: 1 survived of 10 reached, 2 never reached, 1 evaluated outside tests, 3 executables'
  $ run() {
  >   sh ./self-mutate.sh "$@" > out 2>&1; echo "exit $?"
  >   grep -v 'MB more memory' out
  > }
  $ run b -- sh -c "echo '$m'; exit 1"
  exit 0
  mutants: 1 survived of 10 reached, 2 never reached, 1 evaluated outside tests, 3 executables
  gate: mutants: 1 survived of 10 reached, 2 never reached, 1 evaluated outside tests, 3 executables
  gate: 13 mutants

A line with no survivor and no unreached mutant, in color and for one
executable, counts too.

  $ run b -- printf '\033[32mmutants: 10 reached\033[0m, 1 executable\n'
  exit 0
  mutants: 10 reached, 1 executable
  gate: mutants: 10 reached, 1 executable
  gate: 10 mutants
  $ head -n 1 out | cat -v
  ^[[32mmutants: 10 reached^[[0m, 1 executable

More mutants than the bounds give a failure, so that a pull request that
adds mutants measures the bounds again.

  $ sed -i 's/mutants=13/mutants=12/' b
  $ run b -- sh -c "echo '$m'"
  exit 1
  mutants: 1 survived of 10 reached, 2 never reached, 1 evaluated outside tests, 3 executables
  gate: mutants: 1 survived of 10 reached, 2 never reached, 1 evaluated outside tests, 3 executables
  gate: 13 mutants
  gate: 13 mutants is more than the bound of 12. Measure the bounds again.

A build with no merge line, or a line with no count, gives a failure.

  $ run b -- sh -c 'echo Error: Dependency cycle; exit 1'
  exit 1
  Error: Dependency cycle
  gate: no merge line
  gate: the merge gave no count of mutants
  $ run b -- echo 'mutants: many, 3 executables'
  exit 1
  mutants: many, 3 executables
  gate: mutants: many, 3 executables
  gate: the merge gave no count of mutants

A bounds file without a positive number fails before the build.

  $ printf 'mutants=12\nmemory_mb=lots\nminutes=5\n' > c
  $ run c -- true
  exit 2
  gate: ./c sets no positive number for memory_mb
  $ printf 'mutants=12\nmemory_mb=1\nminutes=0\n' > c
  $ run c -- true
  exit 2
  gate: ./c sets no positive number for minutes
