# ADR-0001: Automated review is advisory; humans remain the sole approvers

**Status:** Accepted
**Date:** 2026-09-21
**Deciders:** Aurora EM

## Context

Review is the team's bottleneck, not authoring. Observed on Aurora before this
change:

- A fix for a Sev-3 production incident sat in review for **4 days**, blocked on
  one unresolved comment.
- Deploys per week fell **6 → 4 → 2 → 1 → 0**. Review latency is upstream of
  that collapse.
- The first PR implementing the V2 batch endpoint shipped with an undefined name,
  a `# TODO: handle errors` on the gRPC client, and a test that would have passed
  if every job in the batch had failed. All three are mechanically detectable and
  none required human judgement to find.

Three of four engineers were shipping at normal throughput, so authoring speed
was not the constraint. The constraint was the latency and the altitude of
review: humans were spending their attention on defects a tool could have caught,
and consequently not spending it on whether the change was right.

## Decision

Pull requests pass through three gates in order.

**Gate 0 — deterministic.** Formatting, lint, types, tests, and 100% coverage of
changed lines, via `scripts/gates.sh`. No model. Identical locally and in CI. If
red, nothing downstream runs.

**Gate 1 — automated first-pass review.** The `pr-review` skill posts inline
findings on SOLID shape, clean-code thresholds, test quality, documentation
obligations, and the repo's known sharp edges. Capped at 8 findings. **It has no
approve capability and no merge capability.**

**Gate 2 — a human.** The sole approver, reviewing a diff where mechanics are
already settled and obvious defects are already annotated.

## Alternatives considered

- **Automated review that can block merge** — rejected. The first time it blocks
  an incident fix on a false positive, the team routes around it permanently, and
  we lose the tool and the trust together. Advisory findings that are usually
  right beat blocking findings that are occasionally wrong.

- **Automated review that can approve trivial PRs** — rejected. "Trivial" is a
  judgement, and the PRs that look trivial are where the expensive mistakes hide.
  A one-line change to the eligibility DSL looks trivial and is not.

- **A model checking formatting alongside everything else** — rejected. A model is
  nondeterministic and will contradict itself between runs on the same file.
  Formatting has exactly one correct answer, so it belongs to `ruff format` with
  one committed config. The skill is explicitly forbidden from raising anything a
  formatter owns.

- **Global 100% test coverage as the gate** — rejected. It manufactures tests that
  execute lines and assert nothing; the exercise's own
  `test_batch_returns_success` is that pathology. Coverage is enforced on changed
  lines instead, where the target is achievable without the incentive to game it.

- **Unbounded review findings** — rejected. Thirty comments on one PR is not a
  quality bar, it is a way to ensure none are read, and dropping eleven blocking
  comments on a struggling engineer's PR is a management failure. Hence the cap of
  8, and the rule that a third instance of one issue becomes one comment naming
  the pattern.

- **No automation; fix review culture with a review-latency SLA alone** — rejected
  as insufficient, not wrong. We are also setting a 4-business-hour first-response
  SLA. But an SLA makes humans faster at finding undefined names, which is not
  what we want them doing.

## Consequences

- Human review starts at design altitude. Mechanical defects are annotated before
  a person opens the diff.
- Feedback to the author drops from days to ~90 seconds for the mechanical class.
- **Cost:** one model run per PR per push. Bounded with `--max-turns`, a 15-minute
  timeout, and `concurrency.cancel-in-progress` so a force-push doesn't pay twice.
- **Cost:** the skill is a maintained artifact. A wrong `BLOCK` is a bug in it and
  must be fixed there, not worked around in the PR. Whoever gets a bad finding is
  expected to say so.
- **We accept that some defects pass Gate 1.** It is a first pass. Presenting it
  as a safety net would make human review less careful, which is the one failure
  mode that would make this net-negative.
- Revisit if: false-positive rate makes engineers ignore findings, or if the
  8-finding cap is hiding real defects rather than reducing noise.
