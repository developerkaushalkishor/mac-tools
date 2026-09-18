# Contributing to ScreenInk

Thanks for helping make a small native Mac annotation tool better. Contributions can be code, documentation, reproducible bug reports or compatibility testing.

## Before starting

Check existing [issues](https://github.com/developerkaushalkishor/mac-tools/issues) and the [roadmap](docs/PLAN.md). For larger features or architecture changes, open an issue describing the problem and proposed scope before investing in an implementation. Small, focused fixes can go directly to a pull request.

## Set up a contribution

1. Fork the repository on GitHub.
2. Clone your fork, replacing YOUR_GITHUB_USERNAME below.
3. Add the original repository as upstream and create a descriptive branch.

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/mac-tools.git
cd mac-tools
git remote add upstream https://github.com/developerkaushalkishor/mac-tools.git
git switch -c fix/short-description
bash scripts/doctor.sh
bash scripts/test.sh
bash scripts/build.sh
codesign --verify --deep --strict --verbose=2 dist/ScreenInk.app
```

See [installation](docs/INSTALLATION.md) and the [developer guide](docs/FIRST_MAC_APP.md) for toolchain details.

## Engineering expectations

- Keep source code, comments, public documentation and pull-request descriptions in clear English.
- Prefer native macOS APIs and justify new dependencies.
- Keep drawing history and visibility rules in `InkCore` where they can be tested without desktop automation.
- Preserve normal click-through mode, a reachable exit path and the menu-bar recovery controls.
- Add meaningful regression tests for behavior changes. Documentation-only changes need link/command review, not new unit tests.
- Test UI changes on a real Mac and state what you observed. Do not equate compilation with verified desktop behavior.
- Keep the app offline by default; discuss network services, telemetry, new permissions or background components before adding them.
- Update usage docs when controls or behavior change. Keep planned features separate from available features.
- Do not commit `.build`, `dist`, personal Xcode state, signing certificates, credentials or private screenshots.

## Validate

For code changes:

```bash
bash scripts/test.sh
bash scripts/build.sh
codesign --verify --strict --verbose=2 dist/ScreenInk.app
```

For UI/input changes, also run the relevant [manual checks](docs/TESTING.md), especially returning to normal clicks and quitting. Include macOS/Xcode versions, architecture and display setup in the PR. Mark checks you could not perform as unverified.

## Submit a pull request

Commit only the intended files, push your branch to your fork, then open a pull request targeting this repository's `main`. Describe the problem, the resulting behavior and verification performed. Include a small screenshot or recording when it helps demonstrate a UI change. Do not upload private desktop content.

Maintainers may ask for narrower scope or additional verification. Keep discussion respectful and focused on the work. Do not add speculative tests, refactors or unrelated features to a small fix.

## Good starting points

- Reproduce and document toolbar hover/drag and normal-mode behavior.
- Verify the current app on another macOS version or display configuration.
- Improve accessibility labels and beginner documentation.
- Reproduce and isolate the current Screen Recording permission failure without weakening macOS privacy controls.
- Complete fullscreen, Spaces, physical display reconnect and long-session checks on additional Macs.
- Exercise `scripts/package-release.sh` with a real Developer ID/notarization setup without committing credentials.

These are suggestions, not claims that GitHub issues have already been created or assigned.

## License

By submitting a contribution, you agree that it is provided under the repository's [MIT License](LICENSE). Only contribute work you have the right to submit, and preserve third-party attribution and license notices where applicable.
