### Mutation testing

- `--sample=PCT` (mirror `WINDTRAP_SAMPLE`) tests only a fixed part of
  `PCT` percent of the reached mutants. A hash of the identifier of a
  mutant and of the seed of the run selects the part. Thus one seed
  keeps one sample, and a change to one file does not change the sample
  of another file. `--sample=100` is no sample. If neither the command
  line nor a mirror gives `--mutate`, the flag on the command line is a
  usage error (doc/manual/mutation.md#testing-a-sample-of-the-mutants).
- The verdict file records a reached mutant out of the sample as not
  sampled. The reach counts it. The outcome line gives the count, and
  gives the score and the total as estimates with a 95% Wilson interval,
  as `score 70.0% (70/100, 63.4% to 75.9%)`. One line above the outcome
  line gives the sample and the seed.
- `windtrap mutants` gives the intervals when the files of the tested
  suites have one sample. `--min` and `--min-total` then compare the
  lower bound. With different samples, the command gives no interval
  and a note, and the gates count each mutant out of a sample as
  survived. A mutant killed elsewhere is an exact kill beside the
  estimate of the sample. With exact kills and no scored mutant in the
  sample, the gates compare the lower bound of these kills. Without a gate, a merge with a mutant that is
  not sampled exits 1. `--max-survivors` with a sampled file is a usage
  error. The `--json` document gives the verdict `not_sampled`, and the
  sample and the bounds in `summary`. It gives `null` for the score and
  the total of a sample with no scored mutant
  (doc/manual/mutation.md#gates-on-a-sample).
