# Release ScreenInk

This guide separates local test archives from public macOS distribution. A local archive is useful for smoke testing on the build Mac. A public download must use an Apple Developer ID Application certificate and notarization so Gatekeeper can verify its origin.

## Create a local test archive

From the repository root:

```bash
bash scripts/test.sh
bash scripts/package-release.sh
```

The script rebuilds and verifies `dist/ScreenInk.app`, then writes a versioned ZIP and SHA-256 checksum under `dist/release`. The archive uses the host architecture. This default path may be ad-hoc signed and must not be described as a notarized public release.

Verify the checksum before testing the archive:

```bash
cd dist/release
shasum -a 256 -c ScreenInk-*.zip.sha256
```

Extract the ZIP, move ScreenInk to Applications, launch it and complete the manual checklist in [TESTING.md](TESTING.md). Test on a separate macOS user or clean Mac before publishing.

## Prepare Apple distribution signing

Public distribution requires an active Apple Developer Program membership and a Developer ID Application certificate installed in the login keychain. List available identities with:

```bash
security find-identity -v -p codesigning
```

Set the exact identity name for the build:

```bash
export SCREENINK_SIGNING_IDENTITY="Developer ID Application: Example Name (TEAMID)"
```

Create a `notarytool` keychain profile using Apple's documented App Store Connect credentials. Keep certificate material, passwords, API keys and the profile out of Git.

## Build, notarize and package

After configuring the signing identity and keychain profile:

```bash
export REQUIRE_DISTRIBUTION_SIGNATURE=1
export SCREENINK_NOTARY_PROFILE="screenink-notary"
bash scripts/test.sh
bash scripts/package-release.sh
```

Public mode refuses to package an app unless its signature contains a Developer ID Application authority. When a notary profile is provided, the script submits the app archive to Apple, waits for the result, staples the ticket, validates it and creates the final ZIP plus checksum.

Before creating a GitHub release, verify the extracted app on a clean Mac, confirm Gatekeeper accepts it, exercise normal click-through and drawing, and record the tested macOS version, architecture and display setup. Upload the final ZIP and matching `.sha256` file together.

The bundled `Resources/AppIcon.icns` is copied into every app build and referenced by `CFBundleIconFile`. Keep the high-resolution `Resources/AppIcon.png` as the editable master. If the artwork changes, regenerate every standard macOS icon size and rebuild the `.icns` file before packaging.
