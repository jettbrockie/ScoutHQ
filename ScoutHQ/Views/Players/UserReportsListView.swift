import SwiftUI

struct UserReportsListView: View {
    @ObservedObject var viewModel: PlayerViewModel
    let currentUserId: String

    var body: some View {
        VStack(spacing: ScoutSpacing.xl) {
            // Sort Header
            sortHeader
                .padding(.horizontal, ScoutSpacing.lg)

            if viewModel.isLoadingReports {
                LoadingView(message: "Loading reports...")
            } else if viewModel.reports.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Reports Yet",
                    message: "Be the first to submit a scouting report for this player!"
                )
            } else {
                VStack(spacing: ScoutSpacing.md) {
                    ForEach(viewModel.reports) { report in
                        ReportCard(
                            report: report,
                            currentUserId: currentUserId,
                            onVote: { vote in
                                Task {
                                    await viewModel.voteOnReport(report, vote: vote, userId: currentUserId)
                                }
                            }
                        )
                        .padding(.horizontal, ScoutSpacing.lg)
                    }
                }
                .padding(.bottom, ScoutSpacing.xl)
            }
        }
        .padding(.top, ScoutSpacing.lg)
    }

    private var sortHeader: some View {
        HStack {
            Text("\(viewModel.reports.count) Reports")
                .font(ScoutFont.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Spacer()

            Menu {
                ForEach(ReportSortOption.allCases, id: \.rawValue) { option in
                    Button {
                        viewModel.changeSortOption(option)
                        HapticFeedback.selection()
                    } label: {
                        Label(
                            option.rawValue,
                            systemImage: viewModel.sortOption == option ? "checkmark" : ""
                        )
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.sortOption.rawValue)
                        .font(ScoutFont.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.scoutAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.scoutAccent.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
}
