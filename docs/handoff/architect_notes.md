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

### Human reasoning

The expensive part of this system should be semantic judgment, not polling. Deterministic infrastructure can cheaply answer “is there new work?” while the role-bearing model answers “what does it mean?” This preserves both cost control and role integrity.

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

## ARCH-20260815T180300-0700-025

- timestamp: `2026-08-15T18:03:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: observation
- status: acknowledged
- acknowledges: `STEWARD-20260815-019`
- subject: Canonical memory remains aligned; Distiller observation/claim evaluation is experimental only

### Assessment

The Steward's common-camera canonical reconciliation in `STEWARD-20260815-019` is accepted as the current governance state. Production `main` remains `0c62cbcfbfef7eac03213f23b0fdc311d7e3afa4`, and the canonical 171-record project memory records that same head, so there is no current repository/canonical continuity drift to reconcile.

Since the prior Architect reconciliation, repository activity on `project-chat-handoff` is confined to the experimental Distiller workstream. The latest evaluation records 39/40 expected classifications across five same-session passes for the tightened `observation` versus `claim` distinction, with the only instability arising from wording that could mean either inspectable architecture state or a broader architectural interpretation. The experiment recommends retaining both kinds and shifting the next experimental pressure toward deterministic validation rather than adding another proposition kind.

This is useful experimental evidence, but it is not an authorized change to frozen `pems/1`, `cove/1`, `jcs/1`, canonical memory, or Steward admission policy. No representation change is therefore proposed or applied by this reconciliation.

### Human reasoning

The Distiller result reduces ontology uncertainty without creating a continuity requirement. Its strongest lesson is that empirical synthesis and evidentiary interpretation can be distinguished by what the proposition is about, while ambiguous wording should be made more atomic. Promoting that result into PEMS now would silently enlarge scope because the Distiller directive explicitly treats its vocabulary as experimental. The correct Architect action is to preserve the evidence and leave the frozen representation untouched until a governed representation tranche exists.

### Outcome

No identity collision or rebinding, semantic/history/provenance loss, nondeterminism, schema/contract contradiction, authority ambiguity, or unexplained evidence mismatch was found. No owner decision is required. No directive, schema, canonical-memory, Steward-owned, production, ADR, roadmap, demo, or test file changed in this reconciliation.
