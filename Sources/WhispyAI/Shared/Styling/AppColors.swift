import SwiftUI

enum AppColors {
    static let deep    = Color(red: 0.04, green: 0.12, blue: 0.30)
    static let dark    = Color(red: 0.08, green: 0.22, blue: 0.50)
    static let mid     = Color(red: 0.15, green: 0.40, blue: 0.75)
    static let bright  = Color(red: 0.25, green: 0.58, blue: 0.96)
    static let light   = Color(red: 0.65, green: 0.82, blue: 1.0)
    static let surface = Color.white.opacity(0.12)
    static let surfaceLight = Color.white.opacity(0.06)

    static let backgroundGradient = LinearGradient(
        colors: [AppColors.deep, AppColors.dark, AppColors.mid],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}