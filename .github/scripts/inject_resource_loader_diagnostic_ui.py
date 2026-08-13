#!/usr/bin/env python3
"""Inject an accessible result/export overlay into the direct ResourceLoader Web diagnostic."""

from __future__ import annotations

import pathlib
import sys


MARKER = "<!-- voxel-resource-loader-diagnostic-ui -->"

UI = r'''
<!-- voxel-resource-loader-diagnostic-ui -->
<style>
#voxel-resource-loader-diagnostic {
  position: fixed;
  z-index: 10000;
  top: 18px;
  left: 18px;
  right: 18px;
  max-width: 920px;
  margin: 0 auto;
  padding: 20px;
  border: 2px solid #3a4654;
  border-radius: 18px;
  background: rgba(5, 14, 23, 0.96);
  color: #f2f5f8;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  font-size: 22px;
  line-height: 1.35;
  box-sizing: border-box;
  box-shadow: 0 14px 40px rgba(0,0,0,.42);
}
#voxel-resource-loader-diagnostic.collapsed {
  left: auto;
  width: auto;
  padding: 10px 14px;
}
#voxel-resource-loader-diagnostic.collapsed .diagnostic-body { display: none; }
#voxel-resource-loader-diagnostic h1 { margin: 0 0 8px; font-size: 30px; }
#voxel-resource-loader-diagnostic p { margin: 8px 0 14px; }
#voxel-resource-loader-diagnostic .status { color: #5ce66e; font-weight: 750; font-size: 25px; }
#voxel-resource-loader-diagnostic .pending { color: #4e91ff; }
#voxel-resource-loader-diagnostic .failure { color: #ff5960; }
#voxel-resource-loader-diagnostic .buttons { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 16px; }
#voxel-resource-loader-diagnostic button,
#voxel-resource-loader-diagnostic a {
  min-height: 58px;
  padding: 10px 18px;
  border: 2px solid #3c8cff;
  border-radius: 13px;
  background: #083a80;
  color: white;
  font: inherit;
  font-weight: 700;
  text-decoration: none;
  cursor: pointer;
}
#voxel-resource-loader-diagnostic button.secondary,
#voxel-resource-loader-diagnostic a.secondary { background: #19222c; border-color: #526170; }
#voxel-resource-loader-diagnostic table { width: 100%; border-collapse: collapse; margin-top: 14px; }
#voxel-resource-loader-diagnostic th,
#voxel-resource-loader-diagnostic td { padding: 7px 10px; text-align: right; border-bottom: 1px solid #34404c; }
#voxel-resource-loader-diagnostic th:first-child,
#voxel-resource-loader-diagnostic td:first-child { text-align: left; }
#voxel-resource-loader-diagnostic .small { font-size: 18px; color: #b9c4ce; }
@media (max-width: 700px) {
  #voxel-resource-loader-diagnostic { font-size: 21px; top: 10px; left: 10px; right: 10px; padding: 16px; }
  #voxel-resource-loader-diagnostic h1 { font-size: 28px; }
  #voxel-resource-loader-diagnostic .buttons { display: grid; grid-template-columns: 1fr; }
  #voxel-resource-loader-diagnostic button,
  #voxel-resource-loader-diagnostic a { width: 100%; }
}
</style>
<div id="voxel-resource-loader-diagnostic" role="region" aria-label="Resource loading diagnostic">
  <button id="resource-loader-collapse" class="secondary" style="float:right; min-height:48px">Collapse</button>
  <div class="diagnostic-body">
    <h1>Direct ResourceLoader Matrix</h1>
    <p>This isolates Web resource loading from ChunkStreamer, residency, terrain traversal, and mesh instance creation.</p>
    <div id="resource-loader-status" class="status pending" aria-live="polite">Running 12 automated measurements…</div>
    <div id="resource-loader-summary"></div>
    <div class="buttons">
      <button id="resource-loader-export" disabled>Export JSON</button>
      <button id="resource-loader-rerun" class="secondary">Run Again</button>
      <a href="../" class="secondary">Back to Streaming Demo</a>
    </div>
    <p class="small">Use the exported JSON as the experiment record. Cache state is not laboratory-controlled and is recorded as a limitation.</p>
  </div>
</div>
<script>
(() => {
  const root = document.getElementById('voxel-resource-loader-diagnostic');
  const status = document.getElementById('resource-loader-status');
  const summary = document.getElementById('resource-loader-summary');
  const exportButton = document.getElementById('resource-loader-export');
  const collapseButton = document.getElementById('resource-loader-collapse');
  let payload = null;

  const median = values => {
    const sorted = [...values].sort((a,b) => a-b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  };

  const render = value => {
    payload = value;
    const runs = value?.measured?.runs || [];
    const groups = new Map();
    for (const run of runs) {
      if (!groups.has(run.concurrency)) groups.set(run.concurrency, []);
      groups.get(run.concurrency).push(run);
    }
    let html = '<table><thead><tr><th>Concurrency</th><th>Median batch</th><th>Median throughput</th><th>Median latency</th></tr></thead><tbody>';
    for (const [concurrency, group] of [...groups.entries()].sort((a,b) => a[0]-b[0])) {
      html += `<tr><td>${concurrency}</td><td>${median(group.map(r => r.duration_msec)).toFixed(1)} ms</td><td>${median(group.map(r => r.throughput_assets_per_second)).toFixed(1)}/s</td><td>${median(group.map(r => r.average_latency_msec)).toFixed(1)} ms</td></tr>`;
    }
    html += '</tbody></table>';
    summary.innerHTML = html;
    status.textContent = value.success ? `Complete: ${runs.length}/12 runs, no experiment failure.` : `Experiment failed: ${value.failure || 'unknown error'}`;
    status.className = value.success ? 'status' : 'status failure';
    exportButton.disabled = false;
  };

  const poll = setInterval(() => {
    if (window.__voxelResourceLoadingExperiment) {
      clearInterval(poll);
      render(window.__voxelResourceLoadingExperiment);
    }
  }, 200);

  exportButton.addEventListener('click', () => {
    if (!payload) return;
    const blob = new Blob([JSON.stringify(payload, null, 2)], {type: 'application/json'});
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'mobile-web-resource-loading-experiment.json';
    document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 0);
  });

  document.getElementById('resource-loader-rerun').addEventListener('click', () => location.reload());
  collapseButton.addEventListener('click', () => {
    root.classList.toggle('collapsed');
    collapseButton.textContent = root.classList.contains('collapsed') ? 'Show Experiment UI' : 'Collapse';
  });
})();
</script>
'''


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: inject_resource_loader_diagnostic_ui.py <index.html>")
    path = pathlib.Path(sys.argv[1])
    text = path.read_text(encoding="utf-8")
    if MARKER in text:
        return 0
    if "</body>" not in text:
        raise SystemExit(f"{path} does not contain </body>")
    path.write_text(text.replace("</body>", UI + "\n</body>", 1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
