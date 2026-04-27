# Release Process

Public releases are built by GitHub Actions when a version tag is pushed.

## GitHub Secrets

Configure these repository secrets before creating the first release:

- `MACOS_CERTIFICATE_P12`: base64-encoded export of the Developer ID Application certificate and private key.
- `MACOS_CERTIFICATE_PASSWORD`: password used when exporting the `.p12`.
- `DEVELOPER_ID_APPLICATION`: exact signing identity, for example `Developer ID Application: Your Name (TEAMID)`.
- `APPLE_API_KEY_ID`: App Store Connect API key ID.
- `APPLE_API_ISSUER_ID`: App Store Connect issuer ID.
- `APPLE_API_KEY_P8`: full contents of the App Store Connect API private key file.

To create the certificate secret from a local `.p12` file:

```sh
base64 -i DeveloperIDApplication.p12 | pbcopy
```

## Create a Release

1. Make sure the changelog or release notes are ready.
2. Push a semantic version tag:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The release workflow derives the app version from the tag. For `v0.1.0`, it builds:

- `CFBundleShortVersionString`: `0.1.0`
- `CFBundleVersion`: the GitHub Actions run number
- release artifact: `Function-Keys-0.1.0.dmg`

The workflow signs the app with Developer ID, notarizes and staples the app, creates a DMG, notarizes and staples the DMG, then publishes it to GitHub Releases.
