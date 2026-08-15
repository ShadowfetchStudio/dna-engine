# DNA Engine 3.0.0 — Release Notes

- Version: **3.0.0**
- Build: **4**
- Scope: **fully offline, local-only genomics workbench — research & educational use**

These notes describe the 3.0 source release. They do not claim an App Store submission, public deployment, notarization upload, or installation on any particular Mac.

## Private workspace

- Added an AES-256-GCM authenticated `workspace.dnavault` envelope containing the exact original source bytes and import metadata.
- Added a random 256-bit, non-synchronizing `WhenUnlockedThisDeviceOnly` Keychain key.
- Added atomic `0700` directory / `0600` file persistence with authenticated final-file round-trip verification.
- Existing plaintext workspace migration removes the legacy source only after encrypted verification succeeds; a failed migration preserves it.
- Added encrypted workspace, memory-only private session, and memory-only synthetic demo modes.
- Made the second concordance file memory-only.
- Added configurable inactivity clear (Never, 5, 15, 30, or 60 minutes; default 15) and explicit clear/reload controls.

## Import integrity

- Replaced extension-driven shell decompression with native, content-signature gzip/ZIP detection.
- Added 256 MiB input, 768 MiB expanded-output, and 200× expansion-ratio limits.
- Added strict single-regular-member ZIP validation for stored and DEFLATE members, with CRC/bounds/header/termination checks and fail-closed rejection of unsafe archive features.
- Added an in-memory parser entry point so encrypted restore creates no plaintext temporary file.
- Added VCF `FORMAT`-aware `GT` indexing, sample-name accounting, diploid phased/unphased SNP support, and explicit rejection of unsupported ploidy, indels, multiallelic rows, filters, malformed rows, duplicates, and conflicts.
- Added a visible import receipt whose totals reconcile accepted and rejected record outcomes.

The current app picker defaults a multisample VCF to its first sample and records that fact. Explicit sample selection exists in the parser API but is not yet a picker control.

## Scientific scope corrections

- Palindromic A/T and C/G definitions now fail closed as strand unresolved across marker, compound, PGx, and downstream surfaces.
- PGx now reports locus observations and published drug-gene source pairs only. It does not call star alleles, diplotypes, phenotypes, medication response, alerts, doses, or actions.
- Two-file comparison now reports raw autosomal genotype concordance and allele overlap only. Relationship and kinship inference were removed.
- Pathway maps now show coverage-aware research context without enzyme-rate, expression, concentration, flux, or outcome estimates.
- Lifestyle/supplement/protocol surfaces now use neutral research questions without genotype-selected products, amounts, restrictions, schedules, or treatment plans.
- The 2.1 two-tier 2,621-marker ancestry implementation remains intact, including seeded intervals, refusal floors, marker-use disclosure, ASJ/Southern-European joint fitting, LCT-cluster deduplication, and not-a-passport framing.

## Privacy, export, and erase

- PDF rendering now uses a nonpersistent WebKit data store, disables JavaScript, blocks external navigation, and remains cancellable.
- Export filenames now include time and randomness to prevent same-day overwrite; app-created report files use mode `0600`.
- Verified erase now cancels active work, clears in-process genomic state, invalidates stale workspace generations, deletes and independently re-enumerates app-support files, reports every failure/survivor, and deletes the Keychain key only after files verify empty.
- Reports copied outside the app-support directory remain the owner's responsibility.

## Evidence appendix disclosure

The current generated report deduplicates 497 `(identifier, note)` pairs:

- 147 numeric PMID-note pairs representing 90 distinct numeric PMID identifiers.
- 350 named registry-note pairs: 273 GWAS Catalog, 38 PharmGKB, 28 CPIC, and 11 ClinVar.

The build checks schema and exact counts. It does not independently live-verify every reference or scientific statement.

## Release engineering

- Explicit build-only mode is the normal safe release posture and never touches `/Applications`.
- Exactly one explicit mode is required: `BUILD_ONLY=1` or `INSTALL=1`.
- Added warnings-as-errors compilation, vault tests, input-manifest stability checks, required-link/architecture/resource/signature verification, hardened-runtime signing, checksum manifests, verified local backups, atomic install swap, and rollback on failed post-install verification.
- The release script performs no network upload, notarization, telemetry, or sales action — it builds, verifies, and (opt-in) installs locally only.

## Verification

```bash
./Tools/run_checks.sh
./Tools/run_vault_checks.sh
VERSION="$(<VERSION)" BUILD_NUMBER="$(<BUILD_NUMBER)" BUILD_ONLY=1 ./build.sh
```

Manual PDF QA requires a GUI run loop and should use only the synthetic demo. Installation is a separate, explicit owner action.
