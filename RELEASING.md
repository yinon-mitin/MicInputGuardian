# Releasing

GitHub Actions creates a release automatically whenever a semantic-version tag such as `v1.0.0` is pushed.

## First release

1. Push the repository to GitHub with `main` as the default branch.
2. Open **Settings → Actions → General** and ensure Actions are enabled.
3. Merge the release workflow into `main` before creating the tag.
4. Create and push a tag:

   ```bash
   git tag -a v1.0.0 -m "Mic Input Guardian 1.0.0"
   git push origin v1.0.0
   ```

5. Follow the **Release** workflow in the repository's Actions tab.

The workflow tests the project on Apple Silicon and Intel runners, builds architecture-specific `.app` bundles, validates their signatures and metadata, creates ZIP archives and SHA-256 checksum files, and publishes them in a GitHub Release with generated notes.

## Signing modes

Without Apple credentials, the workflow publishes ad-hoc-signed apps. They are suitable for testing, but users may need to approve the app in **System Settings → Privacy & Security**.

For Developer ID signing, add these repository Actions secrets:

- `DEVELOPER_ID_APPLICATION_P12_BASE64`: base64-encoded Developer ID Application certificate and private key in `.p12` format.
- `DEVELOPER_ID_APPLICATION_P12_PASSWORD`: password used when exporting the `.p12` file.
- `DEVELOPER_ID_APPLICATION_IDENTITY`: full identity, for example `Developer ID Application: Example Name (TEAMID)`.

For notarization, also add:

- `APPLE_ID`: Apple ID used for notarization.
- `APPLE_TEAM_ID`: Apple Developer Team ID.
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for the Apple ID.

When all notarization secrets are available, the workflow submits each archive to Apple's notary service, waits for acceptance, staples the ticket to the app, and then creates the final release ZIP.

## Versioning

The leading `v` is removed from the Git tag and written to `CFBundleShortVersionString`. The GitHub Actions run number is written to `CFBundleVersion`.

Use semantic versions:

- `v1.0.1` for a bug fix
- `v1.1.0` for backward-compatible features
- `v2.0.0` for breaking behavior changes
