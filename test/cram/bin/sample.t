Under --sample, a mutation run tests only a fixed part of the reached
mutants. pins_add.exe pins calc.ml's add and only reaches sub and shared,
so a full run kills one mutant and lets two survive. Under the root seed of
a mutation run, a sample of 50% holds the mutants of lines 12 and 13, and
not the mutant of line 14.

The executable runs from a scratch build directory, where it writes its
verdict file. --mutate scopes the loop to calc.ml's mutants, because under
--instrument-with the executable also links an instrumented core.

  $ bin=$PWD
  $ run() {
  >   env -i PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" WINDTRAP_COLOR=never WINDTRAP_SLOW_THRESHOLD=0 "$@" \
  >     > "$bin/out" 2> "$bin/err"
  >   code=$?; cat "$bin/out"
  >   if [ -s "$bin/err" ]; then echo '--- stderr'; cat "$bin/err"; fi
  >   return $code
  > }
  $ root=$(cd "$(mktemp -d)" && pwd -P) && cd "$root"
  $ mkdir -p _build/default/test test/cram/bin
  $ cp "$bin/calc.ml" "$bin/pins_add.ml" test/cram/bin/
  $ cp "$bin/pins_add.exe" _build/default/test/
  $ exe=_build/default/test/pins_add.exe
  $ scope=--mutate=test/cram/bin/calc.ml
  $ verdicts() { grep -e SURVIVED -e '^sample:' -e '^mutants:' -e '^--- stderr' "$bin/out"; }

A full run kills one mutant and lets two survive:

  $ run $exe $scope > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b
    SURVIVED  test/cram/bin/calc.ml:14:17:sub  a + b → a - b
  mutants: 2 survived of 3 reached by this suite, 1 killed, 1 never reached, score 33.3% (1/3), reach 75.0% (3/4), total 25.0% (1/4)

The sample gives the verdict of its mutants, and records the survivor of
line 14 of the full run as not sampled. The line above the outcome line
gives the sample and the seed:

  $ run $exe $scope --sample=50 > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b
  sample: 50% of the reached mutants, seed s1:6d7574616e747321
  mutants: 1 survived of 3 reached by this suite, 1 killed, 1 never reached, 1 not sampled, score 50.0% (1/2, 15.0% to 85.0%), reach 75.0% (3/4), total 37.5% (11.3% to 63.7%)

The mirror does the same under --mutate:

  $ run env WINDTRAP_SAMPLE=50 $exe $scope > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b
  sample: 50% of the reached mutants, seed s1:6d7574616e747321
  mutants: 1 survived of 3 reached by this suite, 1 killed, 1 never reached, 1 not sampled, score 50.0% (1/2, 15.0% to 85.0%), reach 75.0% (3/4), total 37.5% (11.3% to 63.7%)

Another seed gives another sample:

  $ run $exe $scope --sample=50 --seed=s1:0000000000000003 > /dev/null; verdicts
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b
  sample: 50% of the reached mutants, seed s1:0000000000000003
  mutants: 1 survived of 3 reached by this suite, 1 never reached, 2 not sampled, score 0.0% (0/1, 0.0% to 79.3%), reach 75.0% (3/4), total 0.0% (0.0% to 59.5%)
  $ run $exe $scope --sample=50 > /dev/null

windtrap mutants gives the estimates of the sample, with their intervals,
and the line of the sample:

  $ run windtrap mutants
  ───────────────────── survivors (1) ──────────────────────
  File "test/cram/bin/calc.ml", line 13, characters 14-19:
    SURVIVED  test/cram/bin/calc.ml:13:14:add  a - b → a + b
        13 │ let sub a b = a - b
  
      1 test ran this line and did not fail:
        pins_add.exe  sub › sub is nonzero
  ──────────────────────────────────────────────────────────
  
  ─────────────────── never reached (1) ────────────────────
    1  test/cram/bin/calc.ml   line 15
  ──────────────────────────────────────────────────────────
  
  sample: 50% of the reached mutants, seed s1:6d7574616e747321
  reproduce: dune exec --instrument-with ppx_windtrap.mutate test/pins_add.exe -- --arm test/cram/bin/calc.ml:13:14:add
  mutants: 1 survived of 3 reached, 1 killed, 1 never reached, 1 not sampled, 1 executable, score 50.0% (1/2, 15.0% to 85.0%), reach 75.0% (3/4), total 37.5% (11.3% to 63.7%)
  --- stderr
  windtrap: 1 mutant is not sampled, so no gate tells that each mutant was killed: give --min or --min-total to gate a sample
  [1]

--min and --min-total compare the lower bound of the interval:

  $ run windtrap mutants --min=1 --min-total=1 | tail -n 1
  mutants: 1 survived of 3 reached, 1 killed, 1 never reached, 1 not sampled, 1 executable, score 50.0% (1/2, 15.0% to 85.0%), minimum 1% of the lower bound: ok, reach 75.0% (3/4), total 37.5% (11.3% to 63.7%), minimum 1% of the lower bound: ok
  $ run windtrap mutants --min=10 | tail -n 1
  mutants: 1 survived of 3 reached, 1 killed, 1 never reached, 1 not sampled, 1 executable, score 50.0% (1/2, 15.0% to 85.0%), minimum 10% of the lower bound: ok, reach 75.0% (3/4), total 37.5% (11.3% to 63.7%)

--max-survivors does not gate a sample, because the sample does not count
each survivor:

  $ run windtrap mutants --max-survivors=5 > /dev/null
  [2]
  $ sed -E 's|[^ ]*/windtrap-[0-9a-f-]*\.mutants|FILE|' "$bin/err"
  windtrap: --max-survivors cannot gate a sample: FILE tested only a sample of its reached mutants, so the merge does not count each survivor

The document gives the sample, the bounds and the mutants that are not
sampled:

  $ run windtrap mutants --json | grep -E '"(not_sampled|sample_percent|score_low|total_low|sample)"|"verdict"'
      "not_sampled": 1,
      "sample_percent": 50, "sample_seed": "s1:6d7574616e747321",
      "score_low": 15.00, "score_high": 85.00,
      "total_low": 11.25, "total_high": 63.75 },
        "sample": { "percent": 50, "seed": "s1:6d7574616e747321" } } ],
        "verdict": "killed",
        "verdict": "survived",
        "verdict": "not_sampled" },
        "verdict": "unreached" } ],

The flag without --mutate is a usage error. The mirror alone has no effect
on a run that does not mutate. The mirror refuses a value that is not a
percentage:

  $ run $exe --sample=50
  --- stderr
  windtrap: option '--sample' scopes '--mutate', which is not given
  usage: pins_add.exe [OPTIONS] [PATTERN...]
  [2]
  $ run env WINDTRAP_SAMPLE=50 $exe | sed -E 's/ in [0-9.]+[mµ]?s\././'
  pins_add: 5 passed.
  $ run env WINDTRAP_SAMPLE=0 $exe $scope > /dev/null; head -n 1 "$bin/err"
  windtrap: invalid value '0' for WINDTRAP_SAMPLE: expected a percentage above 0 and at most 100

Files that tested their suite with different samples give the estimates
with no interval. A note says why, and the gates count each mutant that is
not sampled as survived:

  $ mkdir merge && cd merge
  $ "$bin/mkdata.exe" mutants a.mutants --suite a --sample 50 42 \
  >   'lib/a.ml:1:0:add:a + b:a - b=killed' 'lib/a.ml:2:0:add:a + b:a - b=not_sampled' \
  >   'lib/a.ml:3:0:add:a + b:a - b=survived:t/s' 'lib/a.ml:4:0:add:a + b:a - b=unreached'
  $ "$bin/mkdata.exe" mutants b.mutants --suite b --sample 25 42 \
  >   'lib/b.ml:1:0:add:a + b:a - b=killed' 'lib/b.ml:2:0:add:a + b:a - b=not_sampled'
  $ run windtrap mutants --min=50 a.mutants b.mutants | grep -e '^mutants:' -e '^windtrap:'
  mutants: 1 survived of 5 reached, 2 killed, 1 never reached, 2 not sampled, 2 executables, score 66.7% (2/3, at least 40.0%), minimum 50% of the lower bound: FAILED, reach 83.3% (5/6), total 55.6% (at least 33.3%)
  windtrap: the verdict files that tested their suite have different samples, so the score and the total have no interval: --min and --min-total count each mutant that is not sampled as survived, and with no scored mutant in the sample, each mutant that the hash judged
  $ run windtrap mutants --min=20 a.mutants b.mutants | grep -e '^mutants:' -e '^windtrap:'
  mutants: 1 survived of 5 reached, 2 killed, 1 never reached, 2 not sampled, 2 executables, score 66.7% (2/3, at least 40.0%), minimum 20% of the lower bound: ok, reach 83.3% (5/6), total 55.6% (at least 33.3%)
  windtrap: the verdict files that tested their suite have different samples, so the score and the total have no interval: --min and --min-total count each mutant that is not sampled as survived, and with no scored mutant in the sample, each mutant that the hash judged
  $ run windtrap mutants --json a.mutants b.mutants | grep -E '"(not_sampled|sample_percent|score_low|sample)"'
      "not_sampled": 2 },
        "sample": { "percent": 50, "seed": "s1:000000000000002a" } },
        "sample": { "percent": 25, "seed": "s1:000000000000002a" } } ],
        "verdict": "not_sampled" },
        "verdict": "not_sampled" } ],

Files of one sample give the interval. A refused file does not count for the
rule:

  $ "$bin/mkdata.exe" mutants b.mutants --suite b --sample 50 42 \
  >   'lib/b.ml:1:0:add:a + b:a - b=killed' 'lib/b.ml:2:0:add:a + b:a - b=not_sampled'
  $ "$bin/mkdata.exe" mutants c.mutants --suite c --refused 'it crashed' \
  >   'lib/c.ml:1:0:add:a + b:a - b=unknown:it crashed'
  $ run windtrap mutants a.mutants b.mutants c.mutants | grep '^mutants:'
  mutants: 1 survived of 6 reached, 2 killed, 1 unknown, 1 never reached, 2 not sampled, 3 executables, 1 suite not mutation-tested, score 66.7% (2/3, 32.1% to 89.4%), reach 85.7% (6/7), total 54.5% (26.3% to 73.2%)

A refused file counts its unknown mutants in the estimate, and the merge
fails anyway.

A mutant killed elsewhere is an exact kill, and the hash did not judge
it. The estimate adds such kills as they are, beside the estimate of the
sample. Here 50 skips stand, and the sample of 25 of 50 mutants has 5
kills:

  $ mkdir ../exact && cd ../exact
  $ specs() { for i in $(seq "$2" "$3"); do echo "lib/e.ml:$i:0:add:a+b:a-b=$1"; done; }
  $ "$bin/mkdata.exe" mutants e.mutants --suite e --sample 50 42 \
  >   $(specs elsewhere:default/gone.exe 1 50) $(specs not_sampled 51 75) \
  >   $(specs killed 76 80) $(specs survived:t/s 81 100)
  $ run windtrap mutants --min=65 e.mutants | grep '^mutants:'
  mutants: 20 survived of 100 reached, 55 killed, 25 not sampled, 1 executable, score 60.0% (5/25 and 50 killed elsewhere, 55.6% to 66.6%), minimum 65% of the lower bound: FAILED, reach 100.0% (100/100), total 60.0% (55.6% to 66.6%)
  $ run windtrap mutants --json e.mutants | grep -E '"(score|score_low|score_high)"'
      "unreached": 0, "refused": 0, "score": 60.00,
      "score_low": 55.59, "score_high": 66.59,

Without a gate, a merge with a mutant that is not sampled exits 1, because
the sample does not tell that each mutant was killed. A sampled file can
also hide the survivor of a full file:

  $ "$bin/mkdata.exe" mutants k.mutants --suite k --sample 50 42 \
  >   'lib/k.ml:1:0:add:a+b:a-b=killed' 'lib/k.ml:2:0:add:a+b:a-b=not_sampled' \
  >   'lib/k.ml:3:0:add:a+b:a-b=not_sampled'
  $ run windtrap mutants k.mutants > /dev/null
  [1]
  $ grep '^mutants:' "$bin/out"; cat "$bin/err"
  mutants: 3 reached, 1 killed, 2 not sampled, 1 executable, score 100.0% (1/1, 20.7% to 100.0%), reach 100.0% (3/3), total 100.0% (20.7% to 100.0%)
  windtrap: 2 mutants are not sampled, so no gate tells that each mutant was killed: give --min or --min-total to gate a sample
  $ "$bin/mkdata.exe" mutants full.mutants --suite full \
  >   'lib/k.ml:2:0:add:a+b:a-b=survived:t/s'
  $ run windtrap mutants k.mutants full.mutants > /dev/null
  [1]
  $ grep '^mutants:' "$bin/out"; cat "$bin/err"
  mutants: 3 reached, 1 killed, 2 not sampled, 2 executables, score 100.0% (1/1, at least 33.3%), reach 100.0% (3/3), total 100.0% (at least 33.3%)
  windtrap: the verdict files that tested their suite have different samples, so the score and the total have no interval: --min and --min-total count each mutant that is not sampled as survived, and with no scored mutant in the sample, each mutant that the hash judged
  windtrap: 2 mutants are not sampled, so no gate tells that each mutant was killed: give --min or --min-total to gate a sample

A gate gives the exit code, also for a sample:

  $ run windtrap mutants --min=0 k.mutants | grep '^mutants:'
  mutants: 3 reached, 1 killed, 2 not sampled, 1 executable, score 100.0% (1/1, 20.7% to 100.0%), minimum 0% of the lower bound: ok, reach 100.0% (3/3), total 100.0% (20.7% to 100.0%)

--sarif gives no result for a mutant that is not sampled:

  $ run windtrap mutants --sarif full.mutants | grep -c '"ruleId"'
  1
  $ run windtrap mutants --sarif k.mutants | grep -c '"ruleId"' || true
  0

The document gives null for the score and the total of a sample with no
scored mutant, beside an interval of 0 to 100:

  $ "$bin/mkdata.exe" mutants z.mutants --suite z --sample 50 42 \
  >   'lib/z.ml:1:0:add:a+b:a-b=not_sampled'
  $ run windtrap mutants --json z.mutants | grep -E '"(score|total_percent|score_low|total_low)"'
      "unreached": 0, "refused": 0, "score": null,
      "reach_percent": 100.00, "total_percent": null,
      "score_low": 0.00, "score_high": 100.00,
      "total_low": 0.00, "total_high": 100.00 },

With exact kills, a sample of no scored mutant has a lower bound: each
mutant that the hash judged can be a survivor:

  $ specs() { for i in $(seq "$2" "$3"); do echo "lib/x.ml:$i:0:add:a+b:a-b=$1"; done; }
  $ "$bin/mkdata.exe" mutants x.mutants --suite x --sample 50 42 \
  >   $(specs elsewhere:default/gone.exe 1 50) $(specs not_sampled 51 52)
  $ run windtrap mutants --min=50 x.mutants | grep '^mutants:'
  mutants: 52 reached, 50 killed, 2 not sampled, 1 executable, score: no scored mutant in the sample (50 killed elsewhere, at least 96.2%), minimum 50% of the lower bound: ok, reach 100.0% (52/52)
  $ run windtrap mutants --json x.mutants | grep -E '"(score|total_percent|score_low|total_low)"'
      "unreached": 0, "refused": 0, "score": null,
      "reach_percent": 100.00, "total_percent": null,
      "score_low": 96.15, "score_high": 100.00,
      "total_low": 96.15, "total_high": 100.00 },
