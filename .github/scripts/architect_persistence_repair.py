from __future__ import annotations
import copy,hashlib,json,sys
sys.path.insert(0,'/tmp/accepted-pems-cove')
from tools.cove.cove_v1 import encode
from tools.cove.jcs_v1 import canonicalize,serialize_cove
from tools.pems.human_export import render_human_markdown
base=json.load(open('docs/project-chat-handoff.json'))
old='Phase 8 technical cutover is complete and final Steward governance closeout is pending.'
new='Phase 8 technical cutover and final Steward governance closeout are complete.'
summary='Engineering-memory representation workstream field \'phase8_status\' is "accepted_complete".'

def build(did,oid):
 d=copy.deepcopy(base)
 for r in d['records']:
  if r['id']=='pems:decision:abe7b5d5efc6d7232e72':
   r['lifecycle']='superseded';r['superseded_by']=[did];r['observation_refs']=sorted(set(r['observation_refs']+[oid]),key=str.encode)
  elif r['id']=='pems:chat:7da38ee068988502fe3b':
   r['data']['summary']=r['data']['summary'].replace(old,new);r['observation_refs']=sorted(set(r['observation_refs']+[oid]),key=str.encode)
  elif r['id']=='pems:continuation:7da38ee068988502fe3b':
   r['data']['current_focus']=r['data']['current_focus'].replace(old,new);r['observation_refs']=sorted(set(r['observation_refs']+[oid]),key=str.encode)
 d['records'] += [
  {'data':{'decision_state':'accepted','rationale':None,'summary':summary},'id':did,'kind':'decision','lifecycle':'current','observation_refs':[oid],'supersedes':['pems:decision:abe7b5d5efc6d7232e72']},
  {'data':{'captured_fingerprint':'sha256:ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa','evidence_locator':{'commit':'3ad4794f6ef89ecdde5077acee49c7d6844961f8','path':'docs/project-chat-handoff.cove.json','repository':'loteque/gdscript-voxel-engine'},'evidence_state':'immutable_snapshot','observed_at':'2026-08-14T10:03:17-07:00','source_id':'pems:source:eb92b21e7f3c92db6d23'},'id':oid,'kind':'source_observation','lifecycle':'historical','observation_refs':[]}
 ]
 d['records']=sorted(d['records'],key=lambda r:r['id'].encode())
 return d

def info(doc):
 p=canonicalize(doc);c=serialize_cove(encode(doc,profile='pems/1',serializer='jcs/1'));h=render_human_markdown(doc).encode()
 return {k:{'bytes':len(v),'sha256':hashlib.sha256(v).hexdigest()} for k,v in [('expanded',p),('cove',c),('human',h)]}
print(json.dumps({'candidate':info(build('candidate:decision:5fa3241c8b9bc2787b6d','candidate:source_observation:15b32d4adb9bcfa4fc94')),'contingent':info(build('pems:decision:5fa3241c8b9bc2787b6d','pems:source_observation:15b32d4adb9bcfa4fc94'))},indent=2))
raise SystemExit(2)
