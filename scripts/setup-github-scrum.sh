#!/usr/bin/env bash
# Sets up the GitHub Scrum workflow for TakeoutPick (HW3 Task 1). Safe to re-run: existing labels, milestones,
# issues and the project are reused, not duplicated.
#
# Usage (from the repo root, in Git Bash on Windows or any bash):
#   gh auth login                       # once
#   gh auth refresh -s project          # once: lets gh manage GitHub Projects
#   bash scripts/setup-github-scrum.sh                  # uses the repo of the current folder
#   bash scripts/setup-github-scrum.sh owner/takeoutpick
#   bash scripts/setup-github-scrum.sh --dry-run        # print what would happen, change nothing
#
# Run it from the account that OWNS the repo (a project can only be linked to a repo with the same owner).
# Run it BEFORE opening any pull request, so the issues get numbers #1–#14 that match docs/PRD.md.
# Only the gh CLI is required (its built-in --jq is used; no separate jq install).

set -euo pipefail

DRY_RUN=0
REPO=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h | --help) sed -n '2,15p' "$0"; exit 0 ;;
    *) REPO="$arg" ;;
  esac
done

if [[ -z "$REPO" ]]; then
  if ((DRY_RUN)); then REPO="owner/takeoutpick"; else REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner); fi
fi
OWNER="${REPO%%/*}"
PROJECT_TITLE="${PROJECT_TITLE:-TakeoutPick P2 Board}"
SPRINT1="Sprint 1"
SPRINT2="Sprint 2"

echo "Repo: $REPO   Project owner: $OWNER   Dry run: $DRY_RUN"

run() {
  if ((DRY_RUN)); then
    printf '[dry-run]'; printf ' %q' "$@"; printf '\n'
  else
    "$@"
  fi
}

# ---------------------------------------------------------------------------------------------------------------
# 1. Labels: type, priority, size (size doubles as the task estimate: S = 1–2 pts, M = 3 pts, L = 5 pts)
# ---------------------------------------------------------------------------------------------------------------
label() { run gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null; echo "label  $1"; }

label "feature"         "1d76db" "New user-facing capability"
label "bug"             "d73a4a" "Something is broken"
label "chore"           "c5def5" "Tooling, CI, setup, maintenance"
label "docs"            "0075ca" "Documentation"
label "priority:high"   "b60205" "Do first in the sprint"
label "priority:medium" "fbca04" "Do after the high-priority items"
label "priority:low"    "0e8a16" "Nice to have"
label "size:S"          "ededed" "Estimate 1–2 points"
label "size:M"          "bfdadc" "Estimate 3 points"
label "size:L"          "5319e7" "Estimate 5 points"

# ---------------------------------------------------------------------------------------------------------------
# 2. Milestones (one per sprint, with due dates)
# ---------------------------------------------------------------------------------------------------------------
ensure_milestone() {
  local title="$1" due="$2" desc="$3" existing=""
  if ((!DRY_RUN)); then
    existing=$(gh api "repos/$REPO/milestones?state=all&per_page=100" --jq ".[] | select(.title == \"$title\") | .number")
  fi
  if [[ -n "$existing" ]]; then
    echo "milestone exists  $title (#$existing)"
  else
    run gh api "repos/$REPO/milestones" -f title="$title" -f due_on="$due" -f description="$desc" >/dev/null
    echo "milestone  $title (due ${due%%T*})"
  fi
}

ensure_milestone "$SPRINT1" "2026-11-05T12:00:00Z" \
  "Oct 31 - Nov 5. Goal: scaffold, CI, auth, catalog with true totals, deals, compare, order log."
ensure_milestone "$SPRINT2" "2026-11-11T12:00:00Z" \
  "Nov 6 - Nov 11. Goal: Pick for me, real-time Group Pick, partner portal, admin console, public API, security scans, docs."

# ---------------------------------------------------------------------------------------------------------------
# 3. Issues (body read from stdin). Created in order so a fresh repo numbers them #1–#14.
# ---------------------------------------------------------------------------------------------------------------
ISSUE_URLS=()
ISSUE_STATUS=()
ISSUE_POINTS=()

new_issue() {
  local title="$1" labels="$2" milestone="$3" status="$4" points="$5" body url=""
  body=$(cat)
  if ((DRY_RUN)); then
    printf '[dry-run] issue  %-92s %-34s %-9s %-12s %s pts\n' "$title" "$labels" "$milestone" "$status" "$points"
    url="https://github.com/$REPO/issues/$(( ${#ISSUE_URLS[@]} + 1 ))"
  else
    url=$(gh issue list --repo "$REPO" --state all --limit 300 --json title,url \
      --jq ".[] | select(.title == \"$title\") | .url" | head -n1)
    if [[ -n "$url" ]]; then
      echo "issue exists  $url"
    else
      url=$(gh issue create --repo "$REPO" --title "$title" --body "$body" --label "$labels" --milestone "$milestone")
      echo "issue  $url  $title"
    fi
  fi
  ISSUE_URLS+=("$url")
  ISSUE_STATUS+=("$status")
  ISSUE_POINTS+=("$points")
}

# ---------------------------- Sprint 1 ----------------------------

new_issue "Scaffold Next.js app with Prisma schema and test tooling" \
  "chore,priority:high,size:M" "$SPRINT1" "Sprint Todo" 3 <<'EOF'
**Goal:** a running skeleton that both partners and the AI agent build on.
**Estimate:** 3 points

### Acceptance criteria
- [ ] Next.js 16 App Router + TypeScript strict + Tailwind 4 app runs with `npm run dev`
- [ ] `prisma/schema.prisma` models every entity in `docs/PRD.md` (users, restaurants, dishes, deals, orders, partner requests, rooms, nominations, votes) and `npx prisma validate` passes
- [ ] `docker compose up -d db` then `npm run db:migrate` creates the local database
- [ ] Vitest (unit + integration projects) and Playwright are configured; `npm test`, `npm run test:int` and `npm run test:e2e` each run at least one passing test
- [ ] `.env.example` lists every variable and `.env` is git-ignored
- [ ] `AGENTS.md` v1.0, `docs/PRD.md` and `docs/ui-spec.md` are committed
EOF

new_issue "Set up CI with lint, typecheck and tests on every PR plus Vercel previews" \
  "chore,priority:high,size:M" "$SPRINT1" "Sprint Todo" 3 <<'EOF'
**Goal:** every PR is checked automatically and gets a preview deployment.
**Estimate:** 3 points

### Acceptance criteria
- [ ] A GitHub Actions workflow runs on every PR and on pushes to `main` with stages: install, lint + typecheck, unit tests, integration tests (Postgres service container), build
- [ ] A failing stage blocks the merge (branch protection on `main` requires CI and 1 approving review)
- [ ] Vercel creates a preview deployment for every PR and posts its URL on the PR
- [ ] Development, Preview and Production have separate environment variables; previews use their own database branch
- [ ] The coverage report is uploaded as a workflow artifact
EOF

new_issue "Register, log in and log out with JWT cookie sessions (US1)" \
  "feature,priority:high,size:L" "$SPRINT1" "Sprint Todo" 5 <<'EOF'
**User story (docs/PRD.md US1):** As a diner, I want to register and log in, so that my orders and preferences follow me across devices.
**Estimate:** 5 points

### Acceptance criteria
- [ ] I can register with name, email and a password of at least 8 characters; a duplicate email is rejected with a clear message
- [ ] I can log in and log out; the session lasts 7 days
- [ ] The session is a signed JWT in an httpOnly, Secure, SameSite=Lax cookie
- [ ] Partner pages require role PARTNER and admin pages require ADMIN; the API answers 401 when logged out and 403 for the wrong role
- [ ] Passwords are hashed with bcrypt (cost 12) and never returned by any API
EOF

new_issue "Browse restaurants and dishes with estimated delivery and pickup totals (US2)" \
  "feature,priority:high,size:L" "$SPRINT1" "Sprint Todo" 5 <<'EOF'
**User story (docs/PRD.md US2):** As a diner, I want to browse restaurants and dishes with what they really cost, so that I don't get surprised at checkout.
**Estimate:** 5 points

### Acceptance criteria
- [ ] I can browse restaurants, filter by cuisine and open a restaurant's dish list
- [ ] Each dish shows an estimated delivery total and pickup total using the pricing rules in docs/PRD.md §4
- [ ] Tapping (phone) or hovering/focusing (desktop) a total reveals the breakdown: subtotal, discount, delivery fee, service fee, tip, tax
- [ ] A diner can suggest a new restaurant; it shows as "Unverified" until an admin or its partner verifies it
- [ ] Typical fees are prefilled ($3.99 delivery, 15% service) so adding a restaurant takes under 30 seconds
EOF

new_issue "Show deal status and price after deal with a minimum-order hint (US3)" \
  "feature,priority:high,size:M" "$SPRINT1" "Sprint Todo" 3 <<'EOF'
**User story (docs/PRD.md US3):** As a diner, I want to see which deals I can still use and what a dish costs after the deal, so that deals stop expiring unnoticed.
**Estimate:** 3 points

### Acceptance criteria
- [ ] Each deal shows a status badge: Active, Expiring soon (72 hours or less left) or Expired, per docs/PRD.md §4
- [ ] A dish with an applicable deal shows its price before (struck through) and after the deal
- [ ] If the order subtotal is below the deal's minimum, the deal is not applied and the UI shows "Add $X.XX more to use this deal"
- [ ] Official deals (from a partner) and community deals (from diners) carry different labels
- [ ] `GET /api/v1/deals?status=active` returns only non-hidden, non-expired deals, soonest expiry first
EOF

new_issue "Compare 2 to 4 dishes by total cost and health level (US4)" \
  "feature,priority:medium,size:M" "$SPRINT1" "Sprint Todo" 3 <<'EOF'
**User story (docs/PRD.md US4):** As a diner, I want to compare 2–4 dishes by total cost and health level, so that I can trade off saving money and eating healthy.
**Estimate:** 3 points

### Acceptance criteria
- [ ] I can select 2–4 dishes: a table on desktop (768 px and wider), stacked cards on a phone
- [ ] A pickup/delivery toggle updates every total
- [ ] The cheapest and the healthiest options are highlighted; "Healthiest" appears only when health levels differ
- [ ] Options over my budget are flagged
EOF

new_issue "Log orders with a 7-day summary and a recently-eaten filter (US5)" \
  "feature,priority:medium,size:M" "$SPRINT1" "Sprint Todo" 3 <<'EOF'
**User story (docs/PRD.md US5):** As a diner, I want to log what I ordered, so that I see my spending and stop repeating the same meal.
**Estimate:** 3 points

### Acceptance criteria
- [ ] I can add, edit and delete orders; price and health level prefill from the dish
- [ ] A 7-day summary shows the number of orders, total spent and health mix
- [ ] When the price paid differs from the estimate by more than $2.00, the difference is shown
- [ ] Each dish shows when I last had it; a "Haven't had lately" toggle hides dishes ordered in the last 7 days
EOF

# ---------------------------- Sprint 2 ----------------------------

new_issue "Pick for me: recommend a top pick and 2 alternatives in 3 taps (US6)" \
  "feature,priority:high,size:M" "$SPRINT2" "Backlog" 3 <<'EOF'
**User story (docs/PRD.md US6):** As a diner, I want the app to pick for me from my budget, deals, health goal and mood, so that I decide in seconds.
**Estimate:** 3 points

### Acceptance criteria
- [ ] I answer at most 3 button questions: budget, health goal today, cuisine mood (or "Surprise me")
- [ ] I see 1 top pick and up to 2 alternatives, each with its estimated total and a one-line "Why this"
- [ ] Options over budget are never suggested; dishes eaten in the last 7 days rank lower; active deals rank higher
- [ ] "I ordered this" logs the order (US5)
EOF

new_issue "Group Pick rooms with live nominations and voting (US7)" \
  "feature,priority:high,size:L" "$SPRINT2" "Backlog" 5 <<'EOF'
**User story (docs/PRD.md US7):** As a diner ordering with roommates, I want us to vote together, so that we decide in minutes instead of arguing.
**Estimate:** 5 points

### Acceptance criteria
- [ ] A host creates a room with an optional budget and cuisine and gets a 6-character code and a share link
- [ ] Logged-in diners join with the code; each member can nominate up to 2 dishes
- [ ] Each member has 1 vote and can change it until the room closes
- [ ] Nominations, votes and the member list update for everyone within 2 seconds, without reloading
- [ ] The host closes the room and everyone sees the winner; a tie goes to the lower delivery total
EOF

new_issue "Partner portal to manage menus and publish official deals (US8)" \
  "feature,priority:medium,size:M" "$SPRINT2" "Backlog" 3 <<'EOF'
**User story (docs/PRD.md US8):** As a restaurant partner, I want to manage my menu and publish official deals, so that students see accurate prices and my promotions.
**Estimate:** 3 points

### Acceptance criteria
- [ ] A diner can request partner access for a restaurant; the request stays pending until an admin approves
- [ ] An approved partner can edit their restaurant's fees and create, edit and delete its dishes
- [ ] A partner can publish, edit and end official deals for their own restaurant only (403 otherwise)
- [ ] The portal lists the restaurant's deals with their status (US3)
EOF

new_issue "Admin console to approve partners, moderate deals and manage roles (US9)" \
  "feature,priority:medium,size:M" "$SPRINT2" "Backlog" 3 <<'EOF'
**User story (docs/PRD.md US9):** As an admin, I want to verify partners and moderate content, so that the catalog stays trustworthy.
**Estimate:** 3 points

### Acceptance criteria
- [ ] I see pending partner requests and can approve or reject each; approval sets the user's role to PARTNER and links the restaurant
- [ ] I can hide or delete any deal; hidden deals disappear from every list and from the API
- [ ] I can change a user's role, but I cannot remove my own admin role
EOF

new_issue "Public API v1 with OpenAPI 3.1 docs and Swagger UI (US10)" \
  "feature,priority:high,size:M" "$SPRINT2" "Backlog" 3 <<'EOF'
**User story (docs/PRD.md US10):** As a developer, I want a documented API, so that other tools can read restaurants and deals.
**Estimate:** 3 points

### Acceptance criteria
- [ ] Public read endpoints: `GET /api/v1/restaurants`, `/restaurants/{id}`, `/restaurants/{id}/dishes`, `/deals`
- [ ] Authenticated endpoints (Bearer JWT or session cookie): `GET` and `POST /api/v1/orders`
- [ ] Every error uses `{ "error": { "code", "message" } }` with the correct HTTP status
- [ ] The OpenAPI 3.1 document is served at `/api/v1/openapi.json` and rendered with Swagger UI at `/api-docs`
EOF

new_issue "Add security scanning, security headers and automated production deploys" \
  "chore,priority:medium,size:S" "$SPRINT2" "Backlog" 2 <<'EOF'
**Goal:** complete the multi-stage pipeline: security checks on every PR and hands-off production deploys.
**Estimate:** 2 points

### Acceptance criteria
- [ ] CodeQL analysis runs on every PR and weekly
- [ ] `npm audit --audit-level=high` and a gitleaks secret scan run in CI and fail the build on findings
- [ ] Dependabot is enabled for npm and GitHub Actions
- [ ] A merge to `main` runs `prisma migrate deploy` and deploys to production on Vercel
- [ ] Security headers are set in `next.config.ts` (CSP, X-Content-Type-Options, Referrer-Policy, frame-ancestors)
- [ ] The Playwright suite runs against each PR's preview URL
EOF

new_issue "Write README, architecture and database diagrams, and deployment guide" \
  "docs,priority:medium,size:S" "$SPRINT2" "Backlog" 2 <<'EOF'
**Goal:** the documentation package required for P2 submission.
**Estimate:** 2 points

### Acceptance criteria
- [ ] README: what it is, features by role, tech stack, local setup in 5 commands or fewer, test commands, live URL
- [ ] Architecture diagram (Mermaid) that matches AGENTS.md §1.3
- [ ] Database schema diagram (Mermaid erDiagram) that matches `prisma/schema.prisma`
- [ ] Deployment guide: Vercel + Neon setup, environment variables per environment, migrations
- [ ] Sprint 1 and Sprint 2 retrospectives with partner feedback in `docs/retros/`, plus the contribution log
EOF

# ---------------------------------------------------------------------------------------------------------------
# 4. GitHub Project: Status options = board columns, Estimate field, all issues added
# ---------------------------------------------------------------------------------------------------------------
STATUS_OPTIONS='[{name: "Backlog", color: GRAY, description: "Not in the current sprint"},
  {name: "Sprint Todo", color: BLUE, description: "Committed for the current sprint"},
  {name: "In Progress", color: YELLOW, description: "Someone is working on it"},
  {name: "In Review", color: PURPLE, description: "PR open, waiting for the partner review"},
  {name: "Done", color: GREEN, description: "Merged to main"}]'

if ((DRY_RUN)); then
  echo "[dry-run] create project \"$PROJECT_TITLE\" for $OWNER, link it to $REPO"
  echo "[dry-run] set Status options: Backlog, Sprint Todo, In Progress, In Review, Done; add Estimate field"
  for i in "${!ISSUE_URLS[@]}"; do
    echo "[dry-run] add ${ISSUE_URLS[$i]} -> ${ISSUE_STATUS[$i]}, estimate ${ISSUE_POINTS[$i]}"
  done
  exit 0
fi

PROJECT_NUMBER=$(gh project list --owner "$OWNER" --limit 100 --format json \
  --jq ".projects[] | select(.title == \"$PROJECT_TITLE\") | .number" | head -n1)
if [[ -z "$PROJECT_NUMBER" ]]; then
  PROJECT_NUMBER=$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json --jq .number)
  echo "project created  #$PROJECT_NUMBER"
else
  echo "project exists  #$PROJECT_NUMBER"
fi
PROJECT_ID=$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json --jq .id)
gh project link "$PROJECT_NUMBER" --owner "$OWNER" --repo "$REPO" >/dev/null 2>&1 || true

field_json() { gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --limit 50 --format json --jq "$1"; }

STATUS_FIELD_ID=$(field_json '.fields[] | select(.name == "Status") | .id')
CURRENT_OPTIONS=$(field_json '[.fields[] | select(.name == "Status") | .options[].name] | join(",")')
if [[ "$CURRENT_OPTIONS" != "Backlog,Sprint Todo,In Progress,In Review,Done" ]]; then
  if gh api graphql -f id="$STATUS_FIELD_ID" -f query="mutation(\$id: ID!) {
      updateProjectV2Field(input: {fieldId: \$id, singleSelectOptions: $STATUS_OPTIONS}) {
        projectV2Field { ... on ProjectV2SingleSelectField { id } } } }" >/dev/null; then
    echo "board columns set: Backlog, Sprint Todo, In Progress, In Review, Done"
  else
    echo "!! Could not rename the Status options automatically."
    echo "   In the project: Settings > Status, make the options exactly: Backlog, Sprint Todo, In Progress, In Review, Done"
    echo "   then re-run this script to place the cards."
    exit 1
  fi
fi

if [[ -z "$(field_json '.fields[] | select(.name == "Estimate") | .id')" ]]; then
  gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" --name "Estimate" --data-type NUMBER >/dev/null
  echo "field created  Estimate"
fi
ESTIMATE_FIELD_ID=$(field_json '.fields[] | select(.name == "Estimate") | .id')

option_id() { field_json ".fields[] | select(.name == \"Status\") | .options[] | select(.name == \"$1\") | .id"; }
OPT_SPRINT_TODO=$(option_id "Sprint Todo")
OPT_BACKLOG=$(option_id "Backlog")

for i in "${!ISSUE_URLS[@]}"; do
  url="${ISSUE_URLS[$i]}"
  item_id=$(gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$url" --format json --jq .id)
  if [[ "${ISSUE_STATUS[$i]}" == "Sprint Todo" ]]; then opt="$OPT_SPRINT_TODO"; else opt="$OPT_BACKLOG"; fi
  gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" --field-id "$STATUS_FIELD_ID" \
    --single-select-option-id "$opt" >/dev/null
  gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" --field-id "$ESTIMATE_FIELD_ID" \
    --number "${ISSUE_POINTS[$i]}" >/dev/null
  echo "board  ${ISSUE_STATUS[$i]}  ($((ISSUE_POINTS[$i])) pts)  $url"
done

cat <<EOF

Done. Two manual steps left (GitHub's CLI cannot create views):
  1. Open the project: https://github.com/users/$OWNER/projects/$PROJECT_NUMBER  (for an org: /orgs/$OWNER/...)
     Click the view tab menu > Layout > Board. It groups by Status, so the five columns appear.
  2. Repo Settings > Collaborators: add your partner with Write access; Project Settings > Manage access: add them too.

Check that the first issue above is #1. If the repo already had issues or PRs, the numbers are shifted:
update the (#n) references in docs/PRD.md to match.
EOF
