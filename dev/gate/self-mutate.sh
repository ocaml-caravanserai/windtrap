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
    '' | *[!0-9]*) echo "gate: $bounds sets no number for $v" >&2; exit 2 ;;
  esac
done

if [ $# -eq 0 ]; then
  set -- env SKIP_PACKAGE_SESSIONS=true WINDTRAP_MUTATE=1 \
    dune build @self-mutate --force --instrument-with ppx_windtrap.mutate
fi

log=$(mktemp)
peak=$(mktemp)
trap 'rm -f "$log" "$peak"' EXIT

used_kb() {
  awk '/^MemTotal:/ {t = $2} /^MemAvailable:/ {a = $2} END {print t - a}' \
    /proc/meminfo
}

base=$(used_kb)
echo 0 > "$peak"
(
  while :; do
    u=$(( $(used_kb) - base ))
    [ "$u" -gt "$(cat "$peak")" ] && echo "$u" > "$peak"
    sleep 5
  done
) &
sampler=$!

start=$(date +%s)
timeout "$(( minutes * 60 ))s" "$@" > "$log" 2>&1
code=$?
end=$(date +%s)
kill "$sampler" 2> /dev/null
wait "$sampler" 2> /dev/null

used_mb=$(( $(cat "$peak") / 1024 ))
took=$(( (end - start + 59) / 60 ))
line=$(grep '^mutants: .* executables' "$log" | tail -n 1)
echo "gate: $took min, $used_mb MB more memory, exit $code"
echo "gate: ${line:-no merge line}"

fail=0
if [ "$code" -eq 124 ]; then
  echo "gate: the run passed its bound of $minutes min" >&2
  fail=1
fi
if [ -z "$line" ]; then
  echo "gate: the merge gave no result; the end of the log follows" >&2
  tail -n 40 "$log" >&2
  exit 1
fi
reached=$(echo "$line" | sed -n 's/.* of \([0-9]*\) reached,.*/\1/p')
never=$(echo "$line" | sed -n 's/.* \([0-9]*\) never reached,.*/\1/p')
total=$(( ${reached:-0} + ${never:-0} ))
echo "gate: $total mutants"
if [ "$used_mb" -gt "$memory_mb" ]; then
  echo "gate: the memory passed its bound of $memory_mb MB" >&2
  fail=1
fi
if [ "$total" -gt "$mutants" ]; then
  echo "gate: $total mutants is more than the $mutants of the bounds." \
    "Measure the bounds again." >&2
  fail=1
fi
exit $fail
