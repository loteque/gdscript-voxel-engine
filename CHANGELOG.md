# Changelog

All notable changes to this project are recorded here by project version.

## 0.1.3

### Fixed
- Isolated `gh-pages` archive assembly in a separate Git worktree so generated `build/web` files cannot block switching to the archive branch.
- Removed legacy root-level `build/` output from the Pages archive during publishing.
- Pull request web validation now exercises the archive worktree assembly path and verifies root build output is not present.

## 0.1.2

### Changed
- Upgraded GitHub Pages actions to Node.js 24-compatible major versions: `actions/configure-pages@v6`, `actions/upload-pages-artifact@v5`, and `actions/deploy-pages@v5`.
- Pull request web deployment validation now uses the same current Pages action majors as production deployment.

## 0.1.1

### Fixed
- GitHub Actions workflow parsing for JavaScript inside the version selector injection.
- Versioned web deployment validation now avoids `${...}` JavaScript template expressions that GitHub Actions can misinterpret as workflow expressions.

## 0.1.0

### Added
- Project-wide semantic version source in `VERSION`.
- Pull request validation for version, changelog, project metadata, and splash-screen consistency.
- Versioned GitHub Pages web builds with immutable release directories.
- Project version displayed at the bottom center of the boot splash screen.
- Top-right version selector on deployed web builds for switching between published versions.
- Pull request validation that exports the versioned Web build, assembles the Pages payload, smoke-tests it over HTTP, and uploads the validated deployment artifact.
