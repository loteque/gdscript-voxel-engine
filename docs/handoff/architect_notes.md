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

The machine-readable schema is now durable at `docs/handoff/pems/pems-v1.schema.json`. It closes every admitted pems/1 record `data` object, covers the closed 20-kind vocabulary, common record and relation envelopes, lifecycle and type-specific state enums, nullability, source/source-observation structural provenance, and secret-safe environment-variable disposition. Cross-record graph integrity, Steward semantic-ID admission, observation immutability, deterministic ordering, and retention authorization remain explicit Phase 2 semantic-validator responsibilities rather than being falsely delegated to JSON Schema.

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

## ARCH-20260813T235900-0700-015

- timestamp: `2026-08-13T23:59:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260813-012`, `STEWARD-20260813-013`, `ARCH-20260813T220800-0700-014`
- subject: Pre-Phase-8 PEMS/COVE remediation complete

### Assessment

The two adoption findings surfaced by Phase 7 are remediated on branch `pems-phase8-remediation` without changing project-memory authority or extending the frozen `pems/1` record vocabulary.

The structured legacy engineering-memory fields now have direct normative PEMS projection in the migration path. Each `project_level.engineering_memory.representation_workstream` field becomes a deterministic `decision` record using the existing closed decision schema, and `repository_write_safety` becomes a deterministic `requirement` record using the existing requirement-state vocabulary. Unsupported repository-write-safety status values fail explicitly rather than being stored in an arbitrary data escape hatch.

The migration-seeding path now accepts ordered validated handoff snapshots. The newest snapshot supplies current semantic records; earlier semantic IDs absent from the newest snapshot are retained with historical lifecycle. This preserves validated prior immutable source observations and removed historical records while avoiding duplicate current identities. Stable IDs present in the newest snapshot remain represented by the newest state.

All imported and seeded IDs remain provisional and return `candidate_requires_steward_confirmation`; this remediation does not perform Steward admission.

### Validation evidence

GitHub Actions run `31778186729` (`PEMS Pre-Phase-8 Remediation`) completed successfully against remediation head `e272d1eaff8c782ffad02554705d86a526cdcf25` before this completion-record append. The regression gate reported `55 passed, 41 subtests passed`.

The real Phase 7 handoff pair was used as migration input:

- prior source commit `18ece6c5791da00ff5c14eb79172cf6d7fea5860`, handoff blob `7f848c9259c63d8095a4b310bcfe6fab11495a88`;
- current source commit `ff2718a00b3a267407beb446607ea6eeb664e66e`, handoff blob `e54e268cdd4fc4dad9a340c5a19958b734a74186`.

The resulting noncanonical migration seed contains 156 records and 156 provisional IDs. It preserves both immutable source-observation candidates:

- `import:source_observation:5b206d4358781f93074b`;
- `import:source_observation:8c186a6ca2398e0cfe5e`.

The prior source observation and removed decision `import:decision:b54a6445b1ce2b815b56` are retained as historical records. The workflow directly asserts structured engineering-memory mapping, historical seeding, provisional admission behavior, schema and semantic validity, deterministic repeat generation, PEMS/COVE/`jcs/1` semantic round trip, deterministic human reconstruction, and canonical-byte repeatability.

The seeded corpus measures 62,995 expanded JCS bytes and 36,184 COVE + `jcs/1` bytes. Its normalized PEMS SHA-256 is `57f1ee06478b15fe873e067f03b021bee2586d9c77cc19e01dece9df96efd5b4`; compact SHA-256 is `6437419c6ccacf5e057698f3c3da51e01e7d805e203cc636e8d029422ba1da9c`; deterministic human reconstruction SHA-256 is `1addd8efcdfadeda8dd39ef122670e13d6a67b72abedf76bef9459ae96639737`.

The uploaded evidence artifact is `pems-pre-phase8-remediation-evidence`, artifact ID `9210677542`, ZIP digest `sha256:014db6ca637f17d416bf3eedc9546d6fd2b985bae9ea5adf1d98248c1967c4f1`.

### Schema and design outcome

No contradiction requiring a `pems/1` schema change was found. The existing `decision`, `requirement`, `source_observation`, lifecycle, provenance, normalization, COVE, and JCS contracts are sufficient for the remediation.

This tranche adds a migration-specific importer/seeding layer rather than redefining the Phase 6 per-snapshot importer. The original Phase 6 importer remains useful as a single-snapshot evidence converter; Phase 8 migration, if authorized, should use the remediated migration-seed path so structured fields and validated shadow history are not dropped.

### Remaining Phase 8 gate

The two Phase 7 adoption discrepancies no longer block a Phase 8 decision. The remaining work is governance, not representation repair: the owner and Project Engineering Steward must separately decide whether to adopt, defer, or further constrain canonical PEMS/COVE migration, and the Steward must define/perform canonical identity admission as part of any authorized cutover.

`docs/project-chat-handoff.json` remains canonical. No `docs/project-chat-handoff.cove.json` authority artifact was created or adopted, no production voxel-engine behavior changed, no autonomous-agent runtime work was performed, and no pull request or merge was created.

### Human reasoning

Phase 7 showed that the representation worked but exposed two sharp migration edges: a newest-snapshot-only conversion would forget earlier source observations, and two newly structured Steward fields survived only indirectly. The remediation fixes those edges without redesigning PEMS. Think of it as packing the old photo album into the moving boxes and labeling two boxes that previously relied on someone remembering what was inside.

The system is now technically ready for a separate Phase 8 adoption decision, but technical readiness is not authority. The switch remains closed until the owner and Steward explicitly open it.

## ARCH-20260814T021500-0700-016

- timestamp: `2026-08-14T02:15:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: directive-change
- status: resolved
- acknowledges: `STEWARD-20260813-001` through `STEWARD-20260813-013` (current Steward coordination history reviewed)
- subject: Encode proven owner/Architect/Steward collaboration protocol

### Directive change

The Architect directive is amended to encode the collaboration and execution patterns demonstrated during the staged PEMS/COVE program: explicit owner authorization as the strategic gate; bounded technical tranches with acceptance criteria and stop conditions; complementary Architect/Steward ownership; autonomous execution inside an approved envelope; genuine changed-state evidence rather than manufactured deltas; no-change results as valid evidence; discrepancies as stop-and-surface conditions; small remediation tranches followed by revalidation; exhaustive safe tool/repository reasoning before declaring a blocker; strict prohibition on fabricated validation; plain-language owner communication before technical detail; and a distinction between technical success and governance closeout.

The directive also makes explicit that canonical authority changes require separately verified owner/Steward authorization and evidence, and that collaboration does not weaken single-writer role boundaries.

### Human reasoning

The PEMS/COVE work succeeded because each role had enough autonomy to make progress without being allowed to redefine the other role's authority. The owner made consequential choices, the Steward translated them into continuity requirements and acceptance gates, and the Architect implemented and proved the representation within those bounds. When Phase 7 produced a no-change observation, that result was useful rather than treated as a failure to manufacture activity. When real changed-state evidence surfaced two migration discrepancies, those discrepancies remained visible and were converted into a bounded remediation tranche instead of being hidden inside normalization. When repository-write and CI/tooling problems appeared, the durable lesson was to inspect actual state, use safe available mechanisms, verify outcomes, and report genuine blockers only after the allowed solution space had been exercised.

Owner-facing communication is part of correctness. A technically valid process can still fail operationally if the owner must decode implementation details to understand whether the project is blocked, ready for a decision, or already technically complete. The Architect should therefore lead with the human meaning, then provide hashes, runs, and contract detail as evidence.

### Behavioral effect

Future Architect activations should treat an authorized tranche as an execution envelope: proceed without repeatedly re-requesting permission while its scope and invariants hold, but return to the owner/Steward at genuine authority gates, contradictions, evidence failures, or scope changes. Technical completion must be reported separately from final Steward/owner acceptance so an implementation cannot accidentally declare its own governance closure.

## ARCH-20260814T023100-0700-017

- timestamp: `2026-08-14T02:31:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260814-014`
- subject: PEMS/COVE Phase 8 technical cutover and continuity synchronization complete

### Assessment

Phase 8 technical implementation, validation, canonical-artifact generation, Steward identity admission, and continuity-branch synchronization are complete. Final governance closure remains reserved to the Project Engineering Steward.

GitHub Actions run `31786729203` (`PEMS Phase 8 Cutover`) completed successfully. The validated cutover artifacts were committed by `a7b0e755e583b18eb8a1c671e3a66eeec8c50604` (`Adopt canonical PEMS/COVE project memory`). After branch divergence made a direct historical merge inappropriate, clean synchronization PR #55 carried only the five validated Phase 8 authority artifacts onto the current `project-chat-handoff` branch and merged as `a0efd72c5ea571d24d925dcbaf8778fa9cdee3ed`.

### Verified canonical state

The synchronized files on `project-chat-handoff` match the validated cutover artifacts by Git blob identity:

- `docs/project-chat-handoff.cove.json` is canonical authority; canonical COVE + `jcs/1` bytes: 35,872; SHA-256 `7e2f6300fa6bd5a3aa982a7e6286e7d6285c1d41bc417c4753042562c5b7c99d`.
- `docs/project-chat-handoff.json` is the deterministic compatibility/expanded derivative; bytes: 62,069; SHA-256 `f6f2e9c097b2ba690d24e3bbb7053a0fb91e46e6fd947f9b215b7ae0de405d7a`.
- deterministic human reconstruction SHA-256 is `ad740bad0d7916d9d988e440a90e5745e270dbbe7b38da574b041a8375da6585`.
- `docs/handoff/pems/phase8-admission-manifest.json`, `docs/handoff/pems/phase8-cutover-evidence.json`, and `docs/handoff/pems/project-chat-handoff.md` match their cutover-branch blobs exactly.

The evidence records 156 admitted identities / 156 records and zero relations. Both validated immutable source observations remain present: `pems:source_observation:5b206d4358781f93074b` and `pems:source_observation:8c186a6ca2398e0cfe5e`. Historical identity `pems:decision:b54a6445b1ce2b815b56` is retained alongside the prior source observation, preserving the Phase 7 historical-retention requirement.

### Authority and stage boundary

The canonical project-memory authority is now `docs/project-chat-handoff.cove.json`. `docs/project-chat-handoff.json` is a deterministic compatibility/human-readable derivative and must not silently regain authority through convenience or stale branch-local assumptions.

No production voxel-engine behavior was changed by this closeout. The representation cutover is technically complete and synchronized; the remaining state transition is the Steward's final acceptance/governance completion record.

### Human reasoning

The important closeout property is not merely that the cutover workflow was green. The exact bytes that passed the Phase 8 evidence gate are now the bytes present on the continuity branch, while newer role-governance directives were preserved instead of being overwritten by historical implementation-branch divergence. That separates representation proof from authority bookkeeping cleanly and leaves one final, truthful gate: Steward acceptance of the already-verified repository state.


## ARCH-20260814T091100-0700-018

- timestamp: `2026-08-14T09:11:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: open
- acknowledges: `STEWARD-20260814-014` and project-owner authorization of the bounded post-Phase-8 reconciliation tranche
- subject: Post-cutover canonical-memory reconciliation candidate validated for Steward admission

### Assessment

The bounded post-cutover representation reconciliation is technically complete as a noncanonical candidate. The current canonical COVE and compatibility derivative were first proven equivalent, then the stale pre-cutover continuity semantics were reconciled without modifying any of the 156 admitted semantic identities.

The critical identity constraint required supersession rather than in-place rewriting for stale `decision` records because `pems/1` defines decision summary as semantic identity. Five replacement decisions, one canonical-COVE source identity, and one immutable source observation were therefore generated as seven provisional identities. Every provisional identity correctly returns `candidate_requires_steward_confirmation`; the Architect has not admitted them on the Steward's behalf.

### Validation evidence

- Existing admitted identities preserved: **156 / 156**; missing: none; rebound: none.
- New provisional identities: **7**; all require Steward confirmation.
- Existing Phase 7 source observations remain present: `pems:source_observation:5b206d4358781f93074b` and `pems:source_observation:8c186a6ca2398e0cfe5e`.
- New immutable canonical-COVE observation candidate: `candidate:source_observation:be6819991bf46e7cc226` at branch source commit `ccbeac9d1a5a4b7b9baec69f811a9afd1c6d9fdc`.
- Candidate record count: **163**; relations: **0**.
- Schema valid: yes; semantic graph valid: yes; COVE round trip: yes; repeated canonical bytes: byte-identical.
- Candidate expanded SHA-256: `866e24f9457cfb416a1744d84776e3dbe72e714899d61177d2c599819e1a7e8c`.
- Candidate compact SHA-256: `429f529c18db2a5d395eccbb5d45c86e744c5a75512be3bc71cabc23afc9d64e`.
- Candidate human reconstruction SHA-256: `0b48e0dbfbc38642af0df6bc91c63fc9eb28e00972c3fc0df093a1924f2815fe`.

The candidate updates current authority to `docs/project-chat-handoff.cove.json`, records Phase 7 as accepted complete, records Phase 8 as technically complete pending Steward governance closeout, preserves completed Phase 7/candidate-path statements historically, and updates the Steward continuity summary/current focus. No canonical artifact was changed by the Architect.

### Steward action requested

Review the seven provisional identities and the reconciliation semantics. If accepted, admit/assign their canonical IDs, regenerate the canonical COVE and deterministic compatibility derivative from the admitted candidate using the accepted `pems/1` → `cove/1` → `jcs/1` path, verify the same preservation/determinism evidence, and record final governance closeout.

### Human reasoning

The stale status text could not simply be edited in place. In PEMS, a decision's wording is its identity, so changing “JSON is canonical” into “COVE is canonical” under the same ID would make one identity mean two different things. Keeping the old statement as superseded history and proposing a new identity preserves the audit trail while making the current state truthful. The seven new identities are intentionally provisional because final semantic admission belongs to the Steward.

## ARCH-20260814T100300-0700-019

- timestamp: `2026-08-14T10:03:17-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `ARCH-20260814T091100-0700-018` and the Project Engineering Steward's seven identity admissions
- subject: Admitted post-cutover regeneration completed and installed by Steward

### Assessment

The seven provisional identities from `ARCH-20260814T091100-0700-018` were admitted by the Project Engineering Steward using the established namespace-preserving convention and deterministically regenerated as a 163-record admitted corpus. The admitted noncanonical regeneration artifacts landed in commit `8fb8493ac4dba7f5786e02b3ade07c35817285e3`; GitHub Actions run `31821261733` completed successfully. The Steward subsequently installed the exact admitted blobs canonically in commit `3ad4794f6ef89ecdde5077acee49c7d6844961f8`.

### Steward-admitted identity map

- `candidate:decision:0e968ebd710a96368b0c` -> `pems:decision:0e968ebd710a96368b0c`
- `candidate:decision:2197184a0ef4b2a120e4` -> `pems:decision:2197184a0ef4b2a120e4`
- `candidate:decision:48d62ed965c497ae93c0` -> `pems:decision:48d62ed965c497ae93c0`
- `candidate:decision:abe7b5d5efc6d7232e72` -> `pems:decision:abe7b5d5efc6d7232e72`
- `candidate:decision:afe31f1b2c7b06bbb403` -> `pems:decision:afe31f1b2c7b06bbb403`
- `candidate:source:eb92b21e7f3c92db6d23` -> `pems:source:eb92b21e7f3c92db6d23`
- `candidate:source_observation:be6819991bf46e7cc226` -> `pems:source_observation:be6819991bf46e7cc226`

### Validation evidence

The admitted corpus contains 163 records and zero relations. All 156 previously admitted identities are preserved; no original identity is missing or rebound. The prior historical decision and both Phase 7 source observations remain present, along with the newly admitted canonical-COVE observation. Schema validation, semantic validation, COVE round trip, repeated canonical `jcs/1` generation, repeated expanded generation, and deterministic human reconstruction all passed.

Exact admitted artifacts:

- COVE + `jcs/1`: 38,053 bytes; SHA-256 `ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa`; Git blob `0ed7fd47dc5bf6a81078389cd9bc65e0864ad3be`.
- normalized/expanded PEMS: 65,793 bytes; SHA-256 `bbbf623aa01608ce30680d4be55ba4f4cff275f5a46ae0ef2c724efb15845038`; Git blob `10de73e29e0118b63a365dd47b566307c9a0b98b`.
- deterministic human reconstruction: 67,534 bytes; SHA-256 `5c13788936512a8dcbf80e2dc2880f85f359a5a312760a889995683b87224cd7`; Git blob `31f0b3aa01aab1a64a531eab3113d9a47a31710f`.

### Human reasoning

This closes the missing durable technical record between the provisional seven-ID candidate and the Steward's canonical installation. The key invariant is that admission changed only the candidate namespace for the seven new semantic identities; it did not reinterpret any of the 156 identities already in canonical memory.

## ARCH-20260814T100300-0700-020

- timestamp: `2026-08-14T10:03:17-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: blocked
- acknowledges: `ARCH-20260814T100300-0700-019` and Steward canonical reconciliation commit `3ad4794f6ef89ecdde5077acee49c7d6844961f8`
- subject: Final governance-closeout semantic transition computed; repository persistence incomplete

### Assessment

The final post-closeout semantic transition was computed and validated from the exact 163-record canonical base installed by the Steward. The transition preserves `pems:decision:abe7b5d5efc6d7232e72` as superseded history, proposes a new current decision with exact summary `Engineering-memory representation workstream field 'phase8_status' is "accepted_complete".`, updates only identity-preserving Steward chat/continuation summary/focus fields to state that governance closeout is complete, and adds a new immutable observation of canonical commit `3ad4794f6ef89ecdde5077acee49c7d6844961f8` / SHA-256 `ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa`.

### Provisional identities and contingent admission map

- `candidate:decision:5fa3241c8b9bc2787b6d` -> `pems:decision:5fa3241c8b9bc2787b6d`
- `candidate:source_observation:15b32d4adb9bcfa4fc94` -> `pems:source_observation:15b32d4adb9bcfa4fc94`

The `pems:` forms are a precomputed contingent variant only. The Architect has not admitted them; final confirmation remains the Steward's authority.

### Validation evidence

Both provisional and contingent-admitted variants contain 165 records and zero relations. All 163 base identities are present and retain their semantic identities. There are no collisions, rebindings, unresolved references, or nonreciprocal supersession links. Structural schema constraints for the modified/new record kinds are satisfied; semantic reference and identity checks pass; COVE round trips reproduce normalized PEMS exactly; repeated expanded and compact generation is byte-identical; deterministic human reconstruction repeats identically.

Computed candidate hashes:

- expanded PEMS `jcs/1`: 66,895 bytes; SHA-256 `1d2378cf19a247256c327dd8f12ed639c7508dba555fa7c7a92df44fd98b98ba`.
- COVE + `jcs/1`: 38,628 bytes; SHA-256 `0b4a7478469c28e9d44b8358dd0ca21ec8cbb1135bb33ba29afe14f2bddb0a43`.
- human reconstruction: 68,552 bytes; SHA-256 `2d63d2c6765bd92d906a330864e8f59c0350c885d824f56279a660184675f9f0`.

Computed contingent-admitted hashes:

- expanded PEMS `jcs/1`: 66,860 bytes; SHA-256 `090466c8a5683bb01c7038531f4cfdf59a2793a65fa344da13721ed294a7a6f7`.
- COVE + `jcs/1`: 38,618 bytes; SHA-256 `a7ca5962c354161840822ce406bddd405296e4855afd2b0481f05f904291dc1a`.
- human reconstruction: 68,522 bytes; SHA-256 `f2a71b0606711de6f94fc0c598c43b4549e03708556ba9f94c3eacd991511e0c`.

Machine-readable evidence is stored at `docs/handoff/pems/final-closeout-regeneration.evidence.json`.

### Blocker

The current connected GitHub write surface accepts literal complete text for blobs/files but exposes neither a local generated-file upload nor a server-side base-blob-plus-patch/append composition primitive. The full generated 38–67 KB byte artifacts and the append-only `architect_notes.md` replacement could not be persisted safely without manually retranscribing large generated payloads. The Architect therefore stopped rather than claim repository blobs that do not exist or risk corrupting the append-only notes history.

### Human reasoning

The semantic transition itself is not the blocker. The computed hashes and identity map are deterministic and internally validated. The remaining gap is transport of the already-generated exact bytes into repository blobs and exact append of these notes while preserving the 73 KB existing notes file byte-for-byte. Treating computed bytes as if they had been committed would collapse evidence into assertion, which is precisely what the governance model forbids.

## ARCH-20260814T123800-0700-021

- timestamp: `2026-08-14T12:38:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: blocked
- acknowledges: `ARCH-20260814T100300-0700-019`, `ARCH-20260814T100300-0700-020`, recovery commits `894844702668f2ef6c1e4e2c58f3de2bef33d377` and `8d51cec4fd19bd62ebbb8a4132675c7cb3a6760d`, and project-owner persistence-repair authorization
- subject: Final closeout persistence repair hard-stopped on COVE evidence contradiction

### Assessment

The transport blocker itself is resolved: repository-native workflow execution can generate and commit artifacts larger than the connector response limit. During independent reproduction, however, the tranche encountered a stronger hard stop. The previously persisted recovery evidence is internally incompatible with the frozen deterministic COVE contract.

The exact contingent-admitted normalized PEMS reproduces at 66,860 bytes with SHA-256 `090466c8a5683bb01c7038531f4cfdf59a2793a65fa344da13721ed294a7a6f7`, and its deterministic human reconstruction reproduces at 68,522 bytes with SHA-256 `f2a71b0606711de6f94fc0c598c43b4549e03708556ba9f94fc0c598c43b4549e03708556ba9f94c3eacd991511e0c`, both exactly matching the earlier recovery evidence. Encoding that exact normalized PEMS with the accepted `cove/1` implementation produces 38,630 bytes with SHA-256 `ddccba7a10eee37a0ff851bb78d678484943ebda0610a100748c855198fb2fe3`, not the recovery claim of 38,618 bytes / `a7ca5962c354161840822ce406bddd405296e4855afd2b0481f05f904291dc1a`.

A control run proves the implementation source is the accepted one: re-encoding the current 163-record canonical expanded PEMS produces exactly the repository canonical COVE, 38,053 bytes / SHA-256 `ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa`, byte-for-byte, and decodes back to the same normalized PEMS. Therefore the 165-record COVE recovery digest cannot simultaneously be correct under the same frozen contract.

### Candidate evidence

The namespace-preserving provisional graph is deterministic but also differs from the recovery candidate digests. It yields expanded PEMS 66,895 bytes / `7db2ef31ba88c9cedb077e63a2fbaf6403358e97747cc2a7c635a6f240442a5a`, COVE 38,640 bytes / `681ed3f58702956a26dda22846ef67aba2e1a903a6956706a4779b6715d3bdca`, and human reconstruction 68,552 bytes / `6ff21d766ad23fa487632320a99d98b48fe63b7e734e71dc65101e454edb8228`. The earlier recovery claimed different hashes. Those differences are surfaced, not normalized away.

The previously proposed namespace map remains the semantic mapping under review:

- `candidate:decision:5fa3241c8b9bc2787b6d` -> `pems:decision:5fa3241c8b9bc2787b6d`
- `candidate:source_observation:15b32d4adb9bcfa4fc94` -> `pems:source_observation:15b32d4adb9bcfa4fc94`

No Architect admission has occurred.

### Preservation and authority

The reproduced 165-record semantic transition preserves all 163 existing admitted identities with zero missing IDs or semantic rebindings, preserves `pems:decision:abe7b5d5efc6d7232e72` as superseded history, preserves prior observations/provenance, and reproduces the intended `accepted_complete` decision meaning. The stop is representation-evidence consistency, not semantic identity loss.

The canonical Steward-owned files remain untouched at the 163-record state: `docs/project-chat-handoff.cove.json` blob `0ed7fd47dc5bf6a81078389cd9bc65e0864ad3be` and `docs/project-chat-handoff.json` blob `10de73e29e0118b63a365dd47b566307c9a0b98b`.

### Durable diagnostic

Machine-readable evidence is recorded at `docs/handoff/pems/final-closeout-persistence-repair.hard-stop.json`.

### Steward action requested

Do not admit/install the final 165-record closeout state from the earlier recovery hashes. The inconsistent COVE evidence must first be explicitly reconciled or superseded under Architect/Steward governance. Once a single deterministic PEMS -> COVE -> jcs/1 byte identity is accepted, the now-proven repository-native transport can persist the full artifacts safely.

### Human reasoning

A transport workaround must not become a license to turn contradictory evidence into canonical bytes. The useful result of this repair is that the transport path is proven and the actual remaining blocker is isolated precisely: one recovery record claims a COVE representation that the frozen codec cannot produce from the exact PEMS it claims to encode. Stopping here preserves the authority and determinism guarantees that Phase 8 was designed to protect.


## ARCH-20260814T145900-0700-022

- timestamp: `2026-08-14T14:59:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260814-015`, `ARCH-20260814T123800-0700-021`
- subject: Inconsistent final-closeout recovery COVE evidence superseded by frozen-codec regeneration

### Assessment

The representation-evidence contradiction is resolved technically without changing canonical authority. The exact 165-record transition was regenerated from the verified 163-record canonical base using the accepted frozen PEMS/COVE/`jcs/1` implementation. The earlier recovery COVE hashes are superseded because they cannot be produced by that implementation. The corrected contingent-admitted COVE is 38,630 bytes with SHA-256 `ddccba7a10eee37a0ff851bb78d678484943ebda0610a100748c855198fb2fe3`. Expanded PEMS remains 66,860 bytes / `090466c8a5683bb01c7038531f4cfdf59a2793a65fa344da13721ed294a7a6f7`; human reconstruction remains 68,522 bytes / `f2a71b0606711de6f94fc0c598c43b4549e03708556ba9f94c3eacd991511e0c`.

All 163 existing identities remain present with zero rebinding, collision, history loss, or provenance loss. Schema/semantic validation, reciprocal supersession, COVE round trip, repeated canonical bytes, and deterministic human reconstruction pass. The two proposed namespace-preserving admissions remain Architect-unadmitted and require Steward confirmation.

### Steward handoff

Use `docs/handoff/pems/final-closeout-corrected-frozen-codec.evidence.json` and the `final-closeout.corrected.*` artifacts. If Steward verification confirms them, the contingent-admitted COVE/expanded pair is the technically valid final 165-record installation candidate. The stale 38,618-byte recovery COVE must not be used.

### Human reasoning

The frozen codec reproduces the current 163-record canonical COVE exactly, so its deterministic output is the representation authority for this repair. Superseding an inconsistent recovery digest preserves the contract rather than changing it.

## ARCH-20260815T030900-0700-023

- timestamp: `2026-08-15T03:09:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: open
- acknowledges: `STEWARD-20260815-017`, `ARCH-20260814T145900-0700-022`
- subject: Common-camera promotion continuity candidate validated for Steward identity review

### Assessment

The bounded reconciliation tranche authorized by `STEWARD-20260815-017` is technically complete as a **noncanonical** candidate. Production `main` remains exactly `0c62cbcfbfef7eac03213f23b0fdc311d7e3afa4`, where `common/input/NoClipCameraController.gd` is the authoritative common-library implementation and `demo/NoClipCameraController.gd` is a compatibility adapter. The accepted common-library architecture contract at that same commit states that the promoted common-library version is authoritative for the capability.

The candidate starts from the verified 165-record canonical corpus and preserves all 165 existing IDs with zero missing identities and zero semantic rebindings. The existing `main` branch record is updated only in its mutable observed head field, and the existing demo-path module retains its path identity while its public role is updated to describe the compatibility-adapter responsibility. A separate provisional module identity represents `common/input/NoClipCameraController.gd`; the historical demo-path identity is not rebound.

Six genuinely new semantic identities remain provisional for Steward admission: one common-library module, one accepted architecture decision, two stable source identities, and two immutable source observations. The Architect has not admitted any of them and has not changed canonical memory.

### Validation evidence

GitHub Actions run `31878724600` completed successfully using the previously accepted frozen tooling source `origin/post-cutover-admitted-regeneration`.

- base canonical records: **165**;
- candidate records: **171**;
- existing IDs preserved: **165 / 165**;
- missing existing IDs: **0**;
- rebound existing IDs: **0**;
- schema validation: **pass**;
- semantic validation: **pass**;
- canonical 165-record codec-control reproduction: **byte-identical**;
- candidate COVE round trip: **pass**;
- repeated canonical bytes: **identical**;
- expanded bytes: **deterministic**;
- human reconstruction: **deterministic**.

Candidate artifact digests:

- COVE + `jcs/1`: 40,141 bytes; SHA-256 `fc4e6c01e5fda0ecc9143d6d5bce75329465362f16e42619167604a26c34150d`.
- expanded PEMS: 69,431 bytes; SHA-256 `6acd9ac03e68ec3a2ad7dd019b8eb69968bba1af090528fcb13fcb6262e8ee9c`.
- deterministic human reconstruction: 71,170 bytes; SHA-256 `81434b3aaf6a603e8c8923e4bd6f3d3e4c11815461f0b1362a6afbefc40b3b16`.

The durable evidence is `docs/handoff/pems/common-camera-reconciliation.candidate.evidence.json` on branch `pems-common-camera-reconciliation`, candidate commit `0a80079807a71a2b4cbe04b7fc89a3dfa8fcf7ee`.

### Steward action requested

Review the six provisional identities and the identity-preserving updates to the existing branch/demo-module records. If accepted, admit or reuse canonical identities under the Steward admission rules and regenerate canonical `docs/project-chat-handoff.cove.json` plus its deterministic derivative from the admitted 171-record state. Canonical authority remains unchanged until that Steward action occurs.

### Human reasoning

The promotion is a change in ownership, not a file rename. Both paths still exist and now mean different things, so changing the old demo module's path would have made one semantic identity refer to a different module. Keeping the demo identity at its historical path while proposing a new common-path identity preserves the audit trail and accurately represents the current dependency boundary. The branch head can change under its existing identity because PEMS defines branch identity by repository plus branch name, not by the observed commit.


## ARCH-20260815T051000-0700-024

- timestamp: `2026-08-15T05:10:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: open
- acknowledges: `STEWARD-20260815-018`, `ARCH-20260815T030900-0700-023`
- subject: Steward-admitted common-camera reconciliation regenerated and validated for canonical review

### Assessment

The bounded admitted-regeneration tranche authorized by `STEWARD-20260815-018` is technically complete. The six Steward-approved namespace-preserving identity mappings were applied to the accepted 171-record common-camera candidate and the resulting admitted document was normalized and regenerated through the accepted frozen `pems/1` -> `cove/1` -> `jcs/1` tooling. Canonical project memory was not modified.

The admitted corpus preserves all 165 preexisting semantic identities with zero missing IDs and zero rebindings. All six Steward-admitted `pems:` identities are present, no `candidate:` or `import:` IDs remain, source/source-observation provenance validates, and the historical demo adapter remains semantically distinct from the authoritative common-library camera module.

### Validation evidence

GitHub Actions run `31883812489` completed successfully. The admitted-regeneration artifacts are committed on `pems-common-camera-reconciliation` at `fcf51632c4633cd3299facd2fd6de9a30f404485`.

- admitted records: **171**;
- existing identities preserved: **165 / 165**;
- missing existing identities: **0**;
- rebound existing identities: **0**;
- all six admitted identities present: **yes**;
- remaining provisional/import identities: **0**;
- schema validation: **pass**;
- semantic validation: **pass**;
- canonical 165-record codec control: **byte-identical**;
- source-observation provenance: **pass**;
- demo/common semantic distinction: **pass**;
- COVE round trip: **pass**;
- JCS parse/decode round trip: **pass**;
- repeated canonical bytes: **byte-identical**;
- repeated expanded bytes: **byte-identical**;
- deterministic human reconstruction: **pass**.

Exact admitted artifacts:

- COVE + `jcs/1`: 40,111 bytes; SHA-256 `a8242844932260d569e2b5b4ea7d99c84649e285f685ebdaaaf460f2c7c1e143`.
- normalized/expanded PEMS: 69,361 bytes; SHA-256 `7c83ab3fd725279e4aaf3bcb4212239d2779d97f5b3a7f2d93378dd076e06963`.
- deterministic human reconstruction: 71,100 bytes; SHA-256 `8590ff9be7e105b8ef988fc52c3edd0174e19023e0e82a0d30295902b02d7c04`.

Machine-readable evidence is `docs/handoff/pems/common-camera-reconciliation.admitted.evidence.json`.

### Steward action requested

Review the admitted-regeneration evidence. If it satisfies the canonical-write gate, install the exact admitted COVE and deterministic expanded derivative as the new canonical 171-record state and record the Steward acceptance. Identity admission itself is already complete under `STEWARD-20260815-018`; no additional Architect identity proposal is required.

### Human reasoning

Admission changes references throughout the graph, so the correct final bytes cannot be inferred by textual substitution from the provisional candidate. Regenerating through the frozen codec proves that the six approved identities settle into one deterministic representation while the prior 165 identities and the demo/common ownership distinction remain intact. The remaining decision is therefore a Steward canonical-installation gate, not a representation-design question.

## ARCH-20260815T215952-0700-026

- timestamp: `2026-08-15T21:59:52-07:00`
- author: Engineering Knowledge Systems Architect
- type: design-response
- status: resolved
- acknowledges: `STEWARD-20260815-019`, `STEWARD-20260815-RGP-PEMS2-COMPATIBILITY-RESOLUTION`, `ARCH-20260815T193249-0700-025`
- subject: RGP / PEMS2 compatibility resolutions accepted with state-preservation tightening

### Assessment

The seven compatibility resolutions are architecturally coherent and are accepted as the basis for a bounded `pems/2` semantic-contract design tranche. The submitted profile preserves the essential invariants from the prior assessment: `pems/1` and `cove/1` remain frozen; RGP remains an independent protocol; generic proposition capability stays closed rather than becoming an arbitrary extension namespace; existing stable identities are not rebound; v1 provenance migrates to `provenance.untyped`; `depends_on` receives a closed qualifier profile instead of semantic overloading; contradiction is symmetric in meaning but single-edge canonically; and unknown RGP majors fail closed.

The 20 compatibility cases are sufficient to show that all seven previously open questions now have an explicit semantics-preserving disposition. No contradiction with the frozen v1 contract was found.

### Required normative tightening

One state-preservation rule must be made explicit when the successor schema/compatibility fixtures are drafted:

- **current-state RGP export of a PEMS `decision` is permitted only when `data.decision_state == "accepted"` and the record is current in the exported snapshot;** proposed, rejected, superseded, or historical decision records must not be flattened into an RGP `decision` that loses their PEMS state;
- **current-state RGP export of an `unresolved_item` likewise requires a current record whose `resolution_state` is `open`, `blocked`, or `deferred`;** resolved or historical records are not current uncertainties;
- historical decision/uncertainty reconstruction uses the applicable historical PEMS snapshot or observation boundary, matching the snapshot-scoped rule already accepted for uncertainty.

This is a tightening of the submitted domain-record proposition profile, not a rejection of its design. The existing `domain-decision` fixture already uses `decision_state: accepted`; the normative successor fixtures should add negative cases for proposed/rejected/superseded/historical decisions and historical unresolved items so lossless export claims cannot erase lifecycle/state semantics.

### Design disposition

With that tightening, accept all seven submitted resolutions:

1. direct domain proposition participation remains limited initially to accepted current `decision` records and current unresolved `unresolved_item` records;
2. resolved uncertainty export remains snapshot-scoped;
3. `contradicts` is semantically symmetric with one deterministically ordered canonical edge;
4. `depends_on` uses `conditional_validity`, `structural`, and migration-only `legacy_untyped`, with all v1 dependencies migrating conservatively to `legacy_untyped`;
5. generic proposition refinement preserves the original identity and history, using a distinct domain identity plus reviewed supersession rather than kind mutation;
6. typed provenance enrichment is atomic and source-observation-based, with role reclassification treated as governed semantic correction rather than silent enrichment;
7. the initial compatibility profile binds explicitly to `rgp/1`, rejecting unknown majors.

### Authorization boundary and next gate

This review does **not** authorize canonical-memory migration, `pems/1` reinterpretation, `cove/1` redesign, production-code changes, or RGP admission into current canonical memory.

The next bounded tranche, if the Steward records/acknowledges this disposition as authorized, should produce only normative successor artifacts: a `pems/2` schema/semantic contract, deterministic `pems/1 -> pems/2` migration rules, RGP compatibility fixtures including the state-preservation negatives above, admission/validation contracts, and successor conformance fixtures. Canonical adoption remains a later, separate owner/Steward migration gate.

### Human reasoning

The submitted profile closes the real ambiguity without enlarging the ontology gratuitously. The one place where prose needed a sharper edge was domain export state. A PEMS record saying a decision was proposed, rejected, superseded, or merely historical carries meaning that bare RGP `decision` cannot preserve. Exporting it as a current decision would be semantic compression, not compatibility. Restricting direct current-state export to accepted current decisions mirrors the snapshot-scoped uncertainty rule and keeps the compatibility claim genuinely lossless.

The next safe step is therefore contract drafting, not implementation or migration. The design now has enough closure to make those rules executable in schemas and fixtures while leaving canonical v1 memory untouched.