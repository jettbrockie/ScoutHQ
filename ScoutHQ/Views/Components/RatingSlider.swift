import SwiftUI

// MARK: - Custom Rating Slider
struct RatingSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 1...100
    var label: String = "Rating"
    var showGrade = true

    private var grade: String {
        switch value {
        case 90...100: return "A+"
        case 85..<90: return "A"
        case 80..<85: return "A-"
        case 75..<80: return "B+"
        case 70..<75: return "B"
        case 65..<70: return "B-"
        case 60..<65: return "C+"
        default: return "C"
        }
    }

    private var gradeColor: Color {
        switch value {
        case 90...100: return Color(red: 1.0, green: 0.82, blue: 0.2)
        case 80..<90: return Color.scoutAccent
        case 70..<80: return Color.green
        default: return Color.gray
        }
    }

    var body: some View {
        VStack(spacing: ScoutSpacing.sm) {
            HStack {
                Text(label)
                    .font(ScoutFont.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    Text(String(format: "%.0f", value))
                        .font(ScoutFont.statNumber)
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                        .animation(.none, value: value)
                    if showGrade {
                        Text(grade)
                            .font(ScoutFont.headline)
                            .fontWeight(.black)
                            .foregroundColor(gradeColor)
                            .frame(width: 36, height: 32)
                            .background(gradeColor.opacity(0.15))
                            .cornerRadius(6)
                            .animation(.none, value: value)
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 12)

                    // Filled track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: trackColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(12, geo.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))),
                               height: 12)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(gradeColor, lineWidth: 3)
                        )
                        .offset(x: max(0, geo.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) - 12))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let newValue = range.lowerBound + Double(drag.location.x / geo.size.width) * (range.upperBound - range.lowerBound)
                            let clamped = max(range.lowerBound, min(range.upperBound, newValue))
                            if abs(clamped - value) > 0.5 {
                                HapticFeedback.selection()
                            }
                            value = clamped
                        }
                )
            }
            .frame(height: 24)
        }
    }

    private var trackColors: [Color] {
        [
            Color(red: 0.85, green: 0.2, blue: 0.2),
            Color(red: 0.95, green: 0.6, blue: 0.1),
            Color.green,
            Color.scoutAccent,
            Color(red: 1.0, green: 0.82, blue: 0.2)
        ]
    }
}

// MARK: - Attribute Rating Bar
struct AttributeRatingBar: View {
    let label: String
    let value: Double // 0-100
    var color: Color = .scoutAccent

    var body: some View {
        HStack(spacing: ScoutSpacing.md) {
            Text(label)
                .font(ScoutFont.caption)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(attributeColor)
                        .frame(width: geo.size.width * (value / 100), height: 8)
                        .animation(.easeOut(duration: 0.8), value: value)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.0f", value))
                .font(ScoutFont.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private var attributeColor: Color {
        switch value {
        case 90...100: return Color(red: 1.0, green: 0.82, blue: 0.2)
        case 80..<90: return .scoutAccent
        case 70..<80: return .green
        default: return .gray
        }
    }
}

// MARK: - Star Rating Display
struct StarRating: View {
    let rating: Double // 0-5 scale
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: starName(for: index))
                    .font(.system(size: size))
                    .foregroundColor(.scoutGold)
            }
        }
    }

    private func starName(for index: Int) -> String {
        let threshold = Double(index) + 1
        if rating >= threshold { return "star.fill" }
        if rating >= threshold - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - Rating Distribution Chart
struct RatingDistributionChart: View {
    let distribution: [Double] // Array of 5 percentages (0...1)
    let labels = ["C", "B-", "B", "A-", "A+"]

    var body: some View {
        VStack(alignment: .leading, spacing: ScoutSpacing.xs) {
            Text("Rating Distribution")
                .font(ScoutFont.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(zip(distribution.indices, distribution)), id: \.0) { index, value in
                    VStack(spacing: 3) {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barColor(for: index))
                                    .frame(height: max(4, geo.size.height * value))
                            }
                        }
                        Text(labels[safe: index] ?? "")
                            .font(ScoutFont.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 60)
        }
    }

    private func barColor(for index: Int) -> Color {
        switch index {
        case 4: return Color(red: 1.0, green: 0.82, blue: 0.2)
        case 3: return .scoutAccent
        case 2: return .green
        case 1: return Color.orange
        default: return .gray
        }
    }
}
