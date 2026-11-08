#!/bin/sh
# Gate 1 of the mutation plan: a full @self-mutate stays within the bounds
# of BOUNDS (default: bounds next to this script). Usage:
#
#   self-mutate.sh [BOUNDS] [-- COMMAND...]
#
# COMMAND replaces the build, for the test of this script. The build exits
# 1 when a mutant survives, so the gate reads the line of the merge and
# not the exit code.

set -u

here=$(dirname "$0")
bounds=$here/bounds
if [ $# -gt 0 ] && [ "$1" != "--" ]; then bounds=$1; shift; fi
if [ $# -gt 0 ] && [ "$1" = "--" ]; then shift; fi

case $bounds in */*) ;; *) bounds=./$bounds ;; esac
# shellcheck disable=SC1090
. "$bounds" || exit 2
for v in mutants memory_mb minutes; do
  eval "x=\${$v:-}"
  case $x in
    '' | *[!0-9]* | 0) echo "gate: $bounds sets no positive number for $v" >&2
      exit 2 ;;
  esac
done

if [ $# -eq 0 ]; then
  set -- env SKIP_PACKAGE_SESSIONS=true WINDTRAP_MUTATE=1 NO_COLOR=1 \
    dune build @self-mutate --force --instrument-with ppx_windtrap.mutate
fi

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

used_kb() {
  awk '/^MemTotal:/ {t = $2} /^MemAvailable:/ {a = $2} END {print t - a}' \
    /proc/meminfo
}

# The sampler reads the memory each 5 s, and prints the peak each 5 min,
# so that a job that the CI cancels keeps its measurements.
base=$(used_kb)
echo 0 > "$dir/peak"
(
  n=0
  while :; do
    u=$(( $(used_kb) - base ))
    if [ "$u" -gt "$(cat "$dir/peak")" ]; then
      echo "$u" > "$dir/next" && mv "$dir/next" "$dir/peak"
    fi
    n=$(( n + 1 ))
    if [ $(( n % 60 )) -eq 0 ]; then
      echo "gate: at $(( n / 12 )) min, $(( $(cat "$dir/peak") / 1024 )) MB" >&2
    fi
    sleep 5
  done
) &
sampler=$!

start=$(date +%s)
{
  timeout -k 5m "$(( minutes * 60 ))s" "$@" 2>&1
  echo $? > "$dir/code"
} | tee "$dir/log"
end=$(date +%s)
kill "$sampler" 2> /dev/null
wait "$sampler" 2> /dev/null

code=$(cat "$dir/code")
used_mb=$(( $(cat "$dir/peak") / 1024 ))
took=$(( (end - start + 59) / 60 ))
esc=$(printf '\033')
line=$(sed "s/$esc\[[0-9;]*m//g" "$dir/log" \
  | grep '^mutants: .* executable' | tail -n 1)
echo "gate: $took min, $used_mb MB more memory, exit $code"
echo "gate: ${line:-no merge line}"

fail=0
if [ "$code" -eq 124 ]; then
  echo "gate: the run took more than its bound of $minutes min" >&2
  fail=1
fi
if [ "$used_mb" -gt "$memory_mb" ]; then
  echo "gate: the memory grew more than its bound of $memory_mb MB" >&2
  fail=1
fi
count='s/^mutants: \([0-9]* survived of \)\{0,1\}\([0-9]*\) reached,.*/\2/p'
reached=$(echo "$line" | sed -n "$count")
never=$(echo "$line" | sed -n 's/.*[^0-9]\([0-9]*\) never reached.*/\1/p')
outside=$(echo "$line" \
  | sed -n 's/.*[^0-9]\([0-9]*\) evaluated outside tests.*/\1/p')
if [ -z "$reached" ]; then
  echo "gate: the merge gave no count of mutants" >&2
  exit 1
fi
total=$(( reached + ${never:-0} + ${outside:-0} ))
echo "gate: $total mutants"
if [ "$total" -gt "$mutants" ]; then
  echo "gate: $total mutants is more than the bound of $mutants." \
    "Measure the bounds again." >&2
  fail=1
fi
exit $fail
