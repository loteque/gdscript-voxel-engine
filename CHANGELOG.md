# Changelog

All notable changes to this project are recorded here by project version.

## 0.1.0

### Added
- Project-wide semantic version source in `VERSION`.
- Pull request validation for version, changelog, project metadata, and splash-screen consistency.
- Versioned GitHub Pages web builds with immutable release directories.
- Project version displayed at the bottom center of the boot splash screen.
- Top-right version selector on deployed web builds for switching between published versions.
- Pull request validation that exports the versioned Web build, assembles the Pages payload, smoke-tests it over HTTP, and uploads the validated deployment artifact.
