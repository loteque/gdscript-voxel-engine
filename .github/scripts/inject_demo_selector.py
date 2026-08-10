import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("index_path")
    parser.add_argument("current_release_id")
    parser.add_argument("current_release_label")
    parser.add_argument("current_demo_key")
    parser.add_argument("current_demo_name")
    parser.add_argument("manifest_relative_url")
    args = parser.parse_args()

    index_path = Path(args.index_path)
    html = index_path.read_text(encoding="utf-8")

    selector = f'''
<style id="voxel-demo-selector-style">
  #voxel-demo-selector {{
    position: fixed;
    top: 12px;
    right: 12px;
    z-index: 2147483647;
    width: 380px;
    max-width: calc(100vw - 24px);
    padding: 7px 10px;
    border: 1px solid rgba(255, 255, 255, 0.22);
    border-radius: 6px;
    background: rgba(7, 21, 34, 0.9);
    color: #f3f5f7;
    font: 12px/1.2 monospace;
    backdrop-filter: blur(4px);
  }}
</style>
<select id="voxel-demo-selector" aria-label="Select demo and version">
  <option selected>{args.current_demo_name} · {args.current_release_label}</option>
</select>
<script>
  (() => {{
    const currentReleaseId = {args.current_release_id!r};
    const currentDemoKey = {args.current_demo_key!r};
    const manifestRelativeUrl = {args.manifest_relative_url!r};
    const selector = document.getElementById('voxel-demo-selector');
    const manifestUrl = new URL(manifestRelativeUrl, window.location.href);

    fetch(manifestUrl, {{ cache: 'no-store' }})
      .then(response => {{
        if (!response.ok) throw new Error('HTTP ' + response.status);
        return response.json();
      }})
      .then(data => {{
        const demos = Array.isArray(data.demos) ? data.demos : [];
        selector.replaceChildren();

        for (const demo of demos) {{
          const releases = Array.isArray(demo.releases) ? demo.releases : [];
          if (releases.length === 0) continue;

          const group = document.createElement('optgroup');
          group.label = demo.name || demo.key;

          for (const release of releases) {{
            const option = document.createElement('option');
            const releaseId = release.id || release.version;
            const releaseLabel = release.label || (release.version ? `v${{release.version}}` : releaseId);
            option.value = release.path;
            option.textContent = `${{demo.name || demo.key}} · ${{releaseLabel}}`;
            option.selected = demo.key === currentDemoKey && releaseId === currentReleaseId;
            group.appendChild(option);
          }}

          selector.appendChild(group);
        }}
      }})
      .catch(error => console.warn('Unable to load demo catalog:', error));

    selector.addEventListener('change', () => {{
      if (!selector.value) return;
      window.location.href = new URL(selector.value, manifestUrl).href;
    }});
  }})();
</script>
'''

    if "</body>" not in html:
        raise SystemExit(f"{index_path} does not contain </body>.")

    html = html.replace("</body>", selector + "\n</body>", 1)
    index_path.write_text(html, encoding="utf-8")


if __name__ == "__main__":
    main()
