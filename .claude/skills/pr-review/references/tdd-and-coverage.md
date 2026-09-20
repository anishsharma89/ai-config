# TDD and coverage

## The gate

Enforced deterministically in the gates job, before this review runs:

- **Diff coverage: 100%.** Every line added or modified in this PR is executed
  by a test. This is the "100% coverage" target, scoped to the only place it's
  achievable without gaming: the code actually being changed.
- **Overall coverage may not decrease.** Ratchet only upward.

**Why not 100% overall?** Because it is the most reliably counterproductive
metric in testing. Chasing it produces tests that execute lines and assert
nothing, drives people to test generated code, getters and `__repr__`, and
rewards the author who writes `assert result is not None` over the one who
writes a real test. The number goes up and the suite gets weaker. Diff coverage
at 100% gets the discipline — nothing new ships untested — without the
incentive to game.

Coverage is a floor, not evidence of quality. It tells you a line ran. It
cannot tell you an assertion would fail if the behaviour broke. That judgement
is yours, and it's the most valuable thing you do on a PR.

## How to judge a test

Apply this to every new or modified test. **Would this test fail if the
behaviour it names were broken?**

If no, it's a `BLOCK`, and say which behaviour goes unprotected.

Failure patterns, in the order you'll encounter them:

**Asserts on shape, not behaviour.**
```python
def test_batch_returns_success():
    result = handle_batch(BatchRequest(jobs=[Job(job_id="1", ...)]))
    assert len(result["results"]) == 1
```
Named `..._success`, but `results` gets an entry whether the job succeeded or
failed. Every job in the batch could fail and this passes. It asserts the loop
ran, which no one doubted. It must assert the *status*, and that the scheduler
was actually called.

**Tests the mock.** If every collaborator is mocked and the assertion is
`mock.assert_called_once()`, the test verifies the test's own wiring. At least
one assertion must be about the subject's output or its effect.

**One happy path only.** A test file with no failure case for a function that
can fail is incomplete. Required: the failure path, and for anything retryable,
the retry path.

**No partial-failure case** on anything batched. If the function processes a
collection, there must be a test where some elements fail — that's where the
real bugs are and it's the case authors skip.

**Asserts current behaviour rather than intended behaviour.** The specific
hazard with generated tests: a test written against buggy code encodes the bug
and then defends it. If a test's expected value looks like it was copied from an
actual run, `ASK` whether it was derived from the requirement.

**Non-deterministic.** Depends on wall-clock time, `uuid4()`, dict ordering,
network, or the order tests run in. `BLOCK` — a flaky test gets disabled within
two sprints and then the code is uncovered and nobody knows.

## TDD signals in the diff

You can't verify test-first from a merged branch, so don't claim to. What you
can observe:

- **Commit order**, when the branch isn't squashed: tests appearing in the same
  commit as, or before, the implementation is a good signal. Worth noting once
  in the summary, never as a finding.
- **Test shape.** Tests written first tend to describe behaviour
  (`test_partial_failure_returns_per_job_status`); tests written after tend to
  describe implementation (`test_handle_batch_calls_scheduler`). The second kind
  breaks on every refactor and protects nothing. `ASK` on naming that describes
  mechanics rather than a guarantee.
- **Coverage arriving in a separate follow-up commit** after review started is
  the tell that tests were bolted on. Note it in the summary.

## What earns a mention in the summary

State whether the diff is adequately tested in one line, and if it is, say so
plainly. An author who wrote real tests should hear that, once, in the summary
where it doesn't clutter the diff.
