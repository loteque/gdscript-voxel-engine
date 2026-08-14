from __future__ import annotations
import hashlib
import json
from pathlib import Path


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(f"blob {len(data)}\0".encode() + data).hexdigest()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

root=Path('.')
base_cove=(root/'docs/project-chat-handoff.cove.json').read_bytes()
base_expanded=(root/'docs/project-chat-handoff.json').read_bytes()
assert len(base_cove)==38053 and sha256(base_cove)=='ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa'
assert git_blob_sha(base_cove)=='0ed7fd47dc5bf6a81078389cd9bc65e0864ad3be'
assert len(base_expanded)==65793 and sha256(base_expanded)=='bbbf623aa01608ce30680d4be55ba4f4cff275f5a46ae0ef2c724efb15845038'
assert git_blob_sha(base_expanded)=='10de73e29e0118b63a365dd47b566307c9a0b98b'

record={
  'status':'hard_stop_representation_evidence_contradiction',
  'authority':{
    'canonical_authority_unchanged':'docs/project-chat-handoff.cove.json',
    'architect_admission_performed':False,
    'steward_ready_165_artifacts_persisted':False
  },
  'base_canonical':{
    'commit':'3ad4794f6ef89ecdde5077acee49c7d6844961f8',
    'record_count':163,
    'cove':{'bytes':38053,'sha256':'ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa','git_blob_sha':'0ed7fd47dc5bf6a81078389cd9bc65e0864ad3be'},
    'expanded':{'bytes':65793,'sha256':'bbbf623aa01608ce30680d4be55ba4f4cff275f5a46ae0ef2c724efb15845038','git_blob_sha':'10de73e29e0118b63a365dd47b566307c9a0b98b'}
  },
  'candidate_to_contingent_admitted_id_map':{
    'candidate:decision:5fa3241c8b9bc2787b6d':'pems:decision:5fa3241c8b9bc2787b6d',
    'candidate:source_observation:15b32d4adb9bcfa4fc94':'pems:source_observation:15b32d4adb9bcfa4fc94'
  },
  'reproduction':{
    'record_count_after':165,
    'existing_ids_preserved':163,
    'missing_existing_ids':[],
    'identity_rebindings':[],
    'contingent_admitted_expanded':{'bytes':66860,'sha256':'090466c8a5683bb01c7038531f4cfdf59a2793a65fa344da13721ed294a7a6f7','matches_recovery':True},
    'contingent_admitted_human':{'bytes':68522,'sha256':'f2a71b0606711de6f94fc0c598c43b4549e03708556ba9f94c3eacd991511e0c','matches_recovery':True},
    'contingent_admitted_cove_frozen_codec':{'bytes':38630,'sha256':'ddccba7a10eee37a0ff851bb78d678484943ebda0610a100748c855198fb2fe3'},
    'contingent_admitted_cove_recovery_claim':{'bytes':38618,'sha256':'a7ca5962c354161840822ce406bddd405296e4855afd2b0481f05f904291dc1a','matches_reproduction':False},
    'candidate_expanded_namespace_preserving':{'bytes':66895,'sha256':'7db2ef31ba88c9cedb077e63a2fbaf6403358e97747cc2a7c635a6f240442a5a'},
    'candidate_cove_frozen_codec':{'bytes':38640,'sha256':'681ed3f58702956a26dda22846ef67aba2e1a903a6956706a4779b6715d3bdca'},
    'candidate_human_namespace_preserving':{'bytes':68552,'sha256':'6ff21d766ad23fa487632320a99d98b48fe63b7e734e71dc65101e454edb8228'},
    'candidate_recovery_claim':{
      'expanded':{'bytes':66895,'sha256':'1d2378cf19a247256c327dd8f12ed639c7508dba555fa7c7a92df44fd98b98ba'},
      'cove':{'bytes':38628,'sha256':'0b4a7478469c28e9d44b8358dd0ca21ec8cbb1135bb33ba29afe14f2bddb0a43'},
      'human':{'bytes':68552,'sha256':'2d63d2c6765bd92d906a330864e8f59c0350c885d824f56279a660184675f9f0'},
      'matches_reproduction':False
    }
  },
  'codec_control':{
    'accepted_tooling_source':'post-cutover-admitted-regeneration/tools/cove/cove_v1.py + jcs_v1.py',
    'canonical_163_reencode_bytes':38053,
    'canonical_163_reencode_sha256':'ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa',
    'canonical_163_reencode_byte_equal_to_repository':True,
    'canonical_163_round_trip_equal':True,
    'verification_run':31834134158
  },
  'diagnostic_runs':{
    'initial_independent_reproduction':31833922912,
    'candidate_structure_search':31834003919,
    'candidate_and_contingent_measurement':31834079062,
    'canonical_codec_control':31834134158
  },
  'hard_stop_reason':'The recovery evidence claims COVE bytes that cannot be produced from the exactly reproduced normalized 165-record PEMS by the frozen cove/1 implementation. The same implementation reproduces the current 163-record canonical COVE byte-for-byte, so treating the recovery COVE digest as canonical-ready would violate deterministic representation authority.',
  'required_next_action':'Reconcile or supersede the inconsistent recovery COVE evidence under explicit Architect/Steward governance before final 165-record canonical admission/install.'
}
path=root/'docs/handoff/pems/final-closeout-persistence-repair.hard-stop.json'
path.write_text(json.dumps(record,indent=2,sort_keys=True)+'\n')

notes=root/'docs/handoff/architect_notes.md'
prior=notes.read_bytes()
assert git_blob_sha(prior)=='cc835535407a39f6a69e3d1accb2ed5a0ba1360e'
recovery=(root/'docs/handoff/pems/final-closeout-architect-notes-append.md').read_bytes()
marker=b'## ARCH-20260814T100300-0700-019'
assert marker not in prior
exact_append=recovery[recovery.index(marker):]
sep=b'' if prior.endswith(b'\n\n') else (b'\n' if prior.endswith(b'\n') else b'\n\n')
restored=prior+sep+exact_append
assert restored[:len(prior)]==prior
final_note=b'''\n## ARCH-20260814T123800-0700-021\n\n- timestamp: `2026-08-14T12:38:00-07:00`\n- author: Engineering Knowledge Systems Architect\n- type: handoff\n- status: blocked\n- acknowledges: `ARCH-20260814T100300-0700-019`, `ARCH-20260814T100300-0700-020`, recovery commits `894844702668f2ef6c1e4e2c58f3de2bef33d377` and `8d51cec4fd19bd62ebbb8a4132675c7cb3a6760d`, and project-owner persistence-repair authorization\n- subject: Final closeout persistence repair hard-stopped on COVE evidence contradiction\n\n### Assessment\n\nThe transport blocker itself is resolved: repository-native workflow execution can generate and commit artifacts larger than the connector response limit. During independent reproduction, however, the tranche encountered a stronger hard stop. The previously persisted recovery evidence is internally incompatible with the frozen deterministic COVE contract.\n\nThe exact contingent-admitted normalized PEMS reproduces at 66,860 bytes with SHA-256 `090466c8a5683bb01c7038531f4cfdf59a2793a65fa344da13721ed294a7a6f7`, and its deterministic human reconstruction reproduces at 68,522 bytes with SHA-256 `f2a71b0606711de6f94fc0c598c43b4549e03708556ba9f94c3eacd991511e0c`, both exactly matching the earlier recovery evidence. Encoding that exact normalized PEMS with the accepted `cove/1` implementation produces 38,630 bytes with SHA-256 `ddccba7a10eee37a0ff851bb78d678484943ebda0610a100748c855198fb2fe3`, not the recovery claim of 38,618 bytes / `a7ca5962c354161840822ce406bddd405296e4855afd2b0481f05f904291dc1a`.\n\nA control run proves the implementation source is the accepted one: re-encoding the current 163-record canonical expanded PEMS produces exactly the repository canonical COVE, 38,053 bytes / SHA-256 `ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa`, byte-for-byte, and decodes back to the same normalized PEMS. Therefore the 165-record COVE recovery digest cannot simultaneously be correct under the same frozen contract.\n\n### Candidate evidence\n\nThe namespace-preserving provisional graph is deterministic but also differs from the recovery candidate digests. It yields expanded PEMS 66,895 bytes / `7db2ef31ba88c9cedb077e63a2fbaf6403358e97747cc2a7c635a6f240442a5a`, COVE 38,640 bytes / `681ed3f58702956a26dda22846ef67aba2e1a903a6956706a4779b6715d3bdca`, and human reconstruction 68,552 bytes / `6ff21d766ad23fa487632320a99d98b48fe63b7e734e71dc65101e454edb8228`. The earlier recovery claimed different hashes. Those differences are surfaced, not normalized away.\n\nThe previously proposed namespace map remains the semantic mapping under review:\n\n- `candidate:decision:5fa3241c8b9bc2787b6d` -> `pems:decision:5fa3241c8b9bc2787b6d`\n- `candidate:source_observation:15b32d4adb9bcfa4fc94` -> `pems:source_observation:15b32d4adb9bcfa4fc94`\n\nNo Architect admission has occurred.\n\n### Preservation and authority\n\nThe reproduced 165-record semantic transition preserves all 163 existing admitted identities with zero missing IDs or semantic rebindings, preserves `pems:decision:abe7b5d5efc6d7232e72` as superseded history, preserves prior observations/provenance, and reproduces the intended `accepted_complete` decision meaning. The stop is representation-evidence consistency, not semantic identity loss.\n\nThe canonical Steward-owned files remain untouched at the 163-record state: `docs/project-chat-handoff.cove.json` blob `0ed7fd47dc5bf6a81078389cd9bc65e0864ad3be` and `docs/project-chat-handoff.json` blob `10de73e29e0118b63a365dd47b566307c9a0b98b`.\n\n### Durable diagnostic\n\nMachine-readable evidence is recorded at `docs/handoff/pems/final-closeout-persistence-repair.hard-stop.json`.\n\n### Steward action requested\n\nDo not admit/install the final 165-record closeout state from the earlier recovery hashes. The inconsistent COVE evidence must first be explicitly reconciled or superseded under Architect/Steward governance. Once a single deterministic PEMS -> COVE -> jcs/1 byte identity is accepted, the now-proven repository-native transport can persist the full artifacts safely.\n\n### Human reasoning\n\nA transport workaround must not become a license to turn contradictory evidence into canonical bytes. The useful result of this repair is that the transport path is proven and the actual remaining blocker is isolated precisely: one recovery record claims a COVE representation that the frozen codec cannot produce from the exact PEMS it claims to encode. Stopping here preserves the authority and determinism guarantees that Phase 8 was designed to protect.\n'''
final=restored.rstrip(b'\n')+b'\n'+final_note
notes.write_bytes(final)
assert final[:len(prior)]==prior
assert final.count(b'## ARCH-20260814T100300-0700-019')==1
assert final.count(b'## ARCH-20260814T100300-0700-020')==1
assert final.count(b'## ARCH-20260814T123800-0700-021')==1
assert (root/'docs/project-chat-handoff.cove.json').read_bytes()==base_cove
assert (root/'docs/project-chat-handoff.json').read_bytes()==base_expanded
print(json.dumps({'status':'hard_stop_record_ready','diagnostic_path':str(path),'diagnostic_blob':git_blob_sha(path.read_bytes()),'notes_blob_after':git_blob_sha(final)},indent=2))
