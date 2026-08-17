const repo='loteque/gdscript-voxel-engine';
const branch='project-chat-handoff';

const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const title=s=>String(s).replaceAll('_',' ').replace(/\b\w/g,c=>c.toUpperCase());

function pill(state){
  const cls=state==='disposed'||state==='proof_persisted'?'ok':state==='waiting_steward'||state==='waiting_execution'?'warn':state==='execution_requested'?'active':'neutral';
  return `<span class="pill ${cls}">${esc(title(state))}</span>`;
}
function bars(target,obj){
  const root=document.querySelector(target); const entries=Object.entries(obj||{}); const max=Math.max(1,...entries.map(([,v])=>Number(v)||0));
  root.innerHTML=entries.length?entries.map(([k,v])=>`<div class="bar-row"><div class="bar-label">${esc(title(k))}</div><div class="bar-track"><div class="bar-fill" style="width:${Math.round((Number(v)||0)/max*100)}%"></div></div><div class="bar-value">${Number(v)||0}</div></div>`).join(''):'<p class="action-meta">No evidence yet.</p>';
}
function stats(data){
  const s=data.summary; const rows=[['Submissions',s.submissions],['Waiting Steward',data.pipeline_state_counts.waiting_steward||0],['Waiting Execution',data.pipeline_state_counts.waiting_execution||0],['Canonical Records',s.canonical_records],['Proof Bundles',s.proof_bundles],['Corrections / Retries',s.correction_retry_pressure],['Test PASS Lines',s.test_pass_lines],['Test FAIL Lines',s.test_fail_lines]];
  document.querySelector('#summary').innerHTML=rows.map(([l,v])=>`<div class="stat"><div class="value">${esc(v)}</div><div class="label">${esc(l)}</div></div>`).join('');
}
function queue(data){
  const tbody=document.querySelector('#queue');
  tbody.innerHTML=data.submissions.map(r=>`<tr><td><a href="https://github.com/${repo}/blob/${branch}/${encodeURI(r.submission_path)}" target="_blank" rel="noreferrer">${esc(r.submission_id)}</a></td><td>${pill(r.state)}</td><td class="num">${r.plan_count}</td><td class="num">${r.request_count}</td><td class="num">${r.evidence_count}</td><td class="num">${r.disposition_count}</td></tr>`).join('');
}
async function liveActions(){
  const root=document.querySelector('#actions'), badge=document.querySelector('#live-badge');
  try{
    const res=await fetch(`https://api.github.com/repos/${repo}/actions/runs?branch=${encodeURIComponent(branch)}&per_page=12`,{headers:{Accept:'application/vnd.github+json'}});
    if(!res.ok) throw new Error(`GitHub API ${res.status}`);
    const data=await res.json(); const runs=(data.workflow_runs||[]).filter(r=>/Distiller|RGP|PEMS/i.test(r.name)).slice(0,8);
    const active=runs.filter(r=>r.status==='queued'||r.status==='in_progress');
    badge.className=`badge ${active.length?'active':'ok'}`; badge.textContent=active.length?`${active.length} workflow${active.length===1?'':'s'} active`:'No active workflows';
    root.innerHTML=runs.map(r=>{const state=r.status==='completed'?(r.conclusion||'completed'):r.status; const cls=state==='success'?'ok':state==='failure'?'bad':state==='queued'||state==='in_progress'?'active':'neutral'; return `<div class="action-row"><div><div class="action-name"><a href="${esc(r.html_url)}" target="_blank" rel="noreferrer">${esc(r.name)}</a></div><div class="action-meta">${esc(r.display_title||'')} · ${esc(new Date(r.created_at).toLocaleString())}</div></div><span class="pill ${cls}">${esc(title(state))}</span></div>`}).join('')||'<p class="action-meta">No matching workflow runs.</p>';
  }catch(err){badge.className='badge warn';badge.textContent='Live status unavailable';root.innerHTML=`<p class="action-meta">${esc(err.message)}</p>`;}
}

fetch('./data.json',{cache:'no-store'}).then(r=>{if(!r.ok)throw new Error(`data.json ${r.status}`);return r.json()}).then(data=>{
  stats(data); queue(data); bars('#pipeline-chart',data.pipeline_state_counts); bars('#proof-chart',data.proof_transaction_totals); bars('#test-chart',{pass:data.summary.test_pass_lines,fail:data.summary.test_fail_lines});
  document.querySelector('#generated-at').textContent=`snapshot ${new Date(data.generated_at).toLocaleString()}`;
}).catch(err=>{document.querySelector('#summary').innerHTML=`<div class="card">Dashboard snapshot failed to load: ${esc(err.message)}</div>`});
liveActions();
setInterval(liveActions,60000);
