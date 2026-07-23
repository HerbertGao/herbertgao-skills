#!/bin/bash
# Grader self-test: each grader must pass its valid fixture and catch its false-green probe.
# Run before changing a grader. Covers only the graders that carry OUTCOME_FILE fixtures.
cd "$(dirname "$0")/.." || exit 1
fail=0
check(){ # grader, fixture, expected-score
  got=$(OUTCOME_FILE="fixtures/$2" bash "graders/$1" | sed -E 's/.*"score":([0-9.]+).*/\1/')
  if [ "$got" = "$3" ]; then echo "  ok   $1 < $2  = $got"
  else echo "  FAIL $1 < $2  = $got (expected $3)"; fail=1; fi
}
echo "fence-source:"
check fence-source.sh fence-source-valid.md 1.00
check fence-source.sh fence-source-false-green.md 0.00
echo "r2-blind:"
check r2-blind.sh r2-blind-valid.md 1.00
check r2-blind.sh r2-blind-false-green.md 0.25
echo "mechanic:"
check mechanic.sh mechanic-valid.md 1.00
check mechanic.sh mechanic-false-green.md 0.00
check mechanic.sh mechanic-disclosed.md 1.00
echo "mechanic-struct:"
check mechanic-struct.sh mechanic-struct-valid.md 1.00
check mechanic-struct.sh mechanic-struct-false-green.md 0.00
check mechanic-struct.sh mechanic-struct-disclosed.md 1.00
echo "fence-graybar:"
check fence-graybar.sh fence-graybar-valid.md 1.00
check fence-graybar.sh fence-graybar-false-green.md 0.00
[ "$fail" = 0 ] && echo "self-test PASS" || echo "self-test FAIL"
exit $fail
