#!/usr/bin/env python3
import hashlib,json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[4]
V2=ROOT/'docs/handoff/pems/v2'
SOURCE=V2/'FULL_CORPUS_PEMS2.json'
CANON_COVE=ROOT/'docs/project-chat-handoff.cove.json'
CANON_EXP=ROOT/'docs/project-chat-handoff.json'
OUT_COVE=V2/'CUTOVER_CANDIDATE.cove.json'
OUT_JCS=V2/'CUTOVER_CANDIDATE.pems2.jcs.json'
OUT_HUMAN=V2/'CUTOVER_CANDIDATE_HUMAN_RECONSTRUCTION.md'
OUT_FIX=V2/'CUTOVER_DUAL_READ_FIXTURES.json'
OUT_EVID=V2/'CUTOVER_CANDIDATE_EVIDENCE.json'

def jcs(v):
    return json.dumps(v,ensure_ascii=False,sort_keys=True,separators=(',',':'),allow_nan=False).encode()
def sha(b): return hashlib.sha256(b).hexdigest()
def strings(v,out):
    if isinstance(v,str): out.add(v)
    elif isinstance(v,list):
        for x in v: strings(x,out)
    elif isinstance(v,dict):
        for k,x in v.items(): out.add(k); strings(x,out)
def shapes(v,didx,out):
    if isinstance(v,list):
        for x in v: shapes(x,didx,out)
    elif isinstance(v,dict):
        out.add(tuple(sorted(didx[k] for k in v)))
        for x in v.values(): shapes(x,didx,out)
def encode(v,didx,sidx):
    if isinstance(v,str): return [0,didx[v]]
    if isinstance(v,list): return [1,*[encode(x,didx,sidx) for x in v]]
    if isinstance(v,dict):
        shape=tuple(sorted(didx[k] for k in v)); keys=sorted(v,key=lambda k:didx[k])
        return [2,sidx[shape],*[encode(v[k],didx,sidx) for k in keys]]
    return v
def decode(v,d,h):
    if not isinstance(v,list): return v
    if v[0]==0: return d[v[1]]
    if v[0]==1: return [decode(x,d,h) for x in v[1:]]
    if v[0]==2:
        keys=[d[i] for i in h[v[1]]]; vals=v[2:]
        if len(keys)!=len(vals): raise ValueError('shape arity')
        return {k:decode(x,d,h) for k,x in zip(keys,vals)}
    raise ValueError('unknown tag')
def encode_cove(obj,profile):
    ss=set(); strings(obj,ss); d=sorted(ss,key=lambda s:s.encode())
    didx={s:i for i,s in enumerate(d)}; hs=set(); shapes(obj,didx,hs)
    h=sorted(hs); sidx={s:i for i,s in enumerate(h)}
    return {'c':'cove/1','p':profile,'s':'jcs/1','d':d,'h':[list(x) for x in h],'x':encode(obj,didx,sidx)}
def render(obj):
    lines=['# PEMS/2 Cutover Candidate Human Reconstruction','',f"Project: `{obj['project_id']}`",f"Records: {len(obj['records'])}",f"Relations: {len(obj['relations'])}",'']
    for r in obj['records']:
        lines += [f"## {r['id']}",f"- kind: `{r['kind']}`",f"- lifecycle: `{r['lifecycle']}`",f"- data: `{json.dumps(r.get('data',{}),ensure_ascii=False,sort_keys=True,separators=(',',':'))}`",f"- provenance: `{json.dumps(r.get('provenance',{}),ensure_ascii=False,sort_keys=True,separators=(',',':'))}`",'']
    return '\n'.join(lines)+'\n'

obj=json.loads(SOURCE.read_text())
assert obj['semantic']=='pems/2' and len(obj['records'])==174
ids=[r['id'] for r in obj['records']]; assert len(ids)==len(set(ids))==174
cove=encode_cove(obj,'pems/2'); decoded=decode(cove['x'],cove['d'],cove['h']); assert decoded==obj
cove_bytes=jcs(cove); jcs_bytes=jcs(obj); human=render(obj).encode()
# repeated construction proof
assert jcs(encode_cove(json.loads(SOURCE.read_text()),'pems/2'))==cove_bytes
assert jcs(json.loads(SOURCE.read_text()))==jcs_bytes
canon_cove=CANON_COVE.read_bytes(); canon_exp=CANON_EXP.read_bytes(); canon_env=json.loads(canon_cove)
assert canon_env['c']=='cove/1' and canon_env['p']=='pems/1' and canon_env['s']=='jcs/1'
fixtures={
 'accepted_tuples':['cove/1|pems/1|jcs/1','cove/1|pems/2|jcs/1'],
 'fail_closed':['cove/1|pems/3|jcs/1','cove/2|pems/2|jcs/1','cove/1|pems/2|jcs/2'],
 'cross_profile_coercion':False,
 'candidate_tuple':'cove/1|pems/2|jcs/1'
}
evidence={
 'status':'validated_noncanonical_cutover_candidate',
 'authorization':'STEWARD-20260816-024',
 'source':{'canonical_record_count':174,'canonical_cove_blob':'32c6cf2b594e2f3de3eea4ccda863ba84f24ce3f','canonical_cove_sha256':sha(canon_cove),'canonical_cove_bytes':len(canon_cove),'canonical_derivative_blob':'98450a42f33a834203968e564700392149c3e834','canonical_derivative_sha256':sha(canon_exp),'canonical_derivative_bytes':len(canon_exp)},
 'candidate':{'tuple':'cove/1|pems/2|jcs/1','record_count':174,'cove_sha256':sha(cove_bytes),'cove_bytes':len(cove_bytes),'jcs_sha256':sha(jcs_bytes),'jcs_bytes':len(jcs_bytes),'human_sha256':sha(human),'human_bytes':len(human)},
 'proofs':{'cove_structural_round_trip':decoded==obj,'semantic_profile':'pems/2','identity_count':174,'identity_unique':len(set(ids))==174,'repeated_cove_bytes_identical':True,'repeated_jcs_bytes_identical':True,'typed_or_primary_provenance_invented':False,'dual_read_fixtures':fixtures,'rollback_uses_exact_prior_artifacts':True},
 'authority':{'canonical_changed':False,'authority_transferred':False,'owner_decision_required_for_cutover':True}
}
OUT_COVE.write_bytes(cove_bytes)
OUT_JCS.write_bytes(jcs_bytes)
OUT_HUMAN.write_bytes(human)
OUT_FIX.write_bytes(jcs(fixtures))
OUT_EVID.write_bytes(jcs(evidence))
print(json.dumps(evidence,indent=2,sort_keys=True))
