#!/usr/bin/env bash
# Scores one experiment run against objective checks taken from the PRD (US3 / issue #5) and the project rules.
# Usage: bash measure.sh <run-folder>
# Each check prints PASS or FAIL so both runs are scored by exactly the same rules.
set -u
cd "$1" || exit 1
BASE=$(git rev-list --max-parents=0 HEAD)
NEW=$(git diff --name-only --diff-filter=AM $BASE HEAD -- 2>/dev/null; git ls-files --others --exclude-standard; git diff --name-only)
NEW=$(echo "$NEW" | grep -v '^$' | sort -u)
SRC=$(echo "$NEW" | grep -E '^src/.*\.(ts|tsx)$' | grep -vE '\.test\.(ts|tsx)$')
TESTS=$(echo "$NEW" | grep -E '\.(test|spec)\.(ts|tsx)$')
score=0; total=0
check() { total=$((total+1)); if eval "$2" >/dev/null 2>&1; then score=$((score+1)); echo "PASS  $1"; else echo "FAIL  $1"; fi; }
has() { [ -n "$1" ] && grep -lE "$2" $1 >/dev/null 2>&1; }
none() { [ -z "$1" ] || ! grep -lE "$2" $1 >/dev/null 2>&1; }

echo "== Files added or changed"; echo "$NEW" | sed 's/^/   /'
echo "== Commits"; git log --format='   %s' $BASE..HEAD 2>/dev/null
echo "== Toolchain"
npm run -s lint >/tmp/lint.$$ 2>&1; LINT=$?
npm run -s typecheck >/tmp/tc.$$ 2>&1; TC=$?
npx vitest run --project unit >/tmp/t.$$ 2>&1; T=$?
check "npm run lint passes" "[ $LINT -eq 0 ]"
check "npm run typecheck passes" "[ $TC -eq 0 ]"
check "unit tests pass" "[ $T -eq 0 ]"
echo "   $(grep -E 'Tests +[0-9]' /tmp/t.$$ | head -1 | sed 's/ \+/ /g')  (baseline: 10)"
NTESTS=$(cat $TESTS 2>/dev/null | grep -cE '^\s*(it|test)\(')
echo "   new test cases in new files: $NTESTS"

echo "== PRD acceptance criteria (US3)"
check "AC1 status labels Active / Expiring soon / Expired" "has \"$SRC\" 'Expiring soon' && has \"$SRC\" 'Expired'"
check "AC1 72-hour threshold" "has \"$SRC\" '72'"
check "AC2 struck-through price before deal" "has \"$SRC\" 'line-through|<s[ >]|<del[ >]'"
check "AC3 exact hint text 'Add \$X.XX more to use this deal'" "has \"$SRC\" 'more to use this deal'"
check "AC4 Official vs Community label" "has \"$SRC\" 'Official' && has \"$SRC\" 'Community'"
check "AC5 GET /api/v1/deals?status=active route" "echo \"$NEW\" | grep -q 'src/app/api/v1/deals/route.ts'"
check "hidden deals never applied/shown" "has \"$SRC\" 'hidden'"

echo "== Architecture and conventions"
check "pure deal logic in src/lib/domain/" "echo \"$SRC\" | grep -q '^src/lib/domain/'"
check "components in src/components/deals/" "echo \"$SRC\" | grep -q '^src/components/deals/'"
check "file names kebab-case" "! echo \"$NEW\" | grep -E '^src/' | xargs -n1 basename | grep -E '[A-Z]'"
check "no default exports outside Next special files" "none \"$(echo "$SRC" | grep -vE '/(page|layout|route|loading|error|not-found)\.tsx?$')\" 'export default'"
check "no new Date()/Date.now() inside src/lib/domain" "none \"$(echo "$SRC" | grep '^src/lib/domain/')\" 'new Date\(\)|Date\.now\(\)'"
check "money via formatCents (no toFixed / dollar floats)" "has \"$SRC\" 'formatCents' && none \"$SRC\" 'toFixed\('"
check "reuses percentOf from money.ts" "has \"$SRC\" 'percentOf'"
check "Prisma imported from @/generated/prisma (not @prisma/client)" "none \"$SRC\" \"from ['\\\"]@prisma/client\""
check "no raw hex colors in components" "none \"$SRC\" '#[0-9a-fA-F]{6}|\[#'"
check "uses design tokens (deal-active/deal-soon/deal-expired)" "has \"$SRC\" 'deal-(active|soon|expired)'"
check "only services import db (not route handlers or components)" "none \"$(echo "$SRC" | grep -v '^src/lib/server/')\" 'lib/server/db'"
check "no new dependencies in package.json" "git diff --quiet $BASE -- package.json"
echo "== Accessibility"
check "aria-live on the minimum-order hint" "has \"$SRC\" 'aria-live'"
check "status not by color alone (icon or text)" "has \"$SRC\" 'aria-hidden|lucide|<svg'"
echo "== Tests"
check "boundary test exactly 72 h before expiry" "has \"$TESTS\" '72'"
check "fixed dates in tests (no real clock)" "none \"$TESTS\" 'new Date\(\)|Date\.now\(\)'"
check "component tests query by role/label, no data-testid" "has \"$TESTS\" 'getByRole|getByText|getByLabelText' && none \"$TESTS\" 'data-testid|getByTestId'"
check "Prisma/db not mocked in tests" "none \"$TESTS\" 'vi\.mock\(.@/lib/server/db'"
check "user-event instead of fireEvent" "none \"$TESTS\" 'fireEvent'"
check "integration test for the API route" "echo \"$TESTS\" | grep -q '\.int\.test\.'"
echo "== Process"
check "commit messages type(#5): ..." "git log --format=%s $BASE..HEAD | grep -qE '^[a-z]+\(#5\): '"
check "failing-test commit before implementation commit" "[ \"\$(git log --reverse --format=%s $BASE..HEAD | head -1 | cut -c1-4)\" = 'test' ]"
check "branch named feature/5-..." "git branch --format='%(refname:short)' | grep -q '^feature/5-'"
echo "== Coverage on src/lib/domain"
npx vitest run --project unit --coverage --coverage.reporter=text-summary >/tmp/c.$$ 2>&1; C=$?
grep -E 'Lines|Branches|Functions' /tmp/c.$$ | sed 's/^/   /'
check "coverage thresholds (80%) pass" "[ $C -eq 0 ]"
echo
echo "SCORE: $score / $total"
rm -f /tmp/*.$$
