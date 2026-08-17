#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

SUBMISSIONS = Path('docs/handoff/rgp/submissions')
TRANSACTIONS = Path('docs/handoff/rgp/admission/transactions')
REQUESTS = Path('docs/handoff/rgp/automation-requests')
EVIDENCE = Path('docs/handoff/rgp/evidence')
DISPOSITIONS = Path('docs/handoff/rgp/dispositions')
CANONICAL = Path('docs/project-chat-handoff.json')


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding='utf-8'))
    except Exception:
        return None


def submission_id(path: Path) -> str:
    return path.stem


def request_submission_id(obj: dict) -> str | None:
    raw = obj.get('submission_path')
    if not isinstance(raw, str):
        return None
    return Path(raw).stem


def evidence_summaries() -> list[tuple[Path, dict]]:
    rows = []
    if not EVIDENCE.exists():
        return rows
    for path in EVIDENCE.glob('*/automation-summary.json'):
        obj = read_json(path)
        if isinstance(obj, dict):
            rows.append((path, obj))
    return rows


def extract_proof_metrics(evidence_dir: Path) -> dict:
    proof = read_json(evidence_dir / 'admission-proof.json') or {}
    tx = proof.get('transaction') if isinstance(proof, dict) else {}
    if not isinstance(tx, dict):
        tx = {}
    return {
        'new_records': int(tx.get('new_record_count', 0) or 0),
        'reused_records': int(tx.get('reuse_record_count', 0) or 0),
        'updated_records': int(tx.get('record_update_count', 0) or 0),
        'new_relations': int(tx.get('new_relation_count', 0) or 0),
    }


def extract_test_counts(evidence_dir: Path) -> tuple[int, int]:
    passed = failed = 0
    for name in ('rgp-validator.txt', 'pems2-candidate-validation.txt', 'transaction.txt'):
        path = evidence_dir / name
        if not path.exists():
            continue
        for line in path.read_text(encoding='utf-8', errors='replace').splitlines():
            s = line.strip().upper()
            if s.startswith('PASS'):
                passed += 1
            elif s.startswith('FAIL') or 'ERROR' in s:
                failed += 1
    return passed, failed


def disposition_index() -> dict[str, list[str]]:
    out: dict[str, list[str]] = defaultdict(list)
    if not DISPOSITIONS.exists():
        return out
    for path in DISPOSITIONS.glob('*.json'):
        text = path.read_text(encoding='utf-8', errors='replace')
        for sid in re.findall(r'RGP-\d{8}T\d{6}-\d{4}-\d{3}', text):
            out[sid].append(path.as_posix())
    return out


def build() -> dict:
    submission_paths = sorted(SUBMISSIONS.glob('RGP-*.json')) if SUBMISSIONS.exists() else []
    transaction_paths = sorted(TRANSACTIONS.glob('*.json')) if TRANSACTIONS.exists() else []
    request_paths = sorted(REQUESTS.glob('*.json')) if REQUESTS.exists() else []

    plans: dict[str, list[str]] = defaultdict(list)
    for path in transaction_paths:
        m = re.match(r'(RGP-\d{8}T\d{6}-\d{4}-\d{3})\.', path.name)
        if m:
            plans[m.group(1)].append(path.as_posix())

    requests: dict[str, list[dict]] = defaultdict(list)
    for path in request_paths:
        obj = read_json(path)
        if isinstance(obj, dict):
            sid = request_submission_id(obj)
            if sid:
                requests[sid].append({'path': path.as_posix(), 'install': obj.get('install'), 'contract': obj.get('contract')})

    evidence: dict[str, list[dict]] = defaultdict(list)
    proof_totals = Counter()
    test_pass = test_fail = 0
    for path, obj in evidence_summaries():
        sid = request_submission_id(obj)
        if not sid:
            continue
        metrics = extract_proof_metrics(path.parent)
        p, f = extract_test_counts(path.parent)
        test_pass += p
        test_fail += f
        proof_totals.update(metrics)
        evidence[sid].append({
            'path': path.parent.as_posix(),
            'status': obj.get('status'),
            'install_requested': obj.get('install_requested'),
            'reconciliation_authority': obj.get('reconciliation_authority'),
            'workflow_performs_semantic_reconciliation': obj.get('workflow_performs_semantic_reconciliation'),
            'metrics': metrics,
        })

    dispositions = disposition_index()
    rows = []
    state_counts = Counter()
    corrections = 0
    for path in submission_paths:
        sid = submission_id(path)
        p = plans.get(sid, [])
        r = requests.get(sid, [])
        e = evidence.get(sid, [])
        d = dispositions.get(sid, [])
        corrections += max(0, len(p) - 1) + max(0, len(r) - 1)
        if d:
            state = 'disposed'
        elif e:
            state = 'proof_persisted'
        elif r:
            state = 'execution_requested'
        elif p:
            state = 'waiting_execution'
        else:
            state = 'waiting_steward'
        state_counts[state] += 1
        rows.append({
            'submission_id': sid,
            'submission_path': path.as_posix(),
            'state': state,
            'plan_count': len(p),
            'request_count': len(r),
            'evidence_count': len(e),
            'disposition_count': len(d),
            'plans': p,
            'requests': r,
            'evidence': e,
            'dispositions': d,
        })

    canonical = read_json(CANONICAL) or {}
    records = canonical.get('records') if isinstance(canonical, dict) else []
    relations = canonical.get('relations') if isinstance(canonical, dict) else []

    rows.sort(key=lambda r: r['submission_id'], reverse=True)
    return {
        'contract': 'distiller-operations-dashboard/1',
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'repository': 'loteque/gdscript-voxel-engine',
        'branch': 'project-chat-handoff',
        'authority': {
            'distiller': 'candidate_producer_only',
            'reconciliation_authority': 'project-engineering-steward',
            'executor_performs_semantic_reconciliation': False,
        },
        'summary': {
            'submissions': len(rows),
            'transactions': len(transaction_paths),
            'execution_requests': len(request_paths),
            'proof_bundles': sum(len(v) for v in evidence.values()),
            'dispositions': len(list(DISPOSITIONS.glob('*.json'))) if DISPOSITIONS.exists() else 0,
            'canonical_records': len(records) if isinstance(records, list) else 0,
            'canonical_relations': len(relations) if isinstance(relations, list) else 0,
            'correction_retry_pressure': corrections,
            'test_pass_lines': test_pass,
            'test_fail_lines': test_fail,
        },
        'pipeline_state_counts': dict(state_counts),
        'proof_transaction_totals': dict(proof_totals),
        'submissions': rows,
    }


def validate(data: dict) -> None:
    assert data['contract'] == 'distiller-operations-dashboard/1'
    assert data['authority']['distiller'] == 'candidate_producer_only'
    assert data['authority']['reconciliation_authority'] == 'project-engineering-steward'
    assert data['authority']['executor_performs_semantic_reconciliation'] is False
    assert sum(data['pipeline_state_counts'].values()) == data['summary']['submissions']
    for row in data['submissions']:
        assert row['state'] in {'waiting_steward','waiting_execution','execution_requested','proof_persisted','disposed'}
        if row['state'] == 'waiting_steward':
            assert row['plan_count'] == 0
        if row['state'] == 'waiting_execution':
            assert row['plan_count'] > 0 and row['request_count'] == 0
        if row['state'] == 'execution_requested':
            assert row['request_count'] > 0 and row['evidence_count'] == 0
        if row['state'] == 'proof_persisted':
            assert row['evidence_count'] > 0 and row['disposition_count'] == 0
        if row['state'] == 'disposed':
            assert row['disposition_count'] > 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    data = build()
    validate(data)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    print(json.dumps(data['summary'], sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
