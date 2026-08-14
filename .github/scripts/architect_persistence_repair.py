from __future__ import annotations
import hashlib,json,sys
sys.path.insert(0,'/tmp/accepted-pems-cove')
from tools.cove.cove_v1 import encode,decode
from tools.cove.jcs_v1 import serialize_cove,parse_canonical
from tools.pems import normalize_document
base=normalize_document(json.load(open('docs/project-chat-handoff.json')))
produced=serialize_cove(encode(base,profile='pems/1',serializer='jcs/1'))
canonical=open('docs/project-chat-handoff.cove.json','rb').read()
print(json.dumps({'produced':{'bytes':len(produced),'sha256':hashlib.sha256(produced).hexdigest()},'canonical':{'bytes':len(canonical),'sha256':hashlib.sha256(canonical).hexdigest()},'byte_equal':produced==canonical,'round_trip_equal':decode(parse_canonical(canonical),supported_profiles={'pems/1'})==base},indent=2))
raise SystemExit(2)
