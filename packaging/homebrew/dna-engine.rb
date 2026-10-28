# frozen_string_literal: true

# DRAFT — not published to Homebrew.
# After the first GitHub Release exists, set `version` to that tag (no "v")
# and replace sha256 with the digest from DNA-Engine-<version>.dmg.sha256.

cask "dna-engine" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/ShadowfetchStudio/dna-engine/releases/download/v#{version}/DNA-Engine-#{version}.dmg"
  name "DNA Engine"
  desc "Offline, bring-your-own-DNA genomics workbench"
  homepage "https://github.com/ShadowfetchStudio/dna-engine"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "DNA Engine.app"

  zap trash: [
    "~/Library/Application Support/DNAEngine",
  ]

  caveats <<~EOS
    DNA Engine is for research and educational use only. It is not a medical
    device and does not diagnose, treat, or recommend clinical action.

    The app is fully offline: your genome is not uploaded. Encrypted workspace
    files live in ~/Library/Application Support/DNAEngine.

    This cask is a draft and is not published in homebrew/cask. Unsigned
    releases may require right-click → Open (or clearing Gatekeeper
    quarantine) on first launch.
  EOS
end
