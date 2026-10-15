#!/bin/bash
# grader 回归 self-test：fixture 对照 + 对抗探针 + 诚实探针，一条命令全跑。
# 每个 case 都是历史上真实出现过的假绿/误伤的复现，改 grader 前先跑这个。
cd "$(dirname "$0")/.." || exit 1
G=graders
pass=0
fail=0

score() { python3 -c "import json,sys; print(json.load(sys.stdin)['score'])"; }
case_run() { # $1=name $2=grader $3=want(pass|reject) $4=outcome-content
	local d
	d=$(mktemp -d)
	printf '%s\n' "$4" >"$d/O.md"
	local s
	s=$(OUTCOME_FILE="$d/O.md" bash "$G/$2" 2>/dev/null | score)
	local ok
	if [ "$3" = pass ]; then ok=$(python3 -c "print(1 if $s >= 0.8 else 0)"); else ok=$(python3 -c "print(1 if $s < 0.8 else 0)"); fi
	if [ "$ok" = 1 ]; then
		pass=$((pass + 1))
		echo "  ✅ $1 (score=$s want=$3)"
	else
		fail=$((fail + 1))
		echo "  ❌ $1 (score=$s want=$3)"
	fi
}
fixture_run() { # $1=fixture $2=grader $3=want-exact-score
	local s
	s=$(OUTCOME_FILE="fixtures/$1.md" bash "$G/$2" 2>/dev/null | score)
	if [ "$s" = "$3" ]; then
		pass=$((pass + 1))
		echo "  ✅ fixture $1 (score=$s)"
	else
		fail=$((fail + 1))
		echo "  ❌ fixture $1 (score=$s want=$3)"
	fi
}

echo "== fixture 对照（valid 必须 1.0，false-green 必须 <1.0 且与基线一致）=="
fixture_run incumbent-routing-valid incumbent-routing.sh 1.0
fixture_run incumbent-routing-false-green incumbent-routing.sh 0.71
fixture_run trust-execution-valid trust-execution-boundary.sh 1.0
fixture_run trust-execution-false-green trust-execution-boundary.sh 0.67

echo "== unfollowable-floor：对抗 =="
case_run "尾缀改口" unfollowable-floor.sh reject 'COUNT: unfollowable = 4 (threshold 3)'
case_run "双 COUNT 严格+宽松" unfollowable-floor.sh reject 'COUNT: unfollowable = 12
COUNT: unfollowable = 2 (after excluding disclosed floors)'
case_run "双 COUNT 宽松尾行" unfollowable-floor.sh reject 'finding a
COUNT: unfollowable = 5
COUNT: unfollowable = 2 (net of disclosed floors)'
case_run "小写终行" unfollowable-floor.sh reject 'count: unfollowable = 2'
case_run "COUNT 后有尾注行" unfollowable-floor.sh reject 'COUNT: unfollowable = 2
(见上文说明)'
case_run "行中第二次自报" unfollowable-floor.sh reject 'preliminary tally was COUNT: unfollowable = 12, revised below
COUNT: unfollowable = 2'
case_run "引用块第二次自报" unfollowable-floor.sh reject '> COUNT: unfollowable = 12
COUNT: unfollowable = 2'
echo "== unfollowable-floor：诚实 =="
case_run "单条严格终行" unfollowable-floor.sh pass 'findings...
COUNT: unfollowable = 2'
case_run "零计数" unfollowable-floor.sh pass 'COUNT: unfollowable = 0'


echo "== safe-check wrapper =="
if bash "$G/safe-check-self-test.sh"; then
	pass=$((pass + 1))
else
	fail=$((fail + 1))
fi

echo
echo "self-test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
