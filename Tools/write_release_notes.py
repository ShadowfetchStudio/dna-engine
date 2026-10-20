#!/usr/bin/env python3
"""Write GitHub Release notes for a DNA Engine DMG. No network I/O."""

from __future__ import annotations

import argparse
import pathlib
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--checksum-file", required=True)
    parser.add_argument("--signing", required=True, choices=("true", "false"))
    parser.add_argument("--notary", required=True, choices=("true", "false"))
    parser.add_argument("--status-file", help="Optional path to write the status token")
    return parser.parse_args()


def classify(signing: str, notary: str) -> tuple[str, str, str]:
    if signing == "true" and notary == "true":
        return (
            "signed-notarized",
            "Signed and notarized",
            (
                "This build is signed with a Developer ID Application certificate "
                "and notarized (the ticket is stapled to the DMG). macOS Gatekeeper "
                "should accept a normal double-click after you drag the app to Applications."
            ),
        )
    if signing == "true":
        return (
            "signed-not-notarized",
            "Signed, not notarized",
            (
                "This build is Developer ID–signed but was **not notarized** "
                "(App Store Connect / Apple ID secrets were not configured). "
                "Gatekeeper may still block first launch.\n"
                "\n"
                "If you trust this download: right-click **DNA Engine.app** → **Open**, "
                "or clear the quarantine flag you accepted:\n"
                "\n"
                "```bash\n"
                'xattr -dr com.apple.quarantine "/Applications/DNA Engine.app"\n'
                "```"
            ),
        )
    return (
        "unsigned",
        "UNSIGNED",
        (
            "**This release is unsigned.** Signing and notarization secrets were not "
            "configured on the repository, so the app is ad-hoc signed only. "
            "Gatekeeper will warn on first launch.\n"
            "\n"
            "If you trust this download:\n"
            "\n"
            "1. Right-click **DNA Engine.app** → **Open** (do not double-click).\n"
            "2. Or clear the quarantine attribute after you have inspected the file:\n"
            "\n"
            "```bash\n"
            'xattr -dr com.apple.quarantine "/Applications/DNA Engine.app"\n'
            "```"
        ),
    )


def main() -> int:
    args = parse_args()
    checksum = pathlib.Path(args.checksum_file).read_text(encoding="utf-8").split()[0]
    status, title, gatekeeper = classify(args.signing, args.notary)
    body = f"""## DNA Engine {args.version}

**Research and educational use only.** DNA Engine is not a medical device, a diagnostic assay, a clinical pharmacogenomics test, an ancestry-identity service, or a validated relationship test. It does not diagnose, treat, prescribe, or recommend a diet, supplement, medication, dose, or clinical action. See the [Science Contract](https://github.com/ShadowfetchStudio/dna-engine#the-science-contract).

### Signing status: {title}

{gatekeeper}

### Install

1. Download `DNA-Engine-{args.version}.dmg`.
2. Optional integrity check:

   ```bash
   shasum -a 256 -c DNA-Engine-{args.version}.dmg.sha256
   ```

   Expected SHA-256: `{checksum}`
3. Open the disk image and drag **DNA Engine** to Applications.

Requires **macOS 14 (Sonoma) or later** (Apple silicon or Intel).

### Privacy

The downloaded app is the same offline workbench as a source build: **no cloud, no account, no telemetry, no updater, no network code.** Your genome stays on your Mac. Encrypted workspace files live in `~/Library/Application Support/DNAEngine`.

<!-- release-status:{status} -->
"""
    output = pathlib.Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(body, encoding="utf-8")
    if args.status_file:
        pathlib.Path(args.status_file).write_text(status + "\n", encoding="utf-8")
    print(status)
    return 0


if __name__ == "__main__":
    sys.exit(main())
