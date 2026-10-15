import SwiftUI

enum AppPalette {
    static let background = Color(red: 0.025, green: 0.055, blue: 0.065)
    static let panel = Color(red: 0.07, green: 0.12, blue: 0.13)
    static let panelLight = Color(red: 0.10, green: 0.18, blue: 0.18)
    static let mint = Color(red: 0.46, green: 0.91, blue: 0.72)
    static let mintBright = Color(red: 0.65, green: 1.0, blue: 0.80)
    static let lime = Color(red: 0.78, green: 0.90, blue: 0.36)
    static let sand = Color(red: 0.91, green: 0.74, blue: 0.42)
    static let muted = Color(red: 0.53, green: 0.65, blue: 0.63)
    static let soil = Color(red: 0.11, green: 0.16, blue: 0.15)
    static let root = Color(red: 0.82, green: 0.68, blue: 0.42)
}

struct CapsuleLabel: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1.1)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }
}

extension Double {
    func compactString(decimals: Int = 1) -> String {
        if self >= 1000 {
            return String(format: "%.1fk", self / 1000)
        }

        return String(format: "%.\(decimals)f", self)
    }
}