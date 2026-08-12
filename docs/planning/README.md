# Engineering Planning Records

The repository's roadmap, architecture decisions, roadmap history, and performance reports are shared planning inputs for both human engineers and autonomous development agents.

They should provide durable context from which a qualified engineer can develop an implementation plan. They should not attempt to replace professional implementation planning.

## Planning principle

Planning records should communicate:

- current architectural boundaries;
- accepted decisions and constraints;
- completed capabilities;
- current priorities;
- measured evidence that influenced those priorities;
- unresolved questions; and
- desired outcomes for upcoming milestones.

They should generally avoid prescribing:

- files to modify;
- methods to add;
- classes to create;
- incidental internal structure; or
- specific algorithms to implement.

Those choices belong in feature-specific implementation plans produced after inspecting the current repository and evaluating the relevant alternatives.

## Record roles

- `ROADMAP.md` is mutable and describes the current development direction.
- `docs/roadmap/history/` preserves why that direction changed.
- `docs/architecture/decisions/` preserves durable architectural decisions and their consequences.
- `docs/performance/` preserves measured scaling and performance evidence.

When a milestone materially changes the recommended development order, update `ROADMAP.md` and add a roadmap history record.

When a milestone establishes or changes a durable architectural decision, add or supersede an ADR.

When performance or scaling evidence materially informs architecture or roadmap direction, preserve the evidence under `docs/performance/` and link the related records.

## Evidence discipline

Keep the reasoning chain explicit:

```text
measured evidence
        ↓
engineering inference
        ↓
architectural decision
        ↓
roadmap adjustment
```

Do not present inference as measurement, and do not prescribe implementation when the evidence only establishes a problem, constraint, or desired outcome.