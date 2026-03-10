import SwiftUI

extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    // Backgrounds
    let background = Color(uiColor: .systemBackground)
    let surface = Color(uiColor: .secondarySystemGroupedBackground)
    let surfaceLight = Color(uiColor: .tertiarySystemGroupedBackground)
    let surfaceElevated = Color(uiColor: .tertiarySystemGroupedBackground)

    // Accents
    let accent = Color.accentColor
    let accentGreen = Color.green
    let accentRed = Color.red
    let accentYellow = Color.yellow
    let accentOrange = Color.orange
    let accentPurple = Color.purple

    // Text
    let textPrimary = Color.primary
    let textSecondary = Color.secondary
    let textTertiary = Color(uiColor: .tertiaryLabel)

    // Borders & Separators
    let border = Color(uiColor: .separator)
    let separator = Color(uiColor: .separator)

    // Brand
    let gold = Color(red: 200/255, green: 153/255, blue: 26/255)
    let goldLight = Color(red: 255/255, green: 233/255, blue: 154/255)
    let feltGreen = Color(red: 15/255, green: 74/255, blue: 52/255)
    let navy = Color(red: 13/255, green: 21/255, blue: 36/255)
    let navyDeep = Color(red: 7/255, green: 12/255, blue: 20/255)
}
