# Roadmap History

This directory preserves the reasons the project's mutable `ROADMAP.md` changes over time.

These records are intended for both human engineers and autonomous development agents. They provide evidence, constraints, and desired outcomes from which future implementation plans can be developed. They should not function as implementation tickets.

## When to add a record

Add a roadmap history record when completed work, architectural analysis, performance evidence, or project priorities materially change the recommended order or purpose of upcoming milestones.

Minor wording changes to `ROADMAP.md` do not require a history record.

## Suggested structure

A roadmap adjustment should record:

- the prior roadmap direction;
- the evidence or completed milestone that prompted reassessment;
- measured evidence separately from engineering inference;
- the resulting roadmap adjustment;
- work deliberately deferred;
- the question or desired outcome of the new next milestone; and
- related ADRs and performance reports.

## Audience and planning discipline

Describe what the project needs to learn or achieve, why it matters, and which architectural constraints must remain true.

Assume the reader is a professional capable of inspecting the current codebase and designing an implementation. Avoid prescribing files to edit, methods to add, classes to create, or specific algorithms unless such details are themselves part of an accepted architectural decision.

`ROADMAP.md` is the current plan. This directory is the historical record of why that plan changed.