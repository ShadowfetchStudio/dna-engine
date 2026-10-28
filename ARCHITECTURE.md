# DNA Engine 3.0 — Private Architecture

DNA Engine is a direct-`swiftc` SwiftUI macOS application with UI-free analysis engines, generated local resources, an encrypted single-workspace store, and no production networking API. It targets macOS 14 or later and is built as one app executable plus Apple system frameworks.

The product is private and research-oriented. Architecture must enforce, not merely label, these limits: no cloud path, no diagnostic or prescribing output, no inferred kinship, no guessed strand orientation, and no destructive replacement before validation succeeds.

## 1. Data flow and trust boundaries

```text
User-selected source bytes
        |
        v
GenomeSourceDecoder
  content signature + hard limits + archive validation
        |
        v
GenomeParser -----> immutable GenomeImportReceipt
  format + VCF sample + reconciled row outcomes
        |
        v
ParsedGenome -> GenomeStats -> AnalysisEngine -> AnalysisReport -> Views / ReportExport
        |
        +---- memory-only private session
        +---- memory-only synthetic demo
        +---- memory-only secondary concordance file
        |
        `---- encrypted workspace mode
                 |
                 v
        PrivateWorkspaceStore actor
                 |
                 v
        PrivateGenomeVault -> workspace.dnavault
          AES-256-GCM + ThisDeviceOnly Keychain key
```

Source bytes are parsed through `GenomeParser.parse(data:sourceName:options:)`; encrypted restore therefore needs no plaintext temporary file. A primary result is published only after parsing and analysis succeed. In encrypted mode, the new vault is also written, reopened, authenticated, and compared with the intended envelope before UI state changes.

## 2. Workspace security

### Versioned authenticated envelope

`PrivateVault.swift` defines two version layers:

- A five-byte external container header: `DNAV` magic plus container version.
- `PrivateGenomeEnvelope.schemaVersion` inside AES-GCM ciphertext.

The encrypted binary-plist envelope contains the original filename and extension, SHA-256 of the original source bytes, import date, vendor/build hints, parser/catalog versions, accepted/skipped counts, and the exact original payload. Except for magic and container version, metadata and source bytes are encrypted and authenticated together.

`KeychainPrivateVaultKeyProvider` creates a random 256-bit AES key only when sealing a new/replacement vault. The generic-password item uses service `ai.shadowfetch.dnaengine.private-vault`, account `workspace-master-key-v1`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, and `kSecAttrSynchronizable = false`. Opening an existing vault is load-only: a missing key is an explicit error and never causes silent replacement-key creation.

ThisDeviceOnly is intentional. There is no cloud escrow, password recovery, or automatic transfer to another Mac; loss of the Keychain item makes the ciphertext unreadable by design.

### Atomic, verified persistence

`PrivateGenomeVault.writeVerified`:

1. Rejects a non-file destination and an existing symlink/nonregular file.
2. Creates the support directory and enforces mode `0700`.
3. Seals with a fresh AES-GCM nonce.
4. Writes a same-directory mode-`0600` temporary file, synchronizes it, and atomically moves/replaces the destination.
5. Re-enforces `0600`, reloads the final ciphertext, authenticates/decrypts it, validates schema and payload hash, and compares the complete envelope.

Legacy `imported_genome.txt` migration validates/parses the source first and removes plaintext only after the encrypted final file passes authenticated round-trip verification. Failure preserves the legacy source unchanged.

### Serialized mutation and cancellation

`PrivateWorkspaceStore` is an actor. Each primary operation receives a UUID generation and monotonically increasing sequence. Stale generations cannot save after a newer operation or erase. Verified erase increments the sequence and clears the active generation before deleting data, preventing cancelled work from recreating the vault.

`DNAEngine` cancels prior primary, comparison, and PDF tasks when replacing or clearing work. Status/progress publication is generation-checked on the main actor. A failed import leaves the previous encrypted workspace unchanged.

### Memory-only modes and inactivity

Private session, synthetic demo, and secondary comparison payloads are not persisted by their flows. `clearSensitiveMemory` releases parsed genome, report, receipt, selections, and comparison state. `WorkspaceActivityMonitor` observes local input events; `App.swift` checks inactivity every 30 seconds and clears state at the configured threshold (Never, 5, 15, 30, or 60 minutes; default 15). The encrypted vault remains available for explicit reload.

This is lifecycle minimization, not a forensic secure-RAM-zeroization guarantee.

## 3. Bounded import pipeline

`GenomeImportFoundation.swift` owns source descriptors, immutable receipts, limits, content decoding, and archive validation. `GenomeParser.swift` owns text-format interpretation and record accounting. Both are Foundation/zlib-only and compile in the UI-free macOS 14 check CLI.

### Container detection and limits

Content magic identifies gzip and ZIP; extension is metadata and mismatch becomes a receipt notice. Standard limits are:

| Limit | Value |
|---|---:|
| Input bytes | 256 MiB |
| Expanded bytes | 768 MiB |
| Expansion ratio | 200× |
| Stored diagnostic examples | 25 |
| Minimum accepted calls | 500 |

Native zlib decoding checks output continuously against limits. Gzip requires a complete single stream with checksum/trailer validation and no concatenated tail.

The strict ZIP reader accepts exactly one safe regular member using stored or raw-DEFLATE compression. It validates EOCD/central/local bounds, entry counts, flags, methods, filenames, extra fields, data descriptors, sizes, CRC, and end position. ZIP64, multi-disk, encrypted/AES, patched, masked, multi-entry, special-file, path-traversal, corrupt, concatenated, or unsafe-ratio inputs are explicit errors. The member is decoded in memory, never extracted.

### VCF semantics

The `#CHROM` header supplies sample names. `GenomeImportOptions.selectedVCFSample` supports an exact explicit name. Without one, the only sample is used or the first of multiple samples is selected with a visible notice; the current UI uses this default behavior.

Each row locates `GT` through `FORMAT`, then resolves only complete diploid `0`, `1`, and `.` alleles against single-base REF/ALT. Phased and unphased diploid SNPs are supported. Haploid/polyploid calls, allele indices beyond 1, indels, symbolic alleles, multiallelic records, non-`PASS`/`.` filters, malformed values, and unsupported identifiers are rejected rather than truncated.

`GenomeParseDiagnostics` reconciles:

```text
totalRecords = acceptedRecords + skippedRecords
skippedRecords = duplicateRecords + conflictRecords + malformedRecords + unsupportedRecords
```

`filteredRecords` is an audited subset of unsupported records. `noCallRecords` is a subset of accepted records so QC can see explicit no-calls. Duplicate calls are retained once; conflicting duplicates never replace the first accepted call.

## 4. Generated knowledge and evidence metadata

`Tools/generate_knowledge.py` is the sole producer of `Resources/knowledge.json`. Fourteen section modules under `Tools/knowledge_sections/` register marker definitions; shared lints require citation pointer, tier, effect, transferability, and expected-chip metadata. Dedicated lints cover compounds, PGx definitions, limitations, and demo pins. A deliberately broken fixture must fail, proving the lint path is active.

The current resource contains 403 markers, 30 multi-locus rule definitions, 14 PGx gene definitions, 15 polygenic panels, 36 legacy ancestry-informative markers, 17 static limitations, and 109 hand-pinned demo genotypes.

`ReportExport.dedupedCitations` combines marker and compound citation records by exact `(identifier, note)` pair. Current generated count:

| Kind | Unique identifier-note pairs |
|---|---:|
| Numeric PMID strings | 147 (90 distinct numeric IDs) |
| GWAS Catalog pointers | 273 |
| PharmGKB pointers | 38 |
| CPIC pointers | 28 |
| ClinVar pointers | 11 |
| **Total** | **497** |

The generator and harness enforce nonempty fields, exact deduplication, and count parity. They do not query PubMed or registries and therefore do not independently verify all 497 entries or their scientific claims.

## 5. Orientation and scientific fail-closed rules

`MarkerMatcher` permits direct or reverse-complement matching for resolvable definitions. A/T and C/G palindromic pairs are withheld as `.strandAmbiguous` before genotype interpretation. This rule also propagates into compound rules and PGx locus observations.

Core engines are deterministic and UI-free:

- `AnalysisEngine` orchestrates marker observations, rules, panels, ancestry, ROH, QC, pathway/lifestyle context, and limitations.
- `CompoundTraits` evaluates catalog rules with missingness/orientation gates; partial coverage is disclosed rather than filled in.
- `PharmacogenomicsEngine` emits locus-level observations and published drug-gene reference pairs. Compatibility fields remain structurally present but are fixed to indeterminate/typical; no star allele, diplotype, phenotype, medication response, alert, or action is inferred.
- `ComparisonEngine` reports direct raw autosomal genotype/allele overlap only. `RelationshipDegree` has only `.notInferred`; no IBD or kinship model exists.
- `PathwaysEngine` overlays coverage/status on static research maps and never computes activity, expression, concentration, flux, or outcome.
- `LifestyleEngine` produces neutral evidence questions; no genotype-selected product, amount, restriction, schedule, exercise plan, or treatment.
- `QCEngine` performs file forensics, including call quality, build sentinels, chip coverage, strand status, and sex-chromosome signal.
- `ROHScanner` reports observed-span homozygosity with qualified length-class context.
- `HonestyEngine` merges 17 static limitations with file-specific missingness, coverage, and QC limitations.

## 6. Ancestry subsystem retained from 2.1

`Tools/build_reference_panel.py` packages `Resources/reference_panel.json` from the validated staging panel. The packaged resource contains 2,621 markers and the 12 columns consumed at runtime: AFR, EUR, EAS, SAS, AMR, MID, NWE, TSI, IBS, FIN, ASJ, and NFE. Provenance notes survive packaging and appear in ancestry outputs.

`AdmixtureEngine` is the authoritative 2.1 two-tier supervised maximum-likelihood model:

1. Tier 1 fits AFR/EUR/EAS/SAS/AMR/MID with deterministic fixed-iteration EM.
2. Tier 2 fits NWE/TSI/IBS/FIN/ASJ on the within-European informative subset while holding non-European components at tier-1 values.
3. Seeded SplitMix64 marker bootstrap produces 95% intervals; refusal floors cover insufficient total, within-European, and founder-subset markers plus low European share.
4. Palindromic markers are dropped and counted. Every result discloses usable markers out of 2,621.
5. The ASJ-vs-NFE founder subset has 377 markers before LCT-cluster dedup and 375 packaged flags afterward. Its share/interval and supporting likelihood ratio are framed as reference-panel signals, never identity, religion, ethnicity, nationality, or passport status.

`AncestryEstimator` retains the older 36-AIM seven-population sketch as an explicitly labeled legacy model. The check harness independently reproduces the two primary EM fits and ASJ likelihood ratio in Python.

## 7. Views, reports, and offline PDF

`DNAEngine.swift` is the main-actor application model. `App.swift` supplies workspace commands, inactivity handling, and settings. SwiftUI views are renderers over `AnalysisReport`, `GenomeImportReceipt`, and workspace state.

`ReportExport.swift` emits Markdown, self-contained HTML, JSON, and the PGx research brief. Full reports always include the deduplicated reference appendix and the limitations appendix. Export names combine millisecond time and a UUID fragment; outputs use mode `0600`.

`OfflinePDFRenderer.swift` is the only WebKit rendering path. It uses `WKWebsiteDataStore.nonPersistent()`, disables content JavaScript and window opening, loads generated HTML with `baseURL: nil`, permits only the local `about:` document, rejects external navigation, supports cancellation, and releases the web view after completion. Generated HTML carries `default-src 'none'` CSP.

## 8. Erase contract

`AppPaths` centralizes persisted paths and enforces `0700` on app-owned directories. `LocalEraser.inventory()` is throwing so an enumeration failure cannot masquerade as empty.

`LocalEraser.eraseAllVerified()`:

1. Enumerates every current child under the app-support directory.
2. Attempts every deletion while retaining per-path errors.
3. Re-enumerates independently.
4. Returns survivors, failures, and `verifiedEmpty` only when both lists are empty.

`PrivateWorkspaceStore.eraseEverything()` invalidates active generations first. It deletes the Keychain key only after file verification is empty and reports key deletion failure separately. `DNAEngine.performVerifiedErase()` cancels in-flight work and clears app state before invoking the actor.

Any new persisted file must remain discoverable by live inventory and covered by erase tests. Copies the owner moves outside the app-support directory are deliberately outside the app's deletion authority.

## 9. Build and release gates

`build.sh` requires explicit `VERSION`, `BUILD_NUMBER`, and exactly one of `BUILD_ONLY=1` or `INSTALL=1`.

Both modes:

- Run `Tools/run_checks.sh` and isolated `Tools/run_vault_checks.sh` first.
- Self-test the atomic-swap helper.
- Snapshot hashes of release inputs before compilation and require the same hashes afterward.
- Compile every Swift source with optimization, whole-module optimization, and warnings as errors for arm64 plus x86_64 when the SDK supports it.
- Link only declared Apple frameworks and zlib.
- Sign with hardened runtime using an available local identity or ad-hoc fallback.
- Verify bundle ID, version/build, minimum OS, resources, exact architectures, required links, executable count, and strict code signature.
- Publish `build/DNA Engine.app` and a per-file SHA-256 manifest through verified staging.

Build-only mode never touches `/Applications`. Install mode is separately explicit, refuses a running app, stages and verifies the candidate, creates a verified local backup, atomically swaps the bundle, verifies again, and rolls back on failure.

`build.sh` itself performs no upload, notarization, or remote publication — it builds, verifies, and (opt-in) installs locally only. Optional GitHub Actions packaging (`.github/workflows/release.yml`) can attach a DMG to a GitHub Release when a version tag is pushed; that job is CI packaging only and does not add network, telemetry, or update code to the app.

## 10. Test harnesses

`Tools/run_checks.sh` compiles UI-free engines directly for macOS 14 and covers generated-resource lints, safe parser/archive/VCF receipts, determinism, scientific fail-closed expectations, independent ancestry and HWE recomputation, QC fixtures, citation recounting, report language gates, comparison scope, and sandboxed erase.

`Tools/run_vault_checks.sh` compiles `Paths`, `PrivateVault`, and `PrivateWorkspaceStore` with warnings as errors. It uses a temporary directory and injected keys—never the real Application Support directory or Keychain—to test nonce uniqueness, authentication/tamper/wrong-key failure, no key creation on open, `0700`/`0600` permissions, verified round trips, migration ordering, generation races, erase, and prevention of post-erase stale writes.

PDF rendering requires a GUI run loop and is manually checked with the synthetic demo during private release QA.

## 11. Catalog change workflow

1. Add the marker or definition to the correct `Tools/knowledge_sections/*.py` module.
2. Add real curation metadata: citation pointer, evidence tier, effect text, transferability, and expected chips.
3. Treat palindromic definitions as unresolvable until a separately validated orientation manifest exists; do not bypass the runtime fail-closed rule with a favorable expected allele.
4. Add a demo pin only when it is valid and useful for deterministic coverage.
5. Run both check suites.
6. If expected output changes intentionally, regenerate it only with `UPDATE_EXPECTED=1`, then review the complete diff.

Passing lints demonstrates structural completeness and deterministic behavior. It is not a substitute for human scientific review.
