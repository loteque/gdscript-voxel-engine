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

## ARCH-20260813T173203-0700-007

- timestamp: `2026-08-13T17:32:03-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260813-004`
- subject: PEMS v1 Phase 2 validation, normalization, and Steward ID admission complete

### Assessment

PEMS v1 Phase 2 is complete. The frozen Phase 1 semantic contract is now backed by deterministic structural and semantic validation, deterministic normalization, Steward ID-admission behavior, stable diagnostics, fixture execution, unit tests, and isolated GitHub Actions validation.

The Phase 2 implementation keeps schema validation, semantic graph validation, normalization, Steward admission, and retention-policy checks as distinct responsibilities. It does not introduce COVE/JCS semantics or autonomous runtime state into PEMS.

### Validation evidence

- feature branch head: `e113f9c4053cb6cac6a98485231095dba2ef33ef`
- PEMS Validation run #4: `31757337308`, conclusion `success`
- frozen Phase 1 fixture suite: `28/28` passing
- Phase 2 unit tests: passing
- normalization idempotence: covered and passing
- input insertion/traversal order independence: covered and passing
- Steward same-identity reuse/confirmation: covered and passing
- conflicting canonical-ID meaning/rebinding rejection: covered and passing
- no COVE, JCS serializer, canonical-memory migration, or autonomous-runtime scope leakage detected

### Implementation notes

A real Phase 2 defect found by CI was corrected without changing the frozen fixtures: rejected Steward ID-admission decisions now return no canonical ID rather than leaking the rejected candidate ID. A separate unit-test defect was also corrected so canonical-ID rebinding is tested by mutating an identity-bearing field on the known `module:chunk-streamer` record rather than a display-only field.

The validator uses explicit JSON Schema format checking for RFC 3339 timestamps, addressing the Phase 1 risk that schema-library `format` handling may otherwise be advisory.

### Open risks and owner decisions

No new owner decision is required for Phase 2 completion. Phase 3 remains separately gated. The exact JCS implementation remains a later evidence-gated serializer choice, numeric compression acceptance remains deferred until measurements exist, and canonical project-memory migration remains unauthorized.

### Human reasoning

Phase 2 proves that PEMS meaning can stand on its own before compact encoding exists. Equivalent semantic input normalizes identically regardless of insertion order, invalid provenance and identity conflicts fail at explicit boundaries, and Steward reconciliation can distinguish candidate identity from admitted canonical identity. That makes COVE a representation layer over a stable semantic contract rather than a place where semantic cleanup quietly occurs.

### Next step

Owner/Steward should accept this Phase 2 completion record before Phase 3 begins. Phase 3 may then implement generic COVE v1 encode/decode against generic JSON fixtures first and normalized PEMS fixtures second. Do not implement JCS serialization or migrate canonical project memory as part of Phase 3.

## ARCH-20260813T180200-0700-008

- timestamp: `2026-08-13T18:02:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: owner/Steward acceptance of Phase 2 in the active assignment; latest durable Steward note remains `STEWARD-20260813-004`
- subject: COVE v1 Phase 3 generic structural codec complete

### Assessment

COVE v1 Phase 3 is complete. The frozen domain-neutral structural codec is implemented, documented, fixture-backed, and validated in GitHub Actions. COVE remains independent from PEMS semantics: it encodes JSON values structurally and only receives normalized PEMS as ordinary input through the public PEMS normalization boundary.

The implemented core uses deterministic global string interning plus deterministic object-shape factoring, preserves raw JSON primitive semantics, rejects malformed references/tags/version/profile conditions with deterministic diagnostics, and keeps COVE versioning independent from PEMS versioning.

### Validation evidence

- feature branch: `cove-v1-codec`
- validation workflow commit: `53e1b9aff9937b99a9692a23bb40ea6ef36bfe9a`
- COVE Validation run #1: `31759268282`, conclusion `success`
- generic COVE fixture suite: passing
- malformed-input fixtures: passing at declared diagnostic boundaries
- COVE Phase 3 unit tests: passing
- deterministic encoding / object insertion-order independence: covered and passing
- generic encode/decode round trips: covered and passing
- normalized PEMS encode/decode round trip through `normalize_document()`: covered and passing
- no PEMS record-kind, chat, role, decision, provenance, terrain-domain, or Steward-admission logic is present in COVE
- no JCS serializer, handoff conversion, shadow migration, canonical switch, autonomous runtime, or production terrain-engine scope leakage was introduced

### Size observations

The fixture runner executed its observational structural-character measurements as part of the successful Actions fixture step. Exact stdout counts are not available through the current GitHub connector response, so no numeric size claim is recorded here. No compression threshold is introduced or implied by Phase 3.

### Design contradictions

No contradiction in the frozen COVE v1 design was exposed by implementation or validation. The generic-first test ordering remained viable, and normalized PEMS passed through COVE without requiring domain-specific codec behavior.

### Human reasoning

Phase 3 answers the architectural question that justified separating PEMS from COVE: the compact representation can be deterministic and lossless without understanding project meaning. A normal JSON object and a normalized PEMS document traverse the same codec machinery; PEMS-specific semantics remain upstream. That means later serializer, migration, and adoption work can build on COVE without turning the codec into a second semantic system.

### Next step

Owner/Steward should review and accept this Phase 3 completion evidence before Phase 4 begins. Phase 4 may evaluate and implement deterministic byte serialization, with RFC 8785 JCS still preferred but evidence-gated. Do not convert canonical project memory or begin shadow migration as part of Phase 4 unless separately authorized.

## ARCH-20260813T183700-0700-009

- timestamp: `2026-08-13T18:37:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260813-005`, `STEWARD-20260813-006`
- subject: PEMS/COVE Phase 4 deterministic JCS serialization complete

### Assessment

Phase 4 is complete. RFC 8785 is now implemented as the independent `jcs/1` canonical UTF-8 serialization boundary over COVE, with `rfc8785==0.1.4` as the evidence-backed current Python implementation. PEMS, COVE, and JCS remain independently versioned and responsibility-separated.

The owner/Steward-approved PEMS integer portability rule is enforced structurally in the current closed pems/1 vocabulary. The only integer-valued schema members currently admitted are `source_observation.data.evidence_locator.line_start` and `line_end`; both are bounded to the inclusive interoperable range ending at `9007199254740991`. Larger exact integers are not silently converted and require an explicitly modeled string representation in a future schema if a domain actually needs them.

### Implementation and validation evidence

- feature branch: `cove-deterministic-serialization`
- JCS byte boundary: `cef49e2c8d3ce8881192a1a108cc7ee5cd339c50`
- pinned `rfc8785==0.1.4` dependency: `4763635d6da43b452c9e077e551dfd0bff1a004b`
- generic JCS tests: `5b924d1eb0282a1c67f04cbfc82565f5fc36bc60`
- initial JCS validation workflow: `821008afecbd5ccbc81d3f52c124d5aeece82461`
- PEMS numeric schema bound: `f789e5bd98c3984c8ea1f8c6e712c4c75d6d38ed`
- PEMS boundary unit test: `c03cecb3369ce6fe89a2305f154818ffc461e42e`
- normalized PEMS -> COVE -> JCS -> parse -> COVE decode round-trip test: `d8bac6dbdf77422b514b7ede3eab1dbc14cfe700`
- Phase 4 CI includes PEMS boundary, COVE regression, and JCS tests: `8549d52b771a781b57e42f32caee3e32a9dcad66`
- normative PEMS numeric documentation: `5e825b5f25761e079fac3b16f52e2b5b768ea6ce`
- JCS Validation run #6: `31761066704`, conclusion `success`
- PEMS tests: 7 passing
- COVE regression tests: 11 passing
- JCS Phase 4 tests: 10 passing

The JCS tests cover the published RFC 8785 sample, representative number serialization boundaries, negative zero canonicalization, deterministic key ordering, safe/unsafe integer behavior, malformed and noncanonical input rejection, serializer metadata, generic COVE round trips, and normalized PEMS byte round trips. RFC 8785 itself records multiple independent implementation families and reference test data; this phase uses that published ecosystem evidence rather than adding a second JCS library dependency solely for duplicate CI serialization.

### Byte-size observation

The successful CI run measured actual canonical UTF-8 bytes for the normalized full-project PEMS fixture:

- expanded normalized PEMS: `14901` bytes
- COVE + `jcs/1`: `10331` bytes
- reduction: `4570` bytes, approximately `30.7%`

This is observational evidence for one representative fixture, not a normative compression threshold or adoption gate.

### Numeric-domain finding

The approved numeric restriction belongs to PEMS meaning, while JCS simply serializes conforming values. In the current closed pems/1 vocabulary, enforcing maximum bounds on the only integer-valued schema fields covers the complete admitted integer-number surface. No duplicate recursive numeric validator was added. Any future schema revision that introduces another integer-valued PEMS member must carry the same portability rule or explicitly model a string form.

### Scope and contradictions

No further contract contradiction was exposed. No handoff conversion, legacy importer, shadow migration, canonical-memory switch, autonomous-agent runtime infrastructure, PR/merge, or production voxel-engine change was introduced.

### Human reasoning

Phase 4 proves the byte boundary without moving project authority. A normalized PEMS document can become a domain-neutral COVE structure, then deterministic RFC 8785 UTF-8 bytes, and return to identical normalized semantics. The numeric bound prevents Python-only arbitrary-precision integers from becoming canonical project meaning that other common JSON runtimes cannot reproduce exactly.

The measured size result is encouraging, but it should remain evidence rather than policy. The next phase should broaden conformance and migration evidence before any discussion of canonical adoption.

### Next step

Owner/Steward should review and accept Phase 4 before Phase 5 begins. Phase 5 may build the broader conformance suite described by the frozen staged plan. Canonical migration remains separately gated and is not authorized by this completion record.

## ARCH-20260814T021245-0700-010

- timestamp: `2026-08-14T02:12:45-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: successful Phase 8 cutover evidence and Steward-confirmed initial corpus admission
- subject: PEMS/COVE Phase 8 canonical cutover complete

### Assessment

Phase 8 is complete. The previously shadow-only PEMS/COVE representation has passed the authorized cutover gates and is now the canonical project-memory representation on `pems-phase8-cutover`.

Canonical authority is now `docs/project-chat-handoff.cove.json`. The expanded `docs/project-chat-handoff.json` remains a generated compatibility derivative, and `docs/handoff/pems/project-chat-handoff.md` remains the deterministic human reconstruction. This authority switch does not elevate project memory above repository truth, ADRs, ROADMAP.md, tests, or validation artifacts; it changes only the canonical representation of the continuity layer.

### Verified execution evidence

- GitHub Actions workflow run: `31786729203`
- workflow conclusion: `success`
- full representation regression: `success`
- admitted canonical corpus generation: `success`
- deterministic regeneration verification: `success`
- canonical cutover artifact commit step: `success`
- cutover commit: `a7b0e755e583b18eb8a1c671e3a66eeec8c50604`
- cutover commit message: `Adopt canonical PEMS/COVE project memory`

The successful workflow generated and committed the canonical compact artifact, expanded compatibility derivative, admission manifest, deterministic human reconstruction, and Phase 8 cutover evidence.

### Canonical corpus and admission

The committed Phase 8 evidence records:

- admission: `steward_confirmed_initial_corpus`
- admitted identity count: `156`
- record count: `156`
- relation count: `0`
- retained historical decision: `pems:decision:b54a6445b1ce2b815b56`
- retained historical source observation: `pems:source_observation:5b206d4358781f93074b`
- source observations preserved: `pems:source_observation:5b206d4358781f93074b`, `pems:source_observation:8c186a6ca2398e0cfe5e`
- source snapshots preserved: `18ece6c5791da00ff5c14eb79172cf6d7fea5860`, `ff2718a00b3a267407beb446607ea6eeb664e66e`

The admission manifest preserves the imported-to-canonical semantic ID mapping used for the initial corpus. Historical preservation therefore survived the authority switch rather than being collapsed into only the latest observation.

### Exact representation evidence

- canonical compact artifact: `docs/project-chat-handoff.cove.json`
- compact bytes: `35872`
- compact SHA-256: `7e2f6300fa6bd5a3aa982a7e6286e7d6285c1d41bc417c4753042562c5b7c99d`
- expanded compatibility derivative: `docs/project-chat-handoff.json`
- expanded bytes: `62069`
- expanded SHA-256: `f6f2e9c097b2ba690d24e3bbb7053a0fb91e46e6fd947f9b215b7ae0de405d7a`
- deterministic human reconstruction: `docs/handoff/pems/project-chat-handoff.md`
- human SHA-256: `ad740bad0d7916d9d988e440a90e5745e270dbbe7b38da574b041a8375da6585`

These values match `docs/handoff/pems/phase8-cutover-evidence.json` as committed by the successful cutover.

### Governance reconciliation

The Architect recognizes the Steward-confirmed initial corpus admission as the semantic authority decision required by the frozen PEMS identity contract. The Architect's completion determination is limited to representation, determinism, provenance preservation, and successful execution of the adoption gates. Ongoing reconciliation of project meaning, canonical ID admission for future records, retention decisions, and continuity sufficiency remain Steward responsibilities.

The compact COVE artifact is authoritative only after successful PEMS semantic admission. COVE remains domain-neutral, `jcs/1` remains the independent deterministic byte contract, and neither codec nor serializer acquires Steward semantics through this cutover.

### Operational follow-up

1. Future Steward reconciliations should treat `docs/project-chat-handoff.cove.json` as the canonical continuity artifact and regenerate both compatibility derivatives deterministically.
2. `docs/project-chat-handoff.json` must not regain independent authority through manual edits; changes should originate from admitted PEMS state and regenerate the derivative.
3. Deterministic regeneration and full representation regression should remain mandatory cutover/reconciliation safeguards.
4. The legacy JSON compatibility derivative may be retired only through a separate explicit compatibility decision after all receiving workflows and tooling have migrated.
5. Any future PEMS, COVE, or JCS major-version change requires its own versioned migration and evidence; Phase 8 does not authorize silent contract evolution.

### Human reasoning

The cutover is complete because the authority change is now backed by the same properties that were deliberately kept separate during the staged migration: PEMS meaning was admitted by the Steward boundary, COVE encoded that admitted meaning without becoming semantic, JCS made the bytes deterministic, historical observations survived migration, the human reconstruction is reproducible, and CI proved regeneration stability before committing the new authority artifacts.

This closes the representation migration without changing production voxel-engine behavior or starting the separately proposed autonomous-agent runtime work.
