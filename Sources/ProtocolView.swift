import SwiftUI

struct ProtocolView: View {
    @EnvironmentObject private var engine: DNAEngine
    var report: AnalysisReport { engine.report! }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                DisclaimerBanner()
                
                // Time-context research prompts
                chronoScheduleSection
                
                // Nutrient evidence topics
                supplementMatrixSection
                
                // General research associations
                pillarProtocolSection
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Lifestyle Evidence Notebook")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text("RESEARCH PROMPTS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.gold)
            }
            Text("Neutral questions and evidence topics linked to observed catalog markers. No genotype-directed schedule, supplement, restriction, or treatment is produced.")
                .font(.subheadline)
                .foregroundStyle(Theme.textMed)
        }
    }

    private var chronoScheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("⏰ Time-Context Research Questions")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text("5 Time Blocks")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.teal)
            }

            ForEach(ChronoTimeSlot.allCases) { slot in
                let items = report.chronoSchedule.filter { $0.slot == slot }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: slot.systemImage)
                                .font(.subheadline)
                                .foregroundStyle(Theme.gold)
                            Text(slot.shortTitle)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.textHi)
                        }
                        .padding(.bottom, 2)

                        ForEach(items) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: item.pillar.systemImage)
                                    .foregroundStyle(Theme.teal)
                                    .frame(width: 20)
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.title)
                                            .font(.callout.weight(.semibold))
                                            .foregroundStyle(Theme.textHi)
                                        Spacer()
                                        Text(item.pillar.title)
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Theme.gold)
                                    }
                                    Text(item.rationale)
                                        .font(.caption)
                                        .foregroundStyle(Theme.textMed)
                                }
                            }
                            .padding(10)
                            .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .dnaCard()
                }
            }
        }
    }

    private var supplementMatrixSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🧬 Nutrient Evidence Topics")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text("\(report.supplementMatrix.recommended.count) Topics")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.success)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("NO PRODUCT, AMOUNT, OR SCHEDULE INFERRED")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.success)

                ForEach(report.supplementMatrix.recommended) { rec in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(rec.nutrientName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.textHi)
                            Spacer()
                            Text(rec.evidence.label)
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Theme.teal)
                        }

                        Text("Evidence frame: **\(rec.preferredForm)**")
                            .font(.caption)
                            .foregroundStyle(Theme.teal)

                        Text(rec.reason)
                            .font(.caption)
                            .foregroundStyle(Theme.textMed)

                        HStack {
                            Text(rec.dosageContext)
                                .font(.caption2)
                                .foregroundStyle(Theme.textLow)
                            Spacer()
                            Text(rec.timing)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    .dnaCard()
                }
            }

        }
    }

    private var pillarProtocolSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Research Associations by Context")
                .font(.headline)
                .foregroundStyle(Theme.textHi)

            ForEach(LifestylePillar.allCases) { pillar in
                let items = report.protocolItems.filter { $0.pillar == pillar }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: pillar.systemImage)
                                .foregroundStyle(Theme.teal)
                            Text(pillar.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.textHi)
                            Spacer()
                            Text("\(items.count) Topics")
                                .font(.caption2.monospaced())
                                .foregroundStyle(Theme.textLow)
                        }

                        ForEach(items.prefix(4)) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("• \(item.title)")
                                    .font(.callout.weight(.medium))
                                    .foregroundStyle(Theme.textHi)
                                Text(item.reason)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textMed)
                                    .padding(.leading, 10)
                            }
                        }
                    }
                    .dnaCard()
                }
            }
        }
    }
}
