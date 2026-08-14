from __future__ import annotations
import copy, hashlib, json, sys
from pathlib import Path
sys.path.insert(0, '/tmp/accepted-pems-cove')
from tools.cove.cove_v1 import decode, encode
from tools.cove.jcs_v1 import canonicalize, parse_canonical, serialize_cove
from tools.pems import normalize_document, semantic_identity, validate_schema, validate_semantics
from tools.pems.human_export import render_human_markdown

ROOT=Path('.')
BASE_EXPANDED=ROOT/'docs/project-chat-handoff.json'
BASE_COVE=ROOT/'docs/project-chat-handoff.cove.json'
SCHEMA=json.loads((ROOT/'docs/handoff/pems/pems-v1.schema.json').read_text())
OLD_PENDING='pems:decision:abe7b5d5efc6d7232e72'
CAND_DEC='candidate:decision:5fa3241c8b9bc2787b6d'; ADM_DEC='pems:decision:5fa3241c8b9bc2787b6d'
CAND_OBS='candidate:source_observation:15b32d4adb9bcfa4fc94'; ADM_OBS='pems:source_observation:15b32d4adb9bcfa4fc94'
OLD_SENTENCE='Phase 8 technical cutover is complete and final Steward governance closeout is pending.'
NEW_SENTENCE='Phase 8 technical cutover and final Steward governance closeout are complete.'
DECISION_SUMMARY='Engineering-memory representation workstream field \'phase8_status\' is "accepted_complete".'

def sha256(b): return hashlib.sha256(b).hexdigest()
def gitblob(b): return hashlib.sha1(f'blob {len(b)}\0'.encode()+b).hexdigest()
def meta(b): return {'bytes':len(b),'sha256':sha256(b),'git_blob_sha':gitblob(b)}

def base_doc():
    eb=BASE_EXPANDED.read_bytes(); cb=BASE_COVE.read_bytes()
    assert meta(eb)=={'bytes':65793,'sha256':'bbbf623aa01608ce30680d4be55ba4f4cff275f5a46ae0ef2c724efb15845038','git_blob_sha':'10de73e29e0118b63a365dd47b566307c9a0b98b'}
    assert meta(cb)=={'bytes':38053,'sha256':'ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa','git_blob_sha':'0ed7fd47dc5bf6a81078389cd9bc65e0864ad3be'}
    d=normalize_document(json.loads(eb)); assert len(d['records'])==163; assert validate_schema(d,schema=SCHEMA).valid; assert validate_semantics(d).valid
    control=serialize_cove(encode(d,profile='pems/1',serializer='jcs/1')); assert control==cb; assert decode(parse_canonical(control),supported_profiles={'pems/1'})==d
    return eb,cb,d

def build(base, admitted):
    d=copy.deepcopy(base); did=ADM_DEC if admitted else CAND_DEC; oid=ADM_OBS if admitted else CAND_OBS
    for r in d['records']:
        if r['id']==OLD_PENDING:
            r['lifecycle']='superseded'; r['superseded_by']=[did]; r['observation_refs']=sorted(set(r.get('observation_refs',[])+[oid]),key=str.encode)
        elif r['id']=='pems:chat:7da38ee068988502fe3b':
            assert OLD_SENTENCE in r['data']['summary']; r['data']['summary']=r['data']['summary'].replace(OLD_SENTENCE,NEW_SENTENCE); r['observation_refs']=sorted(set(r.get('observation_refs',[])+[oid]),key=str.encode)
        elif r['id']=='pems:continuation:7da38ee068988502fe3b':
            assert OLD_SENTENCE in r['data']['current_focus']; r['data']['current_focus']=r['data']['current_focus'].replace(OLD_SENTENCE,NEW_SENTENCE); r['observation_refs']=sorted(set(r.get('observation_refs',[])+[oid]),key=str.encode)
    d['records'] += [
      {'data':{'decision_state':'accepted','rationale':None,'summary':DECISION_SUMMARY},'id':did,'kind':'decision','lifecycle':'current','observation_refs':[oid],'supersedes':[OLD_PENDING]},
      {'data':{'captured_fingerprint':'sha256:ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa','evidence_locator':{'commit':'3ad4794f6ef89ecdde5077acee49c7d6844961f8','path':'docs/project-chat-handoff.cove.json','repository':'loteque/gdscript-voxel-engine'},'evidence_state':'immutable_snapshot','observed_at':'2026-08-14T10:03:17-07:00','source_id':'pems:source:eb92b21e7f3c92db6d23'},'id':oid,'kind':'source_observation','lifecycle':'historical','observation_refs':[]}
    ]
    return normalize_document(d)

def artifact_set(doc):
    p=canonicalize(doc); c=serialize_cove(encode(doc,profile='pems/1',serializer='jcs/1')); h=render_human_markdown(doc).encode()
    assert canonicalize(normalize_document(doc))==p; assert decode(parse_canonical(c),supported_profiles={'pems/1'})==doc; assert serialize_cove(encode(doc,profile='pems/1',serializer='jcs/1'))==c; assert render_human_markdown(doc).encode()==h
    return p,c,h

def validate(base, *docs):
    bm={r['id']:r for r in base['records']}; bids=set(bm); assert len(bids)==163
    for d in docs:
        now={r['id']:r for r in d['records']}; assert len(now)==165 and len(d['relations'])==0 and bids.issubset(now)
        assert validate_schema(d,schema=SCHEMA).valid; assert validate_semantics(d).valid
        assert [i for i in sorted(bids) if semantic_identity(now[i])!=semantic_identity(bm[i])]==[]
        for i in [OLD_PENDING,'pems:decision:b54a6445b1ce2b815b56','pems:source_observation:5b206d4358781f93074b','pems:source_observation:8c186a6ca2398e0cfe5e','pems:source_observation:be6819991bf46e7cc226']: assert i in now

def write(path,b): Path(path).write_bytes(b); return meta(b)

def main():
    eb,cb,base=base_doc(); cand=build(base,False); adm=build(base,True); validate(base,cand,adm)
    cp,cc,ch=artifact_set(cand); ap,ac,ah=artifact_set(adm)
    assert meta(ap)=={'bytes':66860,'sha256':'090466c8a5683bb01c7038531f4cfdf59a2793a65fa344da13721ed294a7a6f7','git_blob_sha':gitblob(ap)}
    assert meta(ah)['sha256']=='f2a71b0606711de6f94fc0c598c43b4549e03708556ba9f94c3eacd991511e0c'
    assert meta(ac)['bytes']==38630 and meta(ac)['sha256']=='ddccba7a10eee37a0ff851bb78d678484943ebda0610a100748c855198fb2fe3'
    manifest={}
    for path,b in [
      ('docs/handoff/pems/final-closeout.corrected.candidate.pems.json',cp),('docs/handoff/pems/final-closeout.corrected.candidate.expanded.json',cp),('docs/handoff/pems/final-closeout.corrected.candidate.cove.json',cc),('docs/handoff/pems/final-closeout.corrected.candidate.md',ch),
      ('docs/handoff/pems/final-closeout.corrected.contingent-admitted.pems.json',ap),('docs/handoff/pems/final-closeout.corrected.contingent-admitted.expanded.json',ap),('docs/handoff/pems/final-closeout.corrected.contingent-admitted.cove.json',ac),('docs/handoff/pems/final-closeout.corrected.contingent-admitted.md',ah)]: manifest[path]=write(path,b)
    evidence={'status':'corrected_frozen_codec_evidence_ready_for_steward_review','supersedes_recovery_cove_claims':{'candidate':{'bytes':38628,'sha256':'0b4a7478469c28e9d44b8358dd0ca21ec8cbb1135bb33ba29afe14f2bddb0a43'},'contingent_admitted':{'bytes':38618,'sha256':'a7ca5962c354161840822ce406bddd405296e4855afd2b0481f05f904291dc1a'}},'authority':{'architect_admission_performed':False,'canonical_authority_unchanged':'docs/project-chat-handoff.cove.json','contingent_variant_requires_steward_confirmation':True},'base':{'record_count':163,'cove':meta(cb),'expanded':meta(eb)},'candidate_to_contingent_admitted_id_map':{CAND_DEC:ADM_DEC,CAND_OBS:ADM_OBS},'record_count_after':165,'existing_ids_preserved':163,'missing_existing_ids':[],'rebound_existing_ids':[],'identity_collisions':[],'validation':{'schema_valid':True,'semantic_valid':True,'cove_round_trip':True,'repeated_bytes_identical':True,'human_reconstruction_deterministic':True,'canonical_163_codec_control_byte_equal':True},'artifacts':manifest,'accepted_tooling_source':'origin/post-cutover-admitted-regeneration'}
    ev=(json.dumps(evidence,indent=2,sort_keys=True)+'\n').encode(); write('docs/handoff/pems/final-closeout-corrected-frozen-codec.evidence.json',ev)
    notes=Path('docs/handoff/architect_notes.md'); prior=notes.read_bytes(); assert gitblob(prior)=='1872e72119e1c5fc6b62882c3dcc5e85dd858681'
    note=f'''\n\n## ARCH-20260814T145900-0700-022\n\n- timestamp: `2026-08-14T14:59:00-07:00`\n- author: Engineering Knowledge Systems Architect\n- type: handoff\n- status: resolved\n- acknowledges: `STEWARD-20260814-015`, `ARCH-20260814T123800-0700-021`\n- subject: Inconsistent final-closeout recovery COVE evidence superseded by frozen-codec regeneration\n\n### Assessment\n\nThe representation-evidence contradiction is resolved technically without changing canonical authority. The exact 165-record transition was regenerated from the verified 163-record canonical base using the accepted frozen PEMS/COVE/`jcs/1` implementation. The earlier recovery COVE hashes are superseded because they cannot be produced by that implementation. The corrected contingent-admitted COVE is 38,630 bytes with SHA-256 `ddccba7a10eee37a0ff851bb78d678484943ebda0610a100748c855198fb2fe3`. Expanded PEMS remains 66,860 bytes / `090466c8a5683bb01c7038531f4cfdf59a2793a65fa344da13721ed294a7a6f7`; human reconstruction remains 68,522 bytes / `f2a71b0606711de6f94fc0c598c43b4549e03708556ba9f94c3eacd991511e0c`.\n\nAll 163 existing identities remain present with zero rebinding, collision, history loss, or provenance loss. Schema/semantic validation, reciprocal supersession, COVE round trip, repeated canonical bytes, and deterministic human reconstruction pass. The two proposed namespace-preserving admissions remain Architect-unadmitted and require Steward confirmation.\n\n### Steward handoff\n\nUse `docs/handoff/pems/final-closeout-corrected-frozen-codec.evidence.json` and the `final-closeout.corrected.*` artifacts. If Steward verification confirms them, the contingent-admitted COVE/expanded pair is the technically valid final 165-record installation candidate. The stale 38,618-byte recovery COVE must not be used.\n\n### Human reasoning\n\nThe frozen codec reproduces the current 163-record canonical COVE exactly, so its deterministic output is the representation authority for this repair. Superseding an inconsistent recovery digest preserves the contract rather than changing it.\n'''.encode()
    final=prior+note; notes.write_bytes(final); assert final[:len(prior)]==prior
    assert BASE_EXPANDED.read_bytes()==eb and BASE_COVE.read_bytes()==cb
    print(json.dumps({'candidate':{'expanded':meta(cp),'cove':meta(cc),'human':meta(ch)},'contingent':{'expanded':meta(ap),'cove':meta(ac),'human':meta(ah)},'evidence':meta(ev),'notes_blob':gitblob(final)},indent=2,sort_keys=True))
if __name__=='__main__': main()
# trigger
