import SwiftUI

struct StatusBadge: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color = Color.theme.accent) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .tracking(0.3)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    static func forCompetition(_ status: CompetitionStatus) -> StatusBadge {
        switch status {
        case .draft: StatusBadge("Draft", color: Color.theme.textSecondary)
        case .upcoming: StatusBadge("Upcoming", color: Color.theme.accentYellow)
        case .active: StatusBadge("Active", color: Color.theme.accentGreen)
        case .completed: StatusBadge("Completed", color: Color.theme.accentPurple)
        }
    }

    static func forMatch(_ status: MatchStatus) -> StatusBadge {
        switch status {
        case .scheduled: StatusBadge("Scheduled", color: Color.theme.textSecondary)
        case .inProgress: StatusBadge("Live", color: Color.theme.accentOrange)
        case .pendingReview: StatusBadge("Pending Review", color: Color.theme.accentYellow)
        case .completed: StatusBadge("Final", color: Color.theme.accentGreen)
        }
    }
}
