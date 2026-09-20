# Clean code, with thresholds

Taste is not reviewable. Each item below has a number or a shape attached, so a
finding is checkable and the author can't reasonably argue it's subjective.

**Formatting is not on this list.** `ruff format` owns whitespace, line length,
quote style, trailing commas, blank lines and import order, and it ran before
you. Commenting on any of them contradicts a tool that already passed. If you
believe the formatter's configuration is wrong, that's a PR against
`pyproject.toml`, not a review comment.

## Thresholds

| Signal | Threshold | Severity |
|---|---|---|
| Function length | > 50 lines | `ASK` |
| Cyclomatic branches in one function | > 10 | `ASK` |
| Positional parameters | > 4 | `ASK` |
| Nesting depth | > 3 | `ASK` |
| Duplicated block | 3rd occurrence | `ASK` |
| Boolean parameter selecting behaviour | any | `ASK` |
| Magic number outside a named constant | any, except 0/1 | `NIT` |
| Commented-out code | any | `BLOCK` — delete it, git remembers |
| `TODO` / `FIXME` with no ticket reference | any | `BLOCK` |
| Bare `except:` or `except Exception` with no re-raise | any | `BLOCK` |
| Mutable default argument | any | `BLOCK` |
| Unused local or fetched-and-discarded result | any | `BLOCK` |

## Naming

- A name that requires a comment to explain it is the wrong name.
- Booleans read as assertions: `is_eligible`, `has_timeout`, not `flag`, `check`.
- No type names in variables (`job_list` → `jobs`), no Hungarian prefixes.
- Version markers in class names age badly. `NewSchedulerV2Client` will be the
  old client in six months — `ASK` once, never twice, and never block on it.
- Same concept, same word, across the whole diff. `job` in one function and
  `work_order` in the next for the same entity is a `BLOCK`: it's how two people
  end up writing two different behaviours.

## Comments

- Comments explain **why**, never **what**. A comment restating the line is
  deletable.
- A comment that contradicts its code is a `BLOCK` — one of them is a lie and
  the reader can't tell which.
- Docstrings on anything public: what it does, what it raises, what it
  guarantees. Absent on a new public function is an `ASK`.
- `# TODO: handle errors` shipped in a diff is a `BLOCK`. It's an admission the
  change isn't finished, written down and merged anyway.

## Error handling

- Every outbound call has an explicit timeout. No timeout is a `BLOCK`, always.
- Catch the narrowest exception that can actually occur.
- Never log and re-raise the same error at two levels — the duplicate is noise
  in the incident.
- A failure path that returns a success-shaped response is a `BLOCK`. Partial
  failure needs its own representation in the response, not a mixed array the
  caller has to inspect element by element without being told to.
- An error message tells the operator what to do next. "Not enabled" doesn't.

## Structure

- A new module that only re-exports is deletable.
- Mutable module-level state is a `BLOCK` in an async service — it's shared
  across requests and across the event loop.
- Configuration read at import time can't be changed without a restart. `ASK`.
- Guard clauses over nested conditionals. Return early.
