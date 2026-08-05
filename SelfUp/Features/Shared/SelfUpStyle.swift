import SwiftUI
import UIKit

// MARK: - Haptics Helper
enum Haptics {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Pressable Button Style
struct PressableScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    Haptics.light()
                }
            }
    }
}

// MARK: - Card Modifiers
struct PremiumCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct GlowingCardModifier: ViewModifier {
    var glowColor: Color
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: glowColor.opacity(0.2), radius: 14, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(0.3), lineWidth: 1.5)
            )
    }
}

extension View {
    func premiumCard(cornerRadius: CGFloat = 18) -> some View {
        self.modifier(PremiumCardModifier(cornerRadius: cornerRadius))
    }
    
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    func glowingCard(color: Color, cornerRadius: CGFloat = 18) -> some View {
        self.modifier(GlowingCardModifier(glowColor: color, cornerRadius: cornerRadius))
    }
    
    func pressableScale(scale: CGFloat = 0.96) -> some View {
        self.buttonStyle(PressableScaleStyle(scale: scale))
    }
}

// MARK: - Design System Tokens & Gradients
enum SelfUpStyle {
    static let primaryIndigo = Color(red: 0.31, green: 0.27, blue: 0.90) // #4F46E5
    static let accentTeal = Color(red: 0.08, green: 0.72, blue: 0.65)
    static let rewardGold = Color(red: 0.96, green: 0.62, blue: 0.07)
    
    static let lifeScoreGradient = AngularGradient(
        colors: [Color.indigo, Color.teal, Color.emerald, Color.indigo],
        center: .center
    )
    
    static let heroGradient = LinearGradient(
        colors: [Color.indigo, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let goldGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.78, blue: 0.2), Color(red: 0.95, green: 0.5, blue: 0.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let incomeGradient = LinearGradient(
        colors: [Color.emerald, Color.teal],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let expenseGradient = LinearGradient(
        colors: [Color(red: 0.94, green: 0.27, blue: 0.27), Color.orange],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let progressGradient = LinearGradient(
        colors: [Color.indigo, Color.purple, Color.pink],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let darkCardGradient = LinearGradient(
        colors: [Color(white: 0.16), Color(white: 0.10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    static let emerald = Color(red: 0.06, green: 0.73, blue: 0.44)
    static let coral = Color(red: 0.95, green: 0.35, blue: 0.35)
    static let darkGray = Color(white: 0.15)
}

