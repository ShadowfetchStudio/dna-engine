# Packaging drafts

Files here are **not published** anywhere. They are starting points for later
distribution work.

## Homebrew cask

[`homebrew/dna-engine.rb`](homebrew/dna-engine.rb) is a draft cask for a future
tap or `homebrew/cask` PR. It is not installed by this repository and is not
submitted to Homebrew.

After the first GitHub Release exists:

1. Set `version` to the tag without the `v` prefix (example: `1.0.0`).
2. Replace `sha256 :no_check` with the digest from `DNA-Engine-<version>.dmg.sha256`.
3. Confirm the DMG URL matches the asset name produced by
   `.github/workflows/release.yml` (`DNA-Engine-<version>.dmg`).

## Cutting a GitHub Release

The workflow runs on `vMAJOR.MINOR.PATCH` tags and on **Actions → Release →
Run workflow**.

```bash
# Example first public tag. Align VERSION / BUILD_NUMBER first if you want the
# bundle metadata to match the tag (the workflow stamps the tag version).
git tag -a v1.0.0 -m "DNA Engine 1.0.0"
git push origin v1.0.0
```

### Secrets for signed + notarized builds

Add these under **Settings → Secrets and variables → Actions**. If the
certificate pair is missing, the workflow still publishes an **unsigned** DMG
and says so in the release notes.

**Signing (required for Developer ID):**

| Secret | Contents |
|---|---|
| `MACOS_CERTIFICATE_P12_BASE64` | Developer ID Application `.p12`, base64 (`base64 -i cert.p12 \| pbcopy`) |
| `MACOS_CERTIFICATE_PASSWORD` | Password for that `.p12` |
| `MACOS_CERTIFICATE_IDENTITY` | Optional exact identity string |

**Notarization — App Store Connect API key (preferred):**

| Secret | Contents |
|---|---|
| `APP_STORE_CONNECT_API_KEY_P8_BASE64` | `AuthKey_<id>.p8` (base64 or raw PEM) |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer UUID |

**Notarization — Apple ID fallback:**

| Secret | Contents |
|---|---|
| `APPLE_ID` | Apple ID email |
| `APPLE_TEAM_ID` | 10-character Team ID |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from appleid.apple.com |
