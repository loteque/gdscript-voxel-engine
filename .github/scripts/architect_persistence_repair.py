from __future__ import annotations
import copy, hashlib, itertools, json

base=json.load(open('docs/project-chat-handoff.json'))
target='1d2378cf19a247256c327dd8f12ed639c7508dba555fa7c7a92df44fd98b98ba'
old_pending='pems:decision:abe7b5d5efc6d7232e72'
did='candidate:decision:5fa3241c8b9bc2787b6d'
oid='candidate:source_observation:15b32d4adb9bcfa4fc94'
old_sentence='Phase 8 technical cutover is complete and final Steward governance closeout is pending.'
new_sentence='Phase 8 technical cutover and final Steward governance closeout are complete.'
summary='Engineering-memory representation workstream field \'phase8_status\' is "accepted_complete".'

def canon(d): return json.dumps(d,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()
def build(bits):
    chat_obs,cont_obs,hv,old_obs,dec_obs,project_obs,rationale,obs_current,old_superseded,dec_supersedes=bits
    d=copy.deepcopy(base)
    for r in d['records']:
        if r['id']==old_pending:
            if old_superseded:
                r['lifecycle']='superseded';r['superseded_by']=[did]
            if old_obs:r['observation_refs']=sorted(set(r.get('observation_refs',[])+[oid]),key=str.encode)
        elif r['id']=='pems:chat:7da38ee068988502fe3b':
            r['data']['summary']=r['data']['summary'].replace(old_sentence,new_sentence)
            if chat_obs:r['observation_refs']=sorted(set(r.get('observation_refs',[])+[oid]),key=str.encode)
        elif r['id']=='pems:continuation:7da38ee068988502fe3b':
            r['data']['current_focus']=r['data']['current_focus'].replace(old_sentence,new_sentence)
            if cont_obs:r['observation_refs']=sorted(set(r.get('observation_refs',[])+[oid]),key=str.encode)
            if hv:r['data']['high_value_record_ids']=sorted(set(r['data']['high_value_record_ids']+[did]),key=str.encode)
        elif r['id']=='pems:project:f16c91ec0a6e67eb2e1d' and project_obs:
            r['observation_refs']=sorted(set(r.get('observation_refs',[])+[oid]),key=str.encode)
    data={'decision_state':'accepted','summary':summary}
    if rationale:data['rationale']=None
    nr={'data':data,'id':did,'kind':'decision','lifecycle':'current','observation_refs':([oid] if dec_obs else [])}
    if dec_supersedes:nr['supersedes']=[old_pending]
    d['records'].append(nr)
    d['records'].append({'data':{'captured_fingerprint':'sha256:ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa','evidence_locator':{'commit':'3ad4794f6ef89ecdde5077acee49c7d6844961f8','path':'docs/project-chat-handoff.cove.json','repository':'loteque/gdscript-voxel-engine'},'evidence_state':'immutable_snapshot','observed_at':'2026-08-14T10:03:17-07:00','source_id':'pems:source:eb92b21e7f3c92db6d23'},'id':oid,'kind':'source_observation','lifecycle':('current' if obs_current else 'historical'),'observation_refs':[]})
    d['records']=sorted(d['records'],key=lambda r:r['id'].encode())
    return d

near=[]
for bits in itertools.product([False,True],repeat=10):
    d=build(bits);b=canon(d);h=hashlib.sha256(b).hexdigest()
    if h==target:
        print('EXACT_CANDIDATE_BITS',bits,'bytes',len(b));raise SystemExit(2)
    if len(b)==66895:near.append((h,bits))
print('NO_EXACT',len(near))
for item in near[:100]:print(item)
raise SystemExit(3)
