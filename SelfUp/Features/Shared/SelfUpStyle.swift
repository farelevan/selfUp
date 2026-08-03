import SwiftUI

struct PremiumCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

extension View {
    func premiumCard(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(PremiumCardModifier(cornerRadius: cornerRadius))
    }
}

enum SelfUpStyle {
    static let lifeScoreGradient = AngularGradient(
        colors: [Color.blue, Color.teal, Color.green, Color.blue],
        center: .center
    )
    
    static let goldGradient = LinearGradient(
        colors: [Color.yellow, Color.orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let incomeGradient = LinearGradient(
        colors: [Color.emerald, Color.teal],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let expenseGradient = LinearGradient(
        colors: [Color.red, Color.orange],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let progressGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .leading,
        endPoint: .trailing
    )
}

extension Color {
    static let emerald = Color(red: 0.05, green: 0.75, blue: 0.45)
    static let darkGray = Color(white: 0.15)
}
