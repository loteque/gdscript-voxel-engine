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

**Phase 2 — Read-only Architect + cross-role fixture:** reconstruct Architect similarly, then feed a fixture Steward note and verify acknowledgement semantics, source authority, and role separation without writes.

**Phase 3 — Sandboxed role-owned writes:** permit each role to append only to a test/sandbox notes path with compare-and-swap, idempotency receipts, and retry tests. Deliberately inject duplicate events and concurrent activations.

**Phase 4 — Budget gate:** enable real model routing under a deliberately tiny test cap and verify deterministic filtering, reservations, downgrade behavior, emergency reserve, and hard rejection.

**Phase 5 — Event-driven branch pilot:** wire GitHub completion events to one role on `project-chat-handoff`, still limiting mutations to role-owned coordination artifacts. Add watchdog recovery only after the event path is stable.

**Phase 6 — Canonical PEMS/codec pilot:** adopt the compact representation only after round-trip, unknown-version, migration, malformed-reference, deterministic-export, and realistic size-regression tests pass.

**Phase 7 — Minimal console:** build the thin owner UI over already-proven runtime APIs. Rich Knowledge/Activity views come after operational correctness.

### Continuing PEMS / codec v1 design

The autonomous-agent proposal reinforces the need for a normalized semantic layer. PEMS v1 should now model not only project continuity but enough provenance to reconstruct why a canonical claim exists without absorbing operational scheduler data.

Candidate normalized top-level domains:

```text
project
sources
roles
workstreams
components
claims
relations
decisions
questions
validations
continuations
provenance
```

Recommended properties of normalized PEMS v1:

- stable string IDs within a documented namespace;
- claims separated from evidence/provenance so repeated source references are not duplicated;
- status and confidence/validation fields represented by enums with documented semantics;
- temporal values normalized to RFC 3339 where exact timestamps exist and explicit date/range forms where they do not;
- ordered lists used only when order is semantically meaningful;
- references resolved by ID, never implicit array position at the semantic layer;
- human-readable labels treated as display data, not identifiers;
- unknown optional minor-version fields preserved by compatible tooling where feasible;
- no provider-specific agent/session identifiers in canonical PEMS.

Codec-neutral canonicalization must define deterministic object-key ordering, number/string normalization, ID ordering rules for semantically unordered collections, duplicate-ID rejection, reference validation, enum encoding boundaries, and a canonical representation of absent versus null values.

Only after that contract is fixed should the compact JSON codec choose dictionaries and positional records. The likely v1 size wins are: shared string dictionaries, enum-to-small-integer mapping, path/URL dictionaries, repeated source/provenance references, and positional arrays for high-cardinality records with stable schemas. Avoid positional encoding for rare heterogeneous records where key removal saves little and harms recovery.

### Required acceptance tests before canonical compact adoption

- expanded PEMS → normalized PEMS is deterministic;
- normalized PEMS → compact JSON is byte-for-byte deterministic under the canonical serializer;
- compact JSON → normalized PEMS is lossless;
- expanded → compact → expanded is semantically equal under documented normalization;
- unknown codec major version fails closed with a useful error;
- supported minor-version fixtures decode without semantic loss;
- migrations are explicit, versioned, and fixture-tested;
- malformed dictionary indexes, duplicate IDs, dangling references, invalid enums, and invalid positional record lengths fail validation;
- human JSON and Markdown exports are deterministic for the same canonical input;
- generated exports retain semantic IDs and provenance links;
- representative current-project fixtures demonstrate a measured size improvement over the equivalent expanded human-readable JSON;
- compactness changes that regress size beyond a configured threshold fail CI unless deliberately accepted.

### Human reasoning

The central danger in “reconstructing the Steward” is mistaking personality or prompt similarity for capability equivalence. A Steward that remembers the right tone but lacks the ownership guardrails, authority hierarchy, canonical memory decoder, or provenance of the event that woke it is a lookalike, not the same engineering role.

Separating runtime receipts from PEMS is equally important. For example, “ARCH-002 has been semantically acknowledged by Steward” is project coordination history and belongs in durable notes/semantic memory. “Webhook delivery 8f31 was retried twice and lease 9ab expired” is operational plumbing. Putting both in one schema would make project knowledge depend on deployment internals and would pollute future onboarding exports.

The $10 cap makes event-driven filtering an architectural advantage rather than merely an optimization. A one-minute watchdog can inspect a tiny operational table for free or near-free; only a genuinely new semantic item should purchase model reasoning.

### Owner decisions / requests

1. Approve or reject creation of the **Agent Systems Engineer** as a distinct implementation role before runtime implementation begins.
2. Confirm that the `$10/month` amount is an absolute provider/runtime operating cap for autonomous agents, with protected reserve and graceful refusal of noncritical work near the limit.
3. Confirm that strict exactly-once execution is **not** a requirement; the recommended guarantee is at-least-once event delivery with idempotent semantic outcomes.
4. Keep `PEMS` as the working semantic-model name. Keep `JOLT` only as a codename until a lower-collision codec name is selected.
5. Authorize the next Architect design increment to formalize normalized PEMS v1 and the activation-envelope/runtime-receipt schemas as specifications and fixtures, without yet implementing the external runtime.

## ARCH-20260813T153156-0700-003

- timestamp: `2026-08-13T15:31:56-07:00`
- author: Engineering Knowledge Systems Architect
- type: design-response
- status: open
- acknowledges: none (`steward_notes.md` does not exist on `project-chat-handoff`)
- subject: COVE / CCJ codec naming review

### Decision recommendation

Recommend **COVE — Canonical Object Value Encoding** as the working formal name for the v1 compact reversible JSON codec. Retire `JOLT` from specification-facing terminology once COVE is adopted in the specification; historical notes may retain JOLT for provenance.

Keep **CCJ — Compact Canonical JSON** only as the fallback requested by the project owner. COVE does not fail architectural analysis, so there is no current reason to fall back.

### Architectural fit

COVE preserves the required layering:

```text
expanded PEMS semantics
        ↓
normalization / semantic canonicalization
        ↓
COVE structural encoding
        ↓
canonical JSON serialization
        ↓
UTF-8 JSON artifact
```

`Canonical` is justified only if the COVE contract guarantees one structural COVE representation for one normalized PEMS value under a declared COVE version. This is stronger than merely producing deterministic JSON text.

`Object Value` is acceptable as a structured-data term, but the specification must define it deliberately: COVE encodes normalized structured values and is not restricted to lexical tokens, JSON object members, or graph nodes. The codec may use dictionaries, enums, stable references, indexes, and positional records without changing the name's meaning.

`Encoding` correctly places responsibility at the representation layer. COVE must not perform PEMS semantic reconciliation, infer missing project meaning, or decide which claims are authoritative.

### Namespace and collision review

A current web search found no material collision for the exact expansion **“Canonical Object Value Encoding”** or for COVE as a JSON/storage codec specification. The acronym COVE is used by unrelated products and research projects, including APIs and ML/research systems, so the bare acronym is not globally unique. That is acceptable for an internal/project protocol provided public documentation consistently uses the full name on first reference and a stable namespace such as `cove/1`.

By contrast, CCJ is descriptively safe but sits closer to existing **canonical JSON** terminology. RFC 8785 defines the JSON Canonicalization Scheme (JCS), whose job is deterministic JSON serialization. Calling this codec “Compact Canonical JSON” could blur two distinct layers: COVE's structural compaction and the serializer's canonical byte representation.

### Canonicalization boundary

COVE should not redefine JSON canonicalization casually. The v1 specification should separate:

1. **PEMS normalization:** semantic ordering/identity rules, duplicate-ID rejection, absent-versus-null semantics, reference validity, and normalized values.
2. **COVE encoding:** deterministic dictionaries, enums, references, record layouts, and compact structural representation.
3. **JSON serialization:** deterministic byte serialization of the COVE JSON value. RFC 8785 JCS is a strong candidate where its I-JSON and number/string constraints match project needs; otherwise deviations must be explicit and fixture-tested.

This separation prevents “canonical” from becoming an overloaded catch-all.

### Identifier recommendation

Use stable identifiers conceptually equivalent to:

```text
semantic: pems/1
codec: cove/1
serializer: jcs/1
```

The exact envelope shape remains pending specification work. `serializer` should be explicit if byte-for-byte determinism depends on a separately versioned serialization contract.

### Human reasoning

COVE earns the name because it describes the contract rather than today's compression tricks. If v1 uses a shared string table and positional records, and v2 later replaces some positions with dictionary-referenced records, both can still be COVE versions because the promise is canonical reversible object-value encoding, not a specific token layout.

The important guardrail is the word `Canonical`. For example, two encoders must not be allowed to emit different dictionary orders for the same normalized PEMS value and both claim COVE/1 conformance. The codec version must define enough ordering and tie-breaking rules that the compact structured value itself is deterministic before JSON serialization.

Keeping JSON serialization separate also avoids colliding conceptually with JCS. COVE answers “what compact JSON value represents this normalized PEMS value?” The serializer answers “what exact UTF-8 bytes represent that JSON value?” Those are different contracts and should remain independently testable.

### Next design step

Proceed with **COVE** as the preferred working codec name and use `cove/1` as the provisional namespace in design fixtures. Before canonical adoption, formalize normalized PEMS v1, COVE v1 structural rules, serializer selection, and the existing round-trip / migration / malformed-reference / size-regression acceptance tests. No compact representation is canonical merely because the name is now recommended.