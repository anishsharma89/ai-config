# Architecture Decision Records

An ADR records **one decision, its context, and its consequences** — at the time
it was made, in the words of the people who made it. Format follows Michael
Nygard's original: Title, Status, Context, Decision, Consequences.

## When a change requires one

The test is not "was this hard." It is: **would a competent engineer, six months
from now, look at this and ask why?** If yes, that question deserves an answer
that isn't a git blame.

Concretely — any of these obliges an ADR:

- Choosing between technologies that both would have worked
- Introducing a new datastore, queue, or external dependency
- Accepting a trade-off knowingly (we chose the slower path because…)
- Reversing an earlier decision — which means superseding an earlier ADR
- A constraint that will look arbitrary later ("max 1000 per batch")
- Deciding *not* to do something, when the obvious move was to do it

## The part everyone skips

**Alternatives considered, and why each was rejected.** An ADR without this
section is an announcement, not a record. It's also the only section that helps
the next person: knowing you picked X is mildly useful, knowing you rejected Y
for a reason that no longer holds is what lets them safely revisit it.

The exercise's V2 design proposal is the negative example. It proposes MongoDB
with three bullet points of reasoning, no alternatives, and an `## Open` section
left blank. A reader six months later cannot tell whether Postgres was evaluated
and rejected, or never considered. Those are very different situations and the
document destroys the distinction.

## Rules

- **One decision per record.** Two decisions in one ADR means neither can be
  superseded independently.
- **Immutable once accepted.** You don't edit an ADR to reflect a new decision;
  you write a new one and mark the old one `Superseded by ADR-00NN`. The history
  of what you used to believe is the value.
- **Numbered sequentially, never renumbered.** `0001`, `0002`. Links break
  otherwise.
- **Written by a human.** A model can format one, chase down the code it refers
  to, and check that the consequences section isn't empty. It cannot supply the
  reasoning, and must not invent it.
- **Present tense, active voice.** "We store events in Postgres" — not "it was
  decided that events would be stored."
- **Short.** One page. If it needs more, the decision is actually several.

## Status values

- `Proposed` — under discussion, not yet binding
- `Accepted` — in force
- `Superseded by ADR-00NN` — no longer in force; the record stays
- `Deprecated` — no longer relevant, nothing replaced it
