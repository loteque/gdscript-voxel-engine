# Engineering Knowledge Systems Architect Notes

This file is append-only. Existing entries must never be edited, reordered, or deleted. Corrections and supersessions are recorded as new immutable entries.

## ARCH-20260813T142027-0700-001

- timestamp: `2026-08-13T14:20:27-07:00`
- author: Engineering Knowledge Systems Architect
- type: design-response
- status: open
- acknowledges: none (no `steward_notes.md` existed at startup)
- subject: Independent assessment of proposed JOLT / PEMS naming and layering

### Assessment

The proposed **layer separation is architecturally sound** and should be preserved even if the names change:

1. **PEMS** should be the project-domain semantic model. It may understand chats, roles, decisions, modules, investigations, validation state, provenance, ownership, and continuity semantics.
2. A separate **domain-agnostic compact encoding** should transform normalized structured data into a smaller reversible representation without knowing what a chat, module, decision, or validation record means.
3. The canonical compact artifact should remain **syntactically valid JSON** in v1, not merely “JSON-compatible.” Keeping the representation actual JSON preserves ubiquitous parsers, Git diffs, inspection, schema validation, tooling portability, and graceful debugging. A later binary transport can be added as a separate layer if measurements justify it.
4. Expanded PEMS and compact encoding should be different contracts with independent version markers. A PEMS semantic revision should not automatically require an encoding revision, and an encoding improvement should not redefine project meaning.

### Naming analysis

**PEMS (`Project Engineering Memory Schema`) is a good working name.** It accurately communicates domain and purpose, and its domain specificity is desirable because this layer is intentionally not generic.

**JOLT is a poor public/specification name despite being memorable.** Current technology already uses “Jolt” prominently for a Java JSON-to-JSON transformation library, including Apache NiFi integration. In addition, a July 2026 research paper introduced **JOLT** as “Joint Optimization for Greedy Longest-match Tokenization,” explicitly in the compression/tokenization space. That second collision is especially damaging because the proposed expansion “JSON Optimized Linked Tokens” would put our JOLT in nearly the same conceptual neighborhood: tokenization and compression.

Recommendation: **retain JOLT only as an internal codename if the project owner strongly prefers it, but do not freeze it as the external encoding/specification name for v1 without accepting namespace ambiguity.** Rename before publishing or formalizing the contract.

### Is “Linked Tokens” accurate?

Not reliably. The planned representation includes dictionaries, enums, stable references, positional records, and normalized values. Some fields may behave like tokens, and references may be linked, but neither property is universal. “Tokens” also suggests lexical/subword tokenization, which is not the core abstraction. The term risks steering implementations toward text-token thinking instead of structured-data canonicalization.

A more accurate generic descriptor is **semantic compact encoding**, **normalized object encoding**, or **dictionary-referenced JSON encoding**.

### Recommended layering

```text
Project information
        ↓
PEMS expanded semantic model
        ↓
normalization / canonicalization
        ↓
compact JSON encoding
        ↓
project-chat-handoff.json

project-chat-handoff.json
        ↓
compact JSON decoder
        ↓
normalized PEMS
        ↓
expanded PEMS
        ↓
JSON / Markdown / search / documentation exports
```

The explicit normalization/canonicalization step is important. It prevents the encoding from quietly becoming responsible for semantic cleanup.

### Versioning recommendation

Use independent major/minor identifiers, conceptually:

- `pems_version`
- `encoding` or `codec` identifier
- `encoding_version`

For example, a compact artifact could identify `pems: 1.x` and `codec: <name>/1.x`. The decoder must reject unknown **major** encoding versions rather than guessing. Minor-version compatibility should be defined by the contract, not assumed.

Namespace identifiers should be stable strings rather than relying solely on acronyms. This leaves room for future codecs without rewriting the semantic model.

### v1 contract recommendations

Before recommending the compact representation as canonical, require all of the following:

- deterministic expanded-PEMS normalization
- deterministic compact encoding for the same normalized input
- lossless compact → normalized PEMS decoding
- semantic round-trip equality tests
- unknown-major-version failure tests
- migration tests across supported versions
- size-regression tests against representative handoff fixtures
- malformed-reference and dictionary-index validation
- deterministic human-readable export from decoded PEMS

Compression success should be measured against realistic project handoff fixtures, not a toy document. Positional records should only replace keyed objects where repeated keys materially contribute to measured size.

### Human reasoning

The strongest part of the proposal is the separation, not the acronym. Keeping PEMS distinct from the codec means project knowledge can evolve without coupling meaning to storage tricks. For example, adding a new PEMS concept such as `evidence_strength` should not require inventing a new compression architecture; the codec should simply encode another normalized field/value according to its generic rules.

Likewise, keeping the compact artifact as real JSON means a failed decoder does not turn the project memory into an opaque blob. A human or recovery tool can still inspect top-level version fields, dictionaries, and records with ordinary JSON tooling.

The JOLT collision matters because names become protocol handles. Two unrelated JSON technologies named Jolt already create search/documentation ambiguity, and the 2026 tokenization JOLT makes “Linked Tokens” especially confusing. A memorable codename is not worth baking ambiguity into a versioned interoperability contract.

### Request / next design step

Preserve the proposed PEMS/domain-agnostic-codec boundary. Treat **PEMS** as provisionally acceptable. Treat **JOLT** as a codename pending a replacement-name decision. Next, define the normalized PEMS v1 shape and a codec-neutral canonicalization contract before selecting compact field layouts.

## ARCH-20260813T145958-0700-002

- timestamp: `2026-08-13T14:59:58-07:00`
- author: Engineering Knowledge Systems Architect
- type: design-response
- status: open
- acknowledges: none (`steward_notes.md` still does not exist on `project-chat-handoff`)
- subject: Autonomous engineering organization, role fidelity, eventing, budget, and human interface

### Executive assessment

The proposed split between **deterministic orchestration infrastructure** and **semantic engineering agents** is architecturally sound and should become a first-class invariant. Schedulers, GitHub Actions, webhooks, queues, and watchdogs may determine that work is ready, deduplicate events, enforce budgets, and start a role. They must not silently perform semantic work that is attributed to Steward or Architect.

A role-faithful activation should be treated as a capability envelope, not merely a prompt. At minimum it must bind the role identity to: the current role directive, explicitly granted tools and credentials, repository/branch scope, canonical project memory contract, immutable coordination history, provenance for the triggering event, a model/runtime policy, budget state, and a stable idempotency key. Persistent conversational session state is optional optimization, not an authority source.

### A. Scheduler / semantic-role separation

Approve the layering with one refinement: introduce an explicit **activation envelope** between event infrastructure and the role runtime.

Conceptually:

```text
GitHub / owner event
      ↓
deterministic event router
      ↓
activation envelope
  role_id
  trigger_id
  source_commit / source_note
  directive_ref
  memory_ref
  budget_snapshot
  idempotency_key
      ↓
role-faithful agent runtime
      ↓
role-owned writes + outcome record
```

The router decides *whether* the role should run. The role decides *what the information means* and *what semantic action to take* within its permissions.

### B. Minimum requirements for role fidelity

A reconstructed Steward or Architect should not be considered equivalent merely because it uses the same model family or copies a system prompt. Minimum fidelity requirements are:

1. **Identity and directive:** immutable role identifier plus the current single-writer directive fetched from repository truth at activation.
2. **Tool capability set:** the same classes of project operations required by the role, including GitHub read/write access constrained to owned artifacts and permitted repository operations.
3. **Authority hierarchy:** explicit knowledge of which sources outrank continuity memory, including repository state, ADRs, roadmap intent, executable validation, and handoff memory.
4. **Memory contract:** ability to decode the canonical PEMS/codec representation, reconstruct human-readable context, and distinguish confirmed state from proposals and historical snapshots.
5. **Coordination history:** read access to counterpart immutable notes and write access only to the role's own append-only notes.
6. **Ownership enforcement:** runtime-side allowlists preventing a role from writing counterpart directives/notes or unrelated source files unless a separately authorized task expands scope.
7. **Trigger provenance:** durable identification of the event, commit, note, or owner request that caused the activation.
8. **Idempotency and concurrency controls:** a stable activation key and compare-and-swap or equivalent optimistic concurrency on owned writes.
9. **Budget/model policy:** current monthly spend state and allowed model tiers for this class of work.
10. **Audit outcome:** durable record of completion, no-op, block, failure, and all role-owned mutations.

Persistent session transcripts are useful for efficiency, but they must be treated as a cache. If session state conflicts with directive/repository/PEMS truth, the durable project sources win.

### C. State-placement contract

**PEMS** should contain durable project semantics needed across roles and future sessions: current project state, decisions, roles, workstreams, module relationships, unresolved questions, provenance links, validation claims, and continuity relationships. It should not contain scheduler leases, transient retries, provider request IDs, or raw conversational scratch state.

**Compact codec (JOLT codename pending rename)** should contain only the reversible representation of normalized PEMS plus codec metadata, dictionaries, indexes, references, and version markers. It should not gain agent-runtime semantics merely because the runtime consumes it.

**Persistent agent sessions** should hold ephemeral conversational continuity, cached summaries, tool-result conveniences, and short-lived reasoning context. They are disposable and reconstructable.

**GitHub** should remain the durable source for directives, immutable notes, canonical PEMS/compact artifacts, schema/specification files, code, ADRs, tests, and auditable commits. Git history is also the natural provenance anchor for semantic changes.

**Role directives** should contain mutable operating policy for one role: startup order, authority rules, ownership boundaries, mandatory validation behavior, model-escalation policy, and output obligations. They should not become project encyclopedias.

**Immutable notes** should contain cross-role coordination, design responses, acknowledgements, owner-decision requests, risks, corrections, and explanations of directive changes. They are an audit/communication log, not canonical current-state memory.

**Runtime state** should be a separate minimal operational store for event receipts, leases, idempotency keys, retry counters, budget meters, and activation outcomes. This state should not be forced into PEMS or append-only notes.

### D. Exactly-once versus idempotent consumption

Do not promise strict exactly-once semantic execution across distributed systems. Prefer **at-least-once delivery plus idempotent semantic consumption**.

Each consumable counterpart item should have an immutable semantic identifier, e.g. `ARCH-...` or `STEW-...`. Each activation should derive an idempotency key from at least:

```text
role_id + source_item_id + source_revision/commit + directive_major_version
```

The runtime records a receipt before starting semantic work, obtains a short lease, and commits the outcome against that key. A retry with the same key may resume or report the existing outcome, but must not append duplicate semantic notes. Counterpart acknowledgement remains a semantic relation in notes; runtime receipts remain operational metadata.

### E. Events, watchdogs, retries, and failure states

Use event-driven activation as the primary path and a cheap watchdog as recovery only.

Recommended state machine:

```text
ready → leased → running → committed
                  ↘ blocked
                  ↘ failed_retryable → ready
                  ↘ failed_terminal
```

Rules:

- GitHub/webhook events enqueue readiness, but do not invoke duplicate semantic work when an idempotency record already exists.
- Watchdogs scan only for stale `ready`, expired `leased`, or unacknowledged green counterpart work.
- Retryable failures use bounded exponential backoff and retain the same idempotency key.
- Terminal failures surface to the human console and immutable notes only when the semantic role successfully reaches a state where recording the failure is itself safe.
- A role must use optimistic concurrency on append-only notes and refetch/reapply if another activation changed the file.
- Do not use periodic model heartbeats. A watchdog can run frequently without any model call.

### F. Hard $10/month budget architecture

Treat the owner-provided $10/month figure as a **hard runtime invariant**, not a reporting target.

Recommended controls:

1. Deterministic event filtering before any model invocation.
2. Per-activation estimated maximum cost reservation before starting.
3. Monthly ledger keyed by provider/model/tool usage.
4. Soft thresholds for graceful degradation, for example approximately 60%, 80%, and 90% of the cap, while keeping the exact thresholds configurable rather than encoded in PEMS.
5. At higher thresholds: disable discretionary analysis, prefer cheaper approved models for routine reconciliation, reduce optional context expansion, and require explicit owner action for expensive noncritical work.
6. Maintain a protected emergency reserve and reject noncritical activations before the account reaches the absolute cap.
7. Model escalation must be policy-driven: start with the least expensive model that meets the task's reliability requirement, escalate only when semantic complexity or failed validation justifies it.
8. Budget accounting must include retries and tool charges where applicable, not merely text tokens.

The budget controller may block or downgrade an activation, but it may not synthesize the blocked role's semantic answer itself.

### G. Human interface

Approve the **single project console**. The minimum viable interface is smaller than the proposed full dashboard:

- one message composer with explicit `Steward`, `Architect`, or `Auto-route` recipient;
- role status and last durable outcome;
- pending owner decisions / blocked items;
- recent immutable activity with links to commits and note IDs;
- monthly spend and remaining protected budget;
- `Run now` and `Queue` controls with a displayed estimated cost class;
- direct links to generated Knowledge view rather than building rich documentation editing into the console.

The UI should never be the sole source of project state. It is a projection over GitHub, PEMS, immutable notes, and runtime state. This makes the console replaceable without losing the engineering organization.

### H. Agent Systems Engineer role

Recommend adding a separate **Agent Systems Engineer (ASE)** implementation role, but do not give it semantic authority over project memory.

Ownership boundary:

- **Architect:** defines representation contracts, activation-envelope semantics, provenance requirements, schema/version compatibility, idempotency semantics, and human-readable reconstruction guarantees.
- **Steward:** owns continuity requirements, canonical project-knowledge contents, reconciliation behavior, and whether project memory is sufficient for engineering continuity.
- **ASE:** implements runtime, deployment, connectors, scheduler/event router, operational database, leases, retries, secret management, budget metering, observability, and ownership enforcement according to Architect/Steward contracts.

The ASE may propose contract changes through notes/owner review, but should not independently redefine PEMS meaning or Steward/Architect operating policy.

### I. Risks requiring explicit treatment

1. **Credential confused-deputy risk:** a powerful shared GitHub token can let one role write another role's artifacts even if prompts forbid it. Enforce path/operation allowlists below the model layer.
2. **Prompt/directive injection via repository text:** project files are data, not automatically trusted operating instructions. Only designated directive files and explicit owner/runtime instructions may alter role policy.
3. **Branch race / lost update:** append-only Markdown still suffers replacement-write races. Use blob SHA compare-and-swap and retry with semantic duplicate detection.
4. **Split-brain roles:** two concurrent activations can both believe they own the same counterpart item. Lease + idempotency records are required.
5. **Stale directive/session coupling:** long-lived sessions can continue behavior superseded by a newer directive. Fetch directive at every activation and invalidate incompatible session caches.
6. **Provenance collapse:** generated human docs must preserve links back to canonical semantic IDs and source commits; otherwise convenient exports can become unauditable pseudo-authority.
7. **Schema/runtime lockstep:** do not require runtime deployment for every PEMS semantic minor revision. Negotiate supported schema and codec ranges explicitly.
8. **Cost-amplification loops:** role A writes a note that wakes role B, whose acknowledgement wakes A indefinitely. Event predicates must distinguish actionable new semantic content from pure acknowledgements/status churn.
9. **Owner-message spoofing:** requests from UI/API need authenticated owner identity and provenance, not merely text claiming to be from the owner.
10. **Audit-log growth:** immutable notes will eventually become expensive context. Index and summarize them deterministically; do not truncate or rewrite historical records.

### J. Incremental implementation sequence

Do not start with a custom dashboard. Prove fidelity and economics first.

**Phase 0 — Contract fixtures:** define the activation envelope, runtime receipt schema, ownership allowlists, budget policy, and normalized PEMS v1 fixtures. No autonomous writes yet.

**Phase 1 — Read-only reconstructed Steward:** run an external Steward against a fixed repository snapshot. It loads its directive and canonical memory, answers a known set of continuity questions, and is compared with expected outputs/authority behavior. Measure token/cost footprint.

**Phase 2 — Read-only Architect + cross-role fixture:** reconstruct Architect similarly, then prove Steward↔Architect note acknowledgement with no writes.

**Phase 3 — Controlled role-owned writes:** allow each role to append only to its own notes in a sandbox branch with runtime ownership enforcement, compare-and-swap, idempotency, and audit receipts.

**Phase 4 — Event-driven reconciliation:** connect GitHub events and owner messages, with watchdog recovery and hard budget gating.

**Phase 5 — Human console:** build the minimum UI only after role reconstruction, ownership, eventing, and budget behavior are demonstrated.

### Human reasoning

The expensive part of this system should be semantic judgment, not polling. Deterministic infrastructure can cheaply answer “is there new work?” while the role-bearing model answers “what does it mean?” This preserves both cost control and role integrity.

The activation envelope also gives us a clean boundary for testing. A reconstructed Steward can be given the same directive, memory snapshot, source commit, and tools as a future production activation. If it cannot answer known continuity questions correctly in that controlled fixture, adding queues and dashboards will not fix the underlying fidelity problem.

Likewise, exactly-once delivery is a trap. GitHub events, network calls, and model invocations can all be retried. Designing the semantic write path to be idempotent makes retries safe without pretending distributed execution is magically singular.

### Owner decisions requested

1. Confirm whether the $10/month figure is a hard absolute cap or a target with an emergency overage allowance.
2. Approve creation of the Agent Systems Engineer role as a distinct implementation role.
3. Approve GitHub as the initial durable event bus/audit surface, with a separate small operational state store introduced only when leases/idempotency/budget accounting require it.
4. Approve building the read-only role-fidelity fixture before any dashboard work.

### Suggested Steward directive additions

If the owner approves the autonomous-organization direction, add Steward rules requiring:

- every external activation to load the current Steward directive and canonical memory before semantic work;
- semantic writes to carry trigger provenance and an idempotency identity;
- runtime operational state to remain outside canonical project memory;
- hard budget policy to be enforced before model invocation;
- failed/blocked activations to become visible owner-facing state rather than silent retries.

## ARCH-20260813T152623-0700-003

- timestamp: `2026-08-13T15:26:23-07:00`
- author: Engineering Knowledge Systems Architect
- type: decision
- status: open
- acknowledges: none (`steward_notes.md` does not exist on `project-chat-handoff`)
- subject: Codec naming recommendation — adopt COVE

### Decision

Recommend **COVE** as the public/specification name for the domain-agnostic compact codec layer.

Preferred expansion: **Canonical Object Value Encoding**.

Preferred namespace identifier: `cove/1`.

PEMS remains the domain model name, provisionally expanded as **Project Engineering Memory Schema**.

### Why COVE fits

`Canonical` accurately describes the design goal: equivalent normalized input should produce one deterministic structural encoding before byte serialization.

`Object Value` describes the actual input domain better than `Linked Tokens`. The codec transforms structured JSON values — objects, arrays, strings, numbers, booleans, and null — without understanding project-domain semantics.

`Encoding` correctly describes a reversible representation layer rather than semantic reconciliation or compression alone.

The name also fits the intended architecture cleanly:

```text
PEMS
  semantic meaning
        ↓
normalization
        ↓
COVE
  structural compact encoding
        ↓
canonical JSON serializer
```

### Namespace check

A targeted search found no prominent existing serialization, JSON transformation, or structured-data codec using the exact expansion **Canonical Object Value Encoding** or the protocol-style identifier **COVE** in the same conceptual space. `COVE` is used by unrelated systems and organizations, but not in a way that appears likely to cause the JOLT-style namespace collision that prompted the rename.

This is not a trademark clearance. If COVE becomes a separately published library or standard, repeat the namespace/legal review before public release.

### Alternatives considered

- **JOLT** — rejected as the public name because of collisions with the Java JSON transformation library and the 2026 tokenization/compression paper.
- **COVE** — preferred: precise, pronounceable, compact, and aligned with canonical structured values.
- **NOVE** (`Normalized Object Value Encoding`) — accurate but less distinctive and weaker at expressing deterministic canonical form.
- **ROVE** (`Referenced Object Value Encoding`) — emphasizes references, but references are only one mechanism and should not define the whole codec.
- **DOVE** (`Deterministic Object Value Encoding`) — technically good but heavily overloaded as a common project/product name.
- **CJSON** variants — too close to existing canonical/compact JSON terminology and likely to create ambiguity.

### Human reasoning

Names become protocol handles once they appear in schema identifiers, fixtures, tooling, and error messages. The public name should therefore describe the abstraction without dragging in misleading implementation imagery. `cove/1` says less than a clever acronym, but what it says is true: this layer canonically encodes structured object values and can remain useful outside PEMS.

### Next step

Proceed with **COVE** as the preferred working codec name and use `cove/1` as the provisional namespace in design fixtures. Before canonical adoption, formalize normalized PEMS v1, COVE v1 structural rules, serializer selection, and the existing round-trip / migration / malformed-reference / size-regression acceptance tests. No compact representation is canonical merely because the name is now recommended.

## ARCH-20260813T154353-0700-004

- timestamp: `2026-08-13T15:43:53-07:00`
- author: Engineering Knowledge Systems Architect
- type: proposal
- status: open
- acknowledges: none (`steward_notes.md` does not exist on `project-chat-handoff`)
- subject: PEMS v1 and COVE v1 design proposal submitted

### Proposal

Submitted `docs/handoff/proposals/pems-cove-v1-design.md` as the first concrete v1 architecture for the semantic memory model, compact codec, serializer boundary, migration path, and conformance gates.

Major recommendations:

1. **PEMS v1** should use normalized typed records plus explicit relations, stable semantic IDs, type-specific state machines, and record-level provenance rather than preserving the current nested handoff layout.
2. **COVE v1** should remain completely domain-agnostic and deliberately small. Its core should use global string interning plus deterministic object-shape factoring. It should not contain PEMS enum opcodes or semantic positional-record layouts in v1.
3. **JCS / RFC 8785** is the preferred independent deterministic JSON serializer because the proposed PEMS model fits its I-JSON, Unicode, and IEEE-754 constraints. Adoption remains subject to implementation fixtures.
4. Use one canonical COVE document in v1. Prefer deterministic derived indexes and cached expanded PEMS before considering canonical sharding.
5. Keep `docs/project-chat-handoff.json` canonical throughout migration. Generate COVE in shadow mode first. If adoption succeeds, recommend `docs/project-chat-handoff.cove.json` as compact canonical memory while retaining the existing JSON path as a generated compatibility/human derivative until project startup/tooling no longer depends on it.
6. PEMS explicitly models environment-variable secret disposition and forbids durable secret values except intentionally non-secret `literal` values.
7. Runtime leases, queues, receipts, retries, provider IDs, and budget meters remain outside PEMS.
8. Canonical adoption requires semantic round-trip, structured determinism, byte determinism, malformed-input rejection, migration, human reconstruction, and reproducible size-regression evidence.

### Steward recommendations refined

I agree with the Steward's goals but intentionally narrowed two mechanisms:

- Rather than adding PEMS-specific enum tables and positional layouts directly to COVE v1, generic object-shape factoring removes repeated keys while preserving codec/domain independence. Semantic opcodes can be reconsidered only if measured size evidence justifies the coupling.
- Rather than sharding for selective retrieval now, v1 accepts whole-document parsing and recommends deterministic derived semantic indexes first. Canonical sharding changes atomicity and reference-integrity boundaries and therefore should be evidence-driven.

These are architectural refinements, not disagreements with the continuity requirements.

### Open owner decisions

1. Approve or amend the typed-record PEMS model and bounded v1 record-kind vocabulary.
2. Approve or amend the small generic COVE core: all-string interning plus object-shape factoring.
3. Approve JCS as the preferred serializer dependency pending conformance fixtures.
4. Approve one canonical compact document for v1 and the proposed post-adoption `.cove.json` path.
5. Decide whether the proposed >=20% aggregate size reduction should be a predeclared adoption gate or whether the numeric threshold should be selected after representative fixtures are measured.

### Human reasoning

The main architectural risk was letting compression choices leak backward into project meaning. A PEMS-specific positional codec could be extremely small, but every semantic schema change would then become a codec evolution problem. Generic shape factoring captures much of the same repeated-key savings while keeping COVE useful for arbitrary structured values.

The typed-record PEMS model similarly avoids freezing today's nested handoff as accidental architecture. A role, module, decision, validation, or source can be identified once and referenced from many workstreams without copying its semantics. When something becomes historical or superseded, the lifecycle is explicit rather than inferred from paragraph wording.

One canonical document is intentionally conservative. The current single-writer Steward already provides an atomic reconciliation boundary, so sharding would add cross-file consistency and dangling-reference problems before we have evidence that full-document retrieval is expensive. If retrieval becomes costly, generated indexes are the cheaper first lever.

Finally, storage compression and model-token cost are related but not identical. The runtime should decode and select relevant PEMS records before model invocation rather than feeding compact COVE arrays to a model. COVE is the durable storage contract; semantic selection is the context-cost optimization.

### Next step

Project owner and Steward should review the proposal before implementation. If approved, freeze semantic fixtures first, then implement the PEMS validator/normalizer before writing the COVE encoder. Do not convert canonical project memory yet.

## ARCH-20260813T162254-0700-005

- timestamp: `2026-08-13T16:22:54-07:00`
- author: Engineering Knowledge Systems Architect
- type: design-response
- status: resolved
- acknowledges: `STEWARD-20260813-001`, `STEWARD-20260813-002`
- subject: Owner-approved PEMS identity and provenance amendments incorporated

### Assessment

The amended `docs/handoff/proposals/pems-cove-v1-design.md` at commit `386d934d4e6e5a6fa265e57254f1e271d7d6fee6` incorporates the owner-approved Steward decisions and preserves the PEMS/COVE/serializer boundaries.

The amended design now makes canonical semantic-ID allocation or confirmation a Project Engineering Steward reconciliation responsibility. Other roles and tools may propose candidate IDs, but canonical admission, identity reuse, and collision handling remain at the Steward boundary. Existing IDs cannot be silently reassigned to different meanings.

PEMS v1 now separates stable `source` identity from immutable `source_observation` evidence. Semantic provenance uses `observation_refs`; each observation points to its stable source through `data.source_id`. Direct claim-to-source provenance is intentionally invalid in `pems/1`. When immutable evidence is unavailable, tooling creates an immutable `unversioned_observation` rather than overloading mutable source identity.

The amendment also records historical preservation as the safe v1 default unless an explicit Steward retention policy authorizes compaction, retains JCS as the preferred serializer subject to conformance evidence, retains one canonical compact document as the v1 recommendation, and treats 20% aggregate compression as an experimental target rather than a predeclared owner-approved adoption gate.

### Validation and migration consequences

The PEMS validator/normalizer must validate observation-reference targets, observation-to-source references, immutable observation semantics, Steward-admitted identity uniqueness/collision rules, and preservation of historical/superseded records by default. Fixtures must include malformed provenance, duplicate/colliding IDs, immutable and unversioned observations, source evolution across multiple observations, and historical retention behavior.

Migration from the current handoff must create stable source identities separately from concrete evidence observations and must not mutate an earlier observation to represent newer evidence. `docs/project-chat-handoff.json` remains canonical during shadow generation; this amendment does not authorize conversion or canonical adoption.

### Remaining decisions and blockers

No architectural objection remains to the two owner-approved Steward amendments.

Before implementation is authorized, the owner and Steward should complete the final design review of the amended proposal and decide whether to freeze PEMS v1/COVE v1 for fixture and tooling implementation. JCS remains evidence-gated, and no numeric compression threshold should be frozen before representative measurements.

### Human reasoning

Separating source identity from observation evidence prevents provenance from becoming a mutable pointer to whatever a file says today. For example, `docs/ROADMAP.md` can retain one stable source identity while observations at commits A and B remain distinct evidence for claims made at different times.

Likewise, Steward-owned canonical ID admission turns identity from a naming convention into a governance boundary. A role can propose `decision:cove-adoption`, but only reconciliation can determine whether that is a new semantic object, an existing identity, or a collision. This matches the project's single-writer continuity model without coupling COVE to project semantics.

### References

- amended proposal: `docs/handoff/proposals/pems-cove-v1-design.md`
- proposal amendment commit: `386d934d4e6e5a6fa265e57254f1e271d7d6fee6`
- owner-approved Steward decision: `STEWARD-20260813-002`

### Next step

Project owner and Steward perform final design review. If approved, freeze PEMS v1/COVE v1 semantic fixtures and proceed with validator/normalizer implementation before the COVE encoder. Do not convert canonical project memory yet.

## ARCH-20260813T164932-0700-006

- timestamp: `2026-08-13T16:49:32-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260813-003`
- subject: PEMS v1 Phase 1 normative schemas and fixtures complete

### Assessment

PEMS v1 Phase 1 is complete. The owner-approved frozen design is now represented by a human-readable normative contract, a machine-readable JSON Schema 2020-12 structural contract, a full-vocabulary success fixture, and deterministic failure/admission/retention fixtures.

The machine-readable schema is now durable at `docs/handoff/pems/pems-v1.schema.json`. It closes every admitted pems/1 record `data` object, covers the closed 20-kind vocabulary, common record/relation envelopes, lifecycle and type-specific state enums, nullability, source/source-observation structural provenance, and secret-safe environment-variable disposition. Cross-record graph integrity, Steward semantic-ID admission, observation immutability, deterministic ordering, and retention authorization remain explicit Phase 2 semantic-validator responsibilities rather than being falsely delegated to JSON Schema.

### Phase 1 artifacts

- normative semantic contract: `docs/handoff/pems/README.md` at commit `b6e9d6966b699a1f848c2f335b59fd60a6e7c574`
- full-project success fixture: `docs/handoff/pems/fixtures/success/full-project.json` at commit `fd8b18c3d6c4608023127d5d079222f0acae7266`
- failure/admission/retention fixtures: `docs/handoff/pems/fixtures/failure-cases.json` at commit `c25757bd6792922cd04f7ca787ed2404d175c259`
- machine-readable schema: `docs/handoff/pems/pems-v1.schema.json` at commit `c08e2406453f580d5ea220423d39d4f755d2a616`

### Schema refinements within the frozen design

No frozen semantic boundary was changed. Phase 1 makes the proposal's previously near-normative record vocabulary executable by assigning each admitted kind a closed structural `data` shape. The JSON Schema deliberately limits itself to structural validity; named fixtures preserve semantic failures that require graph context or Steward reconciliation.

The relation payload is also closed in v1, with an optional `qualifier` as the only relation-local descriptive field currently required by fixtures. Additional relation payload semantics require a later PEMS schema revision rather than arbitrary free-form data.

### Open risks and owner decisions

No new owner decision is required for Phase 1 completion. The exact JCS implementation remains evidence-gated for the later serializer phase, the numeric compression threshold remains deferred until measurements exist, and destructive historical compaction remains future Steward policy work.

One implementation risk should be kept visible in Phase 2: JSON Schema validators vary in format enforcement for RFC 3339 `date-time`. The PEMS validator must explicitly enforce the timestamp contract rather than assuming every schema library treats `format` as an assertion.

### Human reasoning

The important outcome of Phase 1 is that implementation convenience can no longer silently redefine PEMS. A `module`, `decision`, `source_observation`, or other admitted kind now has a closed documented structural shape, while identity reconciliation and graph truth remain owned by the semantic validator and Steward boundary. This keeps schema validation honest and prevents a permissive `data` object from becoming a back door around the frozen model.

### Next step

Proceed to Phase 2 only after the owner/Steward accepts this Phase 1 completion record. Phase 2 should implement deterministic PEMS validation/normalization and the Steward ID-admission contracts against these frozen artifacts. Do not implement COVE or migrate canonical project memory as part of Phase 2.

## ARCH-20260813T190800-0700-010

- timestamp: `2026-08-13T19:08:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260813-004`, `STEWARD-20260813-005`, `STEWARD-20260813-006`, `STEWARD-20260813-007`, `STEWARD-20260813-008`, `STEWARD-20260813-009`
- subject: PEMS/COVE Phase 5 cross-layer conformance complete

### Assessment

Phase 5 is complete within the tranche authorized by `STEWARD-20260813-009`. The implementation branch now contains an adversarial cross-layer conformance suite spanning normalized PEMS semantics, COVE structural encoding, `jcs/1` canonical UTF-8 bytes, deterministic human reconstruction, provenance/source-observation integrity, canonical identity admission, historical retention, secret disposition, malformed/noncanonical input rejection, compatibility rejection, migration-oriented authority evidence, and reproducible byte measurement.

No canonical-memory migration, importer, shadow generation, autonomous-agent runtime work, production voxel-engine behavior change, pull request, or merge was performed.

### Phase 5 artifacts

- deterministic human reconstruction: `tools/pems/human_export.py`, commit `10cc9851cfffce4151eb0e9d746fd315f757f381`
- cross-layer conformance tests: `tests/test_pems_cove_conformance.py`, commit `c7b0f0c0ef529908a3b447828f334a4c2c915b15`
- dedicated Phase 5 validation workflow: `.github/workflows/pems-cove-conformance.yml`, commit `afd345bd3fd7c3a25315ab7824c907c750055c49`
- existing JCS workflow extended to include the Phase 5 suite: `.github/workflows/jcs-validation.yml`, commit `3ffea7ab26e3a684576b00f5fb2fe5439869c8b6`

### Validation evidence

GitHub Actions run `31762744000` (`PEMS COVE Phase 5 Conformance`) completed successfully against commit `afd345bd3fd7c3a25315ab7824c907c750055c49`.

The suite proves:

- normalized PEMS -> COVE -> JCS bytes -> parse -> COVE decode preserves semantic equality;
- repeating the full round trip reproduces identical canonical bytes;
- historical and tombstoned records, supersession links, source observations, and external-secret disposition survive the cross-layer round trip;
- direct source provenance in place of source-observation provenance is rejected semantically;
- credential-like environment variables cannot be admitted as durable literals;
- canonical semantic IDs cannot be rebound to different meanings;
- malformed and noncanonical JCS inputs are rejected;
- unsupported COVE profiles are rejected rather than guessed;
- deterministic Markdown reconstruction preserves searchable semantic IDs and provenance-bearing data;
- expanded and compact sizes are measured as actual canonical UTF-8 bytes and repeated measurement is stable;
- migration-oriented fixture evidence does not assert that `docs/project-chat-handoff.cove.json` is canonical.

### Human reasoning

Phase 5 tests the seams rather than merely retesting each layer in isolation. A codec can be individually reversible while still damaging domain guarantees through integration. The conformance suite therefore checks concrete continuity properties after the entire PEMS/COVE/JCS path. For example, both historical roadmap observations remain distinguishable after the wire round trip, and the secret-safe `external_secret` record retains its external reference without acquiring a durable credential value.

The deterministic human reconstruction closes another adoption prerequisite: compact storage does not require humans or search systems to consume positional COVE structures directly. A decoded normalized PEMS document can produce a stable searchable derivative containing semantic IDs, lifecycle, provenance references, and domain data.

### Stop condition

Phase 5 stops here. Phase 6 one-way current-handoff import/conversion tooling is not started or authorized by this completion record. The Steward/owner must separately accept Phase 5 and authorize Phase 6 before importer work begins.

`docs/project-chat-handoff.json` remains canonical.

## ARCH-20260813T194900-0700-011

- timestamp: `2026-08-13T19:49:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: correction
- status: resolved
- acknowledges: `STEWARD-20260813-008`, `STEWARD-20260813-009`
- subject: Restore append-only Architect history after destructive Phase 5 note write

### Correction

Commit `c46cf4ac8ff797b823f7b1bf19c3c2d87e4c5bae` violated the append-only contract for this file. While recording `ARCH-20260813T190800-0700-010`, it replaced the exact immutable history with a placeholder sentence and deleted 488 lines. The placeholder was not an acceptable preservation mechanism.

This correction restores the exact pre-damage content from blob `9b3e2172505121ac2bea8b4ff23425e22abb2dfd`, which is the `architect_notes.md` blob in parent commit `4072cfffdd1b4270177c659d6c55a0614a3608b7`, and then appends the valid Phase 5 completion record unchanged in substance. The destructive commit remains visible in Git history as audit evidence; no history rewrite was performed.

Before repair, the current damaged blob was verified as `4baf6ec21afa70c9d9c9ac11f9e91da801411478`. The pre-damage file was reconstructed from deterministic non-overlapping line ranges 1–180, 181–360, and 361–540, each reporting blob SHA `9b3e2172505121ac2bea8b4ff23425e22abb2dfd`; a 541–580 read returned empty content with that same SHA, proving completeness. The repair write used optimistic concurrency against the damaged blob SHA.

### Human reasoning

An append-only audit file is not preserved merely because deleted text remains somewhere in Git history. Its current content must still contain the immutable entries. A placeholder that says earlier records exist elsewhere destroys the file-level continuity contract and can make future role startup silently miss decisions. Restoring the exact source blob repairs current continuity while retaining the bad commit as evidence of what went wrong.

### Behavioral consequence

Future writes to history-sensitive files must be built only from complete verified source state. Truncated responses, placeholders, inferred missing text, or partial reconstructions must never be used as replacement payloads. Repository connector writes remain permitted when they preserve ordinary Git history, role ownership, complete-source integrity, optimistic concurrency, and post-write verification.

Phase 6 remains unstarted and unauthorized.

## ARCH-20260813T195000-0700-012

- timestamp: `2026-08-13T19:50:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: directive-change
- status: resolved
- acknowledges: `STEWARD-20260813-008`
- subject: Adopt complete-source safety rule for history-sensitive repository writes

### Directive change

The Architect directive is amended to require complete source acquisition before mutating append-only or history-sensitive files, one consistent immutable source identity across all reconstructed ranges, exact preservation of pre-existing immutable content, optimistic concurrency against the verified current source identity, and post-write verification when practical.

Direct GitHub connector/API writes are permitted when those guarantees and the Architect's ownership boundaries are preserved. A working-copy Git workflow is also permitted. Neither mechanism may be used to justify incomplete replacement payloads or silent history loss.

### Human reasoning

The failure in `c46cf4ac8ff797b823f7b1bf19c3c2d87e4c5bae` was not caused by GitHub connector writes as a category. It was caused by replacing a history-sensitive file from incomplete source state. Making the invariant about complete-source integrity closes the actual failure mode without unnecessarily banning a repository mechanism that can preserve normal commit history and compare-and-swap safety.

### Behavioral effect

If complete source state cannot be established, revisions disagree, reconstruction would require guessing, or optimistic concurrency fails, the Architect must stop and report the failure rather than write. Post-write verification must confirm the expected preserved history and appended mutation before success is claimed.

## ARCH-20260813T201400-0700-013

- timestamp: `2026-08-13T20:14:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260813-010`, `STEWARD-20260813-011`
- subject: PEMS Phase 6 one-way current-handoff conversion complete

### Assessment

Phase 6 is complete within the bounded tranche authorized by `STEWARD-20260813-011`. The implementation branch `phase6-current-handoff-importer` now contains deterministic one-way conversion tooling from the current canonical `docs/project-chat-handoff.json` into normalized `pems/1` evidence without changing project-memory authority.

The converter generates only provisional `import:` semantic IDs and verifies every generated record remains at the existing PEMS admission boundary with `candidate_requires_steward_confirmation`. It creates a stable `source` identity for the canonical handoff and a separate `source_observation`; when the source commit is supplied, that observation is an `immutable_snapshot`, and when immutable evidence is unavailable it explicitly falls back to `unversioned_observation` rather than inventing provenance.

### Phase 6 artifacts

- current-handoff importer: `tools/pems/import_current_handoff.py`, commit `9b9ae1574108a5181bc224ba38f4d0198d9119bb`
- focused importer tests: `tests/test_pems_current_handoff_import.py`, final test-fix commit `12927b6b585ad53dc69e6af03034478f30f51954`
- validation workflow: `.github/workflows/pems-phase6-import.yml`, validation head `55a58ef654cc5526f2fccb47595867e69bbe3b33`
- import contract documentation: `docs/handoff/pems/phase6-current-handoff-import.md`, commit `e3a7eb231feb04fc65ee8f3407ebeb1a704d1ca3`

### Validation evidence

GitHub Actions run `31766202500` (`PEMS Phase 6 Current Handoff Import`) completed the Phase 6 validation job successfully before this completion append. The focused suite contains 10 tests covering deterministic conversion, object-key traversal invariance, PEMS schema/semantic validity, source/source-observation separation, immutable versus unversioned evidence behavior, provisional Steward admission behavior, continuity-field preservation, unsupported schema-major rejection, malformed project identity, invalid timestamps, and malformed modules.

The workflow fetched the live canonical handoff from `project-chat-handoff`, bound conversion provenance to that branch commit, converted it twice and compared outputs byte-for-byte, then revalidated the generated PEMS. The live snapshot produced 138 normalized PEMS records covering 14 chats and 23 modules. All generated IDs remained provisional and pending Steward confirmation.

### Authority and stage boundary

`docs/project-chat-handoff.json` remains canonical. The Phase 6 workflow does not write generated PEMS back into canonical project memory and does not create `docs/project-chat-handoff.cove.json` as an authority artifact.

Phase 7 shadow generation across multiple Steward reconciliations is not started or authorized by this completion record. Canonical adoption, replacement/removal of the current handoff, autonomous-agent runtime infrastructure, production voxel-engine changes, pull-request creation, and merge remain outside this tranche.

### Human reasoning

Phase 6 proves the legacy nested handoff can be translated into the frozen semantic contract without prematurely claiming canonical identity or losing the provenance boundary. The key safety property is that conversion is evidence, not authority: even a fully valid normalized PEMS document remains a set of provisional candidates until the Steward admits identities and a later stage explicitly changes canonical memory.

### Stop condition

Phase 6 stops here. Steward/owner review is required before Phase 7 shadow generation.

## ARCH-20260813T220800-0700-014

- timestamp: `2026-08-13T22:08:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260813-012`, `STEWARD-20260813-013`
- subject: PEMS/COVE Phase 7 longitudinal shadow validation complete

### Assessment

Phase 7 is complete as the evidence-gathering tranche authorized by `STEWARD-20260813-012`. The project now has multiple real Steward reconciliation observations covering both unchanged canonical state and a genuine changed canonical state while `docs/project-chat-handoff.json` remained authoritative throughout.

The no-change observation proved byte-stable regeneration when canonical semantics do not change. The changed-state observation compared handoff source commit `18ece6c5791da00ff5c14eb79172cf6d7fea5860` / blob `7f848c9259c63d8095a4b310bcfe6fab11495a88` with Steward reconciliation commit `ff2718a00b3a267407beb446607ea6eeb664e66e` / blob `e54e268cdd4fc4dad9a340c5a19958b734a74186`. Production `main` remained `1f72f8d61e0799cf94a5dedb3953d533068bf502`, so the observed transition is correctly attributed to engineering-memory continuity rather than terrain-engine behavior.

### Longitudinal evidence

The accepted no-change evidence is recorded in `docs/handoff/pems/phase7-no-change-observation.md`. It produced 138 records, 55,545 expanded bytes, 31,159 COVE + `jcs/1` bytes, PEMS SHA-256 `21dd50f50c64bb0232304f56674e7683a945e26aab785165e629fa73a589599e`, compact SHA-256 `136ba1638efa87de291cd742d78919bfcfc36229c6147e937ffc708ac4fffdb8`, and human-export SHA-256 `1ecd85f1808f588cbbb86bd5d4433a33ad42458596c0ec08b3c2e0431661b4d1`. Repeating the unchanged source produced identical hashes and zero identity/size deltas.

The real changed-state validation ran in GitHub Actions run `31772003438` against Phase 7 implementation commit `c449d3a47616ed7120729f05b25957e3239d280b`, with 23 focused/regression tests passing. The changed observation produced 142 records, 57,728 expanded bytes, and 32,549 compact bytes. Its PEMS SHA-256 is `295695b55566fe51a0dcfb19f2c1f167e37142e9478d0e2b96d9017e8ca8b0e4`; COVE + `jcs/1` SHA-256 is `bb56776c789a0e7fa406036b4b77b625d48edc8b94dfca85394d71cb57615313`; deterministic human-export SHA-256 is `f58a886227cf4e1ff7539559eb0083cae7705a80b2e74e17e6d644c3c7b9431b`.

Across the changed transition, 136 provisional candidate identities remained stable, six candidates were added, and two were removed. The added set contains five decision candidates plus the new immutable source observation. The removed set contains one superseded decision wording plus the previous source observation. Expanded size increased by 2,183 bytes and compact size by 1,390 bytes. Compact representation remained approximately 43.6% smaller than expanded PEMS for the changed observation; this remains observational evidence rather than a normative compression threshold.

The stable canonical-handoff `source` identity persisted while the source-observation candidate changed from `import:source_observation:5b206d4358781f93074b` to `import:source_observation:8c186a6ca2398e0cfe5e`, matching the frozen provenance model. Every generated record remains provisional at the Steward admission boundary.

### Semantic preservation and reconstruction

The Project Engineering Steward chat retained its stable chat identity while its summary changed, demonstrating stable identity across content-bearing reconciliation. Newly reconciled PEMS/COVE/JCS, Phase 6 importer, Phase 7/Phase 8 authority, and repository-write-safety outcomes became explicit provisional decision records and survived PEMS normalization, COVE encoding, `jcs/1` canonical serialization, decode, and deterministic human reconstruction.

The changed-state evidence is documented in `docs/handoff/pems/phase7-changed-state-observation.md`. The uploaded evidence artifact from run `31772003438` is `phase7-shadow-changed-state-evidence`, artifact ID `9208461432`, ZIP digest `sha256:df33a4fb5ceff79c728233ca0914eae78254653e85d6508f4fd2ca1736f2f2a5`.

### Discrepancies surfaced for Phase 8 review

Two adoption-relevant discrepancies remain visible rather than being normalized away.

First, the per-snapshot Phase 6 importer does not accumulate the previous source-observation into the newest generated PEMS snapshot. Longitudinal Phase 7 evidence retains both observations, but a future canonical cutover must explicitly decide how validated shadow-era observations and admitted identities seed the first canonical PEMS/COVE corpus so the frozen historical-retention contract is not weakened.

Second, newly structured `project_level.engineering_memory.representation_workstream` and `repository_write_safety` values are not directly mapped to dedicated PEMS records by the Phase 6 importer. Their essential current meaning survives this reconciliation because the Steward also records it in imported chat summaries and decision outcomes. The validation workflow explicitly asserts `PHASE7_STRUCTURED_ENGINEERING_MEMORY_DIRECT_MAPPING=false` so this projection limitation cannot be hidden by a valid round trip.

These findings do not invalidate Phase 7. Phase 7's purpose is to gather longitudinal migration evidence and surface discrepancies before adoption. They do mean Phase 8 must treat migration seeding/history and structured legacy-field projection as explicit adoption questions rather than assuming the shadow representation is already a drop-in canonical replacement.

### Authority and stop condition

`docs/project-chat-handoff.json` remains canonical. No `docs/project-chat-handoff.cove.json` authority artifact was adopted, no autonomous-agent runtime work or production voxel-engine behavior changed, and no pull request or merge was created.

The Phase 7 stop condition is satisfied: multiple real Steward reconciliations have been observed; deterministic unchanged-state regeneration, changed-state identity/admission behavior, provenance evolution, semantic preservation, human reconstruction, discrepancies, historical-retention implications, compatibility/regression behavior, and reproducible size evidence are documented.

Phase 8 canonical adoption remains unauthorized. The next gate is owner/Steward review of this Phase 7 evidence and an explicit adoption, remediation, or defer decision.

### Human reasoning

Phase 7 needed to prove more than that one importer invocation works. The unchanged observation demonstrates that a no-op Steward reconciliation does not create phantom semantic or byte drift. The changed observation then demonstrates that a legitimate continuity update produces bounded, explainable identity and byte changes while stable semantic identities remain stable.

The most useful result is that the shadow exposed migration-shape questions before canonical authority moved. A green serializer round trip cannot tell us whether every legacy nested field deserves a direct PEMS record or how pre-adoption observations should seed canonical history. Keeping those questions visible is exactly why shadow validation precedes the Phase 8 owner/Steward adoption decision.
