# Reference documentation (docstrings)

Presence is enforced by `ruff` (pydocstyle `D` rules) in the gates job, so a
missing docstring on a public symbol never reaches review. Presence is all a
linter can check. Everything below is about whether the docstring is worth having.

## What a docstring owes the reader

One line saying what it does, in the imperative. Then, only if non-obvious:

- **Args** — units, ranges, and what an empty or null value means
- **Returns** — the shape, and what it looks like when there's nothing to return
- **Raises** — every exception a caller should handle
- **Guarantees** — is it idempotent? does it mutate its input? is it safe to
  retry? This is the section people omit and the one that prevents incidents.

```python
def reschedule_batch(jobs: list[Job], idempotency_key: str) -> BatchResult:
    """Reschedule up to 1000 jobs, returning per-job outcomes.

    Not atomic: individual jobs can fail independently and the caller must
    inspect each result. Safe to retry with the same idempotency_key — jobs
    already rescheduled under that key are skipped rather than rescheduled
    again.

    Args:
        jobs: Up to 1000 jobs. Duplicate job_ids are rejected, not deduped.
        idempotency_key: Caller-generated, stable across retries of the same
            logical request.

    Returns:
        BatchResult with one entry per input job, in input order.

    Raises:
        BatchTooLargeError: More than 1000 jobs.
        SchedulerUnavailableError: SchedulerV2 unreachable after retries. No
            jobs were rescheduled.
    """
```

Note what earns its place: the retry semantics, the non-atomicity, and the
guarantee that a failed call rescheduled nothing. None of that is inferable from
the signature, and all of it is what a caller gets wrong.

## What not to write

- **A restatement of the name.** `"""Handle batch."""` on `handle_batch` is
  worse than nothing: it occupies the place a real docstring would go, so the
  gap stops being visible.
- **Types already in the signature.** The annotation says `list[Job]`. Don't
  repeat it; say what's true about the list that the type can't express.
- **Implementation detail.** Describes what the caller can rely on, not how it
  currently works. Implementation changes; the contract shouldn't.
- **Stale examples.** An example that no longer runs is a bug report nobody
  filed. If it matters enough to show, make it a doctest so it breaks loudly.

## Comments versus docstrings

A docstring is a contract for callers. A comment explains a decision to the next
maintainer. They are different documents with different readers.

```python
# Sequential rather than concurrent: SchedulerV2 rate-limits per-caller at
# 50 rps and returns 429 without a Retry-After, so parallelism here costs
# more in retries than it saves. See docs/adr/0004.
```

That comment earns its place — it answers a question a reader will otherwise ask,
and pre-empts a "fix" that would make things worse. `# loop over jobs` does not.

## Modules and classes

- **Module docstring:** what lives here and what doesn't. One or two lines. The
  boundary is the useful part.
- **Class docstring:** what it's responsible for, and its lifecycle if it has one
  — is it safe to share between requests, does it hold a connection, must it be
  closed.
