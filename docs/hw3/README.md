# HW3: Context Engineering — evidence

Everything for CS6983 HW3 in one place. The rules file itself is [`/AGENTS.md`](../../AGENTS.md) (v1.2, changelog in §8).

| Deliverable | Where |
| --- | --- |
| Scrum setup | [Project board](https://github.com/users/geekRoy0126/projects/2), milestones `Sprint 1` (due Nov 5) and `Sprint 2` (due Nov 11), issues #1–#14; created by [`scripts/setup-github-scrum.sh`](../../scripts/setup-github-scrum.sh) |
| Rules file | [`/AGENTS.md`](../../AGENTS.md) |
| Before/after comparison | [`before-after-comparison.pdf`](before-after-comparison.pdf) |
| Reflection | [`reflection.pdf`](reflection.pdf) |
| Raw experiment data | [`experiment/`](experiment/) |

## The experiment

The same agent implemented issue #5 (US3, deal status) three times, each in a fresh conversation on a byte-identical
copy of this repo. Only the rules file changed.

| Run | Rules | Score (34 checks) | Code | Score output |
| --- | --- | --- | --- | --- |
| A | none (AGENTS.md deleted) | 28 / 34 | [`A-without-rules.diff`](experiment/runs/A-without-rules.diff) | [score](experiment/scores/A-without-rules-score.txt) |
| B | AGENTS.md v1.0 | 32 / 34 | [`B-with-rules.diff`](experiment/runs/B-with-rules.diff) | [score](experiment/scores/B-with-rules-score.txt) |
| C | AGENTS.md v1.1 | 33 / 34 | [`C-with-rules-v1.1.diff`](experiment/runs/C-with-rules-v1.1.diff) | [score](experiment/scores/C-with-rules-v1.1-score.txt) |

- `runs/*.diff` is each run's full change on top of its baseline (the agent's `test(#5)` and `feat(#5)` commits;
  generated Prisma client omitted). `runs/*.log.txt` is the commit history.
- [`experiment/measure.sh`](experiment/measure.sh) is the scoring script: lint, typecheck, unit tests, coverage,
  then 34 PASS/FAIL checks from the PRD acceptance criteria and the rules. Usage: `bash measure.sh <run-folder>`
  (the folder must be a git repo whose first commit is the baseline).
- Findings from the runs became rule changes v1.1 and v1.2, listed in AGENTS.md §8.
