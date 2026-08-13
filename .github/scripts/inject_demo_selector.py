import argparse
from pathlib import Path


INTEGRATION_PREVIEW_ID = "integration"
INTEGRATION_PREVIEW_LABEL = "Integration Preview"
MOBILE_STREAMING_LABEL = "Runtime Streaming Validation"


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
    current_release_label = args.current_release_label
    if args.current_release_id == INTEGRATION_PREVIEW_ID:
        current_release_label = INTEGRATION_PREVIEW_LABEL

    selector = f'''
<style id="voxel-demo-selector-style">
  #voxel-demo-selector {{
    position: fixed;
    top: 12px;
    right: 16px;
    z-index: 2147483647;
    width: 520px;
    max-width: calc(100vw - 32px);
    height: 56px;
    padding: 8px 44px 8px 16px;
    border: 2px solid rgba(115, 130, 145, 0.55);
    border-radius: 16px;
    background: rgba(4, 17, 29, 0.96);
    color: #f4f6f8;
    font: 600 18px/1 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    white-space: nowrap;
    box-shadow: 0 8px 26px rgba(0, 0, 0, 0.28);
    backdrop-filter: blur(8px);
  }}

  #voxel-demo-selector:focus-visible {{
    outline: 3px solid #3d8cff;
    outline-offset: 3px;
  }}

  @media (max-width: 720px) {{
    #voxel-demo-selector {{
      left: 16px;
      right: 16px;
      width: calc(100vw - 32px);
      max-width: none;
      height: 52px;
      padding: 6px 42px 6px 14px;
      border-radius: 16px;
      font-size: 17px;
    }}
  }}
</style>
<select id="voxel-demo-selector" aria-label="Select demo and version">
  <option selected>{args.current_demo_name} · {current_release_label}</option>
</select>
<script>
  (() => {{
    const currentReleaseId = {args.current_release_id!r};
    const currentDemoKey = {args.current_demo_key!r};
    const manifestRelativeUrl = {args.manifest_relative_url!r};
    const selector = document.getElementById('voxel-demo-selector');
    const manifestUrl = new URL(manifestRelativeUrl, window.location.href);
    const mobileQuery = window.matchMedia('(max-width: 720px)');

    const displayDemoName = (demo) => {{
      if (mobileQuery.matches && demo.key === 'streaming') {{
        return {MOBILE_STREAMING_LABEL!r};
      }}
      return demo.name || demo.key;
    }};

    const populateSelector = (data) => {{
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
          const releaseLabel = releaseId === 'integration'
            ? 'Integration Preview'
            : release.label || (release.version ? `v${{release.version}}` : releaseId);
          option.value = release.path;
          option.textContent = `${{displayDemoName(demo)}} · ${{releaseLabel}}`;
          option.selected = demo.key === currentDemoKey && releaseId === currentReleaseId;
          group.appendChild(option);
        }}

        selector.appendChild(group);
      }}
    }};

    let manifestData = null;
    fetch(manifestUrl, {{ cache: 'no-store' }})
      .then(response => {{
        if (!response.ok) throw new Error('HTTP ' + response.status);
        return response.json();
      }})
      .then(data => {{
        manifestData = data;
        populateSelector(data);
      }})
      .catch(error => console.warn('Unable to load demo catalog:', error));

    mobileQuery.addEventListener('change', () => {{
      if (manifestData) populateSelector(manifestData);
    }});

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
