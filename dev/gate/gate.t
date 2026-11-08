The gate reads the line of the merge, and not the exit code of the build.
The lines of the time and the memory change from run to run.

  $ cat > b <<'X'
  > mutants=12
  > memory_mb=100000
  > minutes=5
  > X
  $ sh ./self-mutate.sh b -- sh -c "echo 'mutants: 1 survived of 10 reached, 9 killed, 2 never reached, 3 executables, score 90.0% (9/10)'; exit 1" > out 2>&1; echo "exit $?"
  exit 0
  $ grep -v 'MB more memory' out
  gate: mutants: 1 survived of 10 reached, 9 killed, 2 never reached, 3 executables, score 90.0% (9/10)
  gate: 12 mutants

More mutants than the bounds give a failure, so that a PR that adds
mutants measures the bounds again.

  $ sed -i 's/mutants=12/mutants=11/' b
  $ sh ./self-mutate.sh b -- sh -c "echo 'mutants: 1 survived of 10 reached, 9 killed, 2 never reached, 3 executables, score 90.0% (9/10)'" > out 2>&1; echo "exit $?"
  exit 1
  $ grep -v 'MB more memory' out
  gate: mutants: 1 survived of 10 reached, 9 killed, 2 never reached, 3 executables, score 90.0% (9/10)
  gate: 12 mutants
  gate: 12 mutants is more than the 11 of the bounds. Measure the bounds again.

A build with no merge line fails, and shows the end of its log.

  $ sh ./self-mutate.sh b -- sh -c 'echo Error: Dependency cycle; exit 1' > out 2>&1; echo "exit $?"
  exit 1
  $ grep -v 'MB more memory' out
  gate: no merge line
  gate: the merge gave no result; the end of the log follows
  Error: Dependency cycle

A bounds file without a number fails before the build.

  $ printf 'mutants=12\nmemory_mb=lots\nminutes=5\n' > c
  $ sh ./self-mutate.sh c -- true; echo "exit $?"
  gate: ./c sets no number for memory_mb
  exit 2
