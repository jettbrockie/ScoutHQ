import SwiftUI

struct AIScoutingReportView: View {
    @ObservedObject var viewModel: PlayerViewModel
    let player: Player

    var body: some View {
        VStack(spacing: ScoutSpacing.xl) {
            if viewModel.isLoadingAI {
                aiLoadingView
            } else if let report = viewModel.aiReport {
                aiReportContent(report: report)
            } else {
                EmptyStateView(
                    icon: "sparkles",
                    title: "No AI Report Yet",
                    message: "Submit a scouting report to help generate the AI analysis for this player.",
                    actionTitle: "Generate Report",
                    action: {
                        Task { await viewModel.loadAIReport(playerId: player.id ?? "") }
                    }
                )
            }
        }
        .padding(.top, ScoutSpacing.lg)
        .padding(.horizontal, ScoutSpacing.lg)
    }

    // MARK: - Loading
    private var aiLoadingView: some View {
        VStack(spacing: ScoutSpacing.xl) {
            // Animated AI icon
            ZStack {
                Circle()
                    .fill(Color.scoutAccent.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundColor(.scoutAccent)
                    .symbolEffect(.variableColor.iterative)
            }
            Text("Generating AI Scouting Report...")
                .font(ScoutFont.headline)
                .fontWeight(.semibold)
            Text("Analyzing \(viewModel.reports.count) community reports")
                .font(ScoutFont.subheadline)
                .foregroundColor(.secondary)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .scoutAccent))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Report Content
    private func aiReportContent(report: AIScoutReport) -> some View {
        VStack(spacing: ScoutSpacing.xl) {
            // AI Header Badge
            aiHeaderBadge(report: report)

            // Overall Rating
            overallRatingCard(report: report)

            // Strengths
            strengthsCard(report: report)

            // Weaknesses
            weaknessesCard(report: report)

            // Playstyle Summary
            playstyleCard(report: report)

            // Player Comparison
            comparisonCard(report: report)

            // Key Attributes
            if !report.keyAttributes.isEmpty {
                attributesCard(report: report)
            }

            // Footer
            aiFooter(report: report)
                .padding(.bottom, ScoutSpacing.lg)
        }
    }

    private func aiHeaderBadge(report: AIScoutReport) -> some View {
        HStack(spacing: ScoutSpacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.scoutAccent)
            Text("AI-Generated Scouting Report")
                .font(ScoutFont.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.scoutAccent)
            Spacer()
            Text("Based on \(report.reportCount) reports")
                .font(ScoutFont.caption)
                .foregroundColor(.secondary)
        }
        .padding(ScoutSpacing.md)
        .background(Color.scoutAccent.opacity(0.1))
        .cornerRadius(ScoutRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: ScoutRadius.sm)
                .stroke(Color.scoutAccent.opacity(0.3), lineWidth: 1)
        )
    }

    private func overallRatingCard(report: AIScoutReport) -> some View {
        HStack(spacing: ScoutSpacing.xl) {
            RatingCircle(rating: report.overallRating, size: 90, lineWidth: 7)

            VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                Text("Consensus Rating")
                    .font(ScoutFont.caption)
                    .foregroundColor(.secondary)
                Text(report.overallRating.ratingString)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                GradeBadge(grade: player.ratingGrade, large: true)
            }

            Spacer()
        }
        .padding(ScoutSpacing.lg)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.lg)
    }

    private func strengthsCard(report: AIScoutReport) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
                Text("Key Strengths")
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                ForEach(report.strengths, id: \.self) { strength in
                    HStack(alignment: .top, spacing: ScoutSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .padding(.top, 2)
                        Text(strength)
                            .font(ScoutFont.callout)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(ScoutSpacing.lg)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.lg)
    }

    private func weaknessesCard(report: AIScoutReport) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                Text("Areas to Improve")
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: ScoutSpacing.sm) {
                ForEach(report.weaknesses, id: \.self) { weakness in
                    HStack(alignment: .top, spacing: ScoutSpacing.sm) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                            .padding(.top, 2)
                        Text(weakness)
                            .font(ScoutFont.callout)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(ScoutSpacing.lg)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.lg)
    }

    private func playstyleCard(report: AIScoutReport) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "doc.plaintext.fill")
                    .foregroundColor(.scoutAccent)
                Text("Play Style")
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
            }
            Text(report.playstyleSummary)
                .font(ScoutFont.callout)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(ScoutSpacing.lg)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.lg)
    }

    private func comparisonCard(report: AIScoutReport) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.purple)
                Text("Player Comparison")
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
            }
            HStack(spacing: ScoutSpacing.md) {
                // Current player
                comparisonPlayerBubble(name: player.name, label: "This Player", color: sportColor(for: player.sport))

                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.secondary)

                // Comparison
                comparisonPlayerBubble(name: report.comparison, label: "Plays Like", color: .purple)
            }
        }
        .padding(ScoutSpacing.lg)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.lg)
    }

    private func comparisonPlayerBubble(name: String, label: String, color: Color) -> some View {
        VStack(spacing: ScoutSpacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Text(String(name.prefix(2)).uppercased())
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(color)
            }
            Text(name)
                .font(ScoutFont.caption)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
            Text(label)
                .font(ScoutFont.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func attributesCard(report: AIScoutReport) -> some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.scoutGold)
                Text("Key Attributes")
                    .font(ScoutFont.headline)
                    .fontWeight(.bold)
            }

            VStack(spacing: ScoutSpacing.sm) {
                ForEach(report.keyAttributes.sorted(by: { $0.value > $1.value }), id: \.key) { attr in
                    AttributeRatingBar(label: attr.key, value: attr.value)
                }
            }
        }
        .padding(ScoutSpacing.lg)
        .background(Color.scoutSurface)
        .cornerRadius(ScoutRadius.lg)
    }

    private func aiFooter(report: AIScoutReport) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text("Generated \(report.generatedAt.relativeString)")
                    .font(ScoutFont.caption2)
            }
            .foregroundColor(.secondary)
            Text("Report updates automatically as new scouting data is submitted.")
                .font(ScoutFont.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
