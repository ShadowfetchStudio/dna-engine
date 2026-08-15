import SwiftUI

enum Theme {
    static let bgDeep = Color(red: 0.020, green: 0.035, blue: 0.055)
    static let bgRaised = Color(red: 0.045, green: 0.065, blue: 0.095)
    static let bgCard = Color(red: 0.065, green: 0.095, blue: 0.135)
    static let bgCardHover = Color(red: 0.085, green: 0.125, blue: 0.175)
    static let bgInset = Color(red: 0.035, green: 0.050, blue: 0.075)
    static let stroke = Color.white.opacity(0.09)
    static let strokeActive = Color.white.opacity(0.18)
    
    static let textHi = Color(red: 0.94, green: 0.97, blue: 0.98)
    static let textMed = Color(red: 0.70, green: 0.78, blue: 0.83)
    static let textLow = Color(red: 0.45, green: 0.54, blue: 0.60)

    static let teal = Color(red: 0.22, green: 0.88, blue: 0.82)
    static let tealDim = Color(red: 0.16, green: 0.52, blue: 0.50)
    static let gold = Color(red: 0.94, green: 0.76, blue: 0.38)
    static let magenta = Color(red: 0.92, green: 0.40, blue: 0.68)
    static let blue = Color(red: 0.38, green: 0.65, blue: 0.98)
    static let purple = Color(red: 0.68, green: 0.48, blue: 0.98)
    static let success = Color(red: 0.35, green: 0.86, blue: 0.58)
    static let warning = Color(red: 0.98, green: 0.72, blue: 0.25)
    static let danger = Color(red: 0.95, green: 0.38, blue: 0.42)
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    var isHovered: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isHovered ? Theme.bgCardHover : Theme.bgCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func dnaCard(padding: CGFloat = 16) -> some View { modifier(CardStyle(padding: padding)) }
}

extension Impact {
    var color: Color {
        switch self {
        case .typical: return Theme.textMed
        case .advantageous: return Theme.success
        case .notable: return Theme.gold
        case .caution: return Theme.danger
        }
    }
}


