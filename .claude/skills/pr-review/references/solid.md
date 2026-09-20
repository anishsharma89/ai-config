# SOLID, as observable signals

"Check for SOLID violations" is not actionable. Each principle below is reduced
to a shape you can find in a diff. If you can't point at the shape, you don't
have a finding — you have an opinion.

All five land as `ASK` unless the violation also causes a correctness or
testability defect, in which case it's a `BLOCK` and you cite the defect, not
the principle. **Never cite a principle as the harm.** "This violates DIP" is
not a consequence; "this can't be tested without a live gRPC channel" is.

## Single Responsibility

**Shape:** one unit changes for more than one reason.

- A function that does orchestration *and* I/O *and* serialisation
- A handler that both decides business outcomes and formats the HTTP response
- A class whose name contains "and", "Manager", "Helper" or "Util"
- A module imported by both the transport layer and the persistence layer

**Ask:** "If the wire format changed, would this function need editing? If the
business rule changed, would the same function need editing?" Two yeses is the
finding.

**Not a finding:** a long function that does one thing. Length is a clean-code
concern, not SRP.

## Open/Closed

**Shape:** extending behaviour requires editing existing code.

- `if isinstance(x, ...)` / `match type(x)` chains that grow per new case
- A dispatch dict or switch that every new feature must be added to
- An enum plus a parallel `if/elif` ladder repeated in several places

**Ask:** "When we add the next case, how many existing files get touched?" More
than one is the finding.

**Not a finding:** two branches. Premature abstraction is the more expensive
mistake — say so if the author has over-generalised.

## Liskov Substitution

**Shape:** a subtype can't stand in for its parent.

- An override that raises `NotImplementedError`
- An override that narrows accepted input or widens what it raises
- A caller doing `isinstance` checks to decide how to treat a subtype
- An override that returns `None` where the parent guarantees a value

**Ask:** "Can every caller of the parent be handed this subtype without
changing?" No is the finding.

## Interface Segregation

**Shape:** a caller depends on methods it never uses.

- An abstract base with many methods where most implementations stub some
- A test that has to mock six methods to exercise one
- A protocol/interface that grew to serve two unrelated consumers

**Ask:** "How many of these methods does the narrowest caller use?" A small
fraction is the finding.

**The test suite is the evidence.** When a test needs a large mock to exercise
one behaviour, the interface is too fat — that's a concrete, checkable signal
rather than a judgement call.

## Dependency Inversion

**Shape:** a high-level module names a concrete low-level implementation.

- A concrete client, driver or SDK instantiated at module import time
  (`scheduler = NewSchedulerV2Client()`) — the highest-value instance of this
  family, because it also breaks testability and connection lifecycle
- A handler importing a database driver directly instead of taking a repository
- `datetime.now()`, `uuid4()`, `random()` or `time.sleep()` called inline in
  business logic rather than injected — untestable, and the reason "flaky test"
  tickets exist
- Constructing an HTTP or gRPC client inside the function that uses it

**Ask:** "Can this be tested without the network, a clock, or a database?" No is
the finding, and the finding is *testability*, not the acronym.

## Priority

When several apply, report **DIP** first. It's the one that most reliably
predicts a test suite that can't be written, and unlike the others it usually
has a small, obvious fix: pass the thing in.
