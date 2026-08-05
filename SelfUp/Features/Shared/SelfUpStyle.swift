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

// MARK: - Gen Z Bento & Cyber Card Modifiers
struct BentoCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.primary.opacity(0.12), Color.primary.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}

struct CyberGlowingCardModifier: ViewModifier {
    var glowColor: Color
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: glowColor.opacity(0.25), radius: 18, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [glowColor.opacity(0.8), glowColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
    }
}

struct NeonGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var neonTint: Color
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: neonTint.opacity(0.2), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [neonTint.opacity(0.6), neonTint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}

extension View {
    func bentoCard(cornerRadius: CGFloat = 22) -> some View {
        self.modifier(BentoCardModifier(cornerRadius: cornerRadius))
    }
    
    func premiumCard(cornerRadius: CGFloat = 22) -> some View {
        self.modifier(BentoCardModifier(cornerRadius: cornerRadius))
    }
    
    func glassCard(cornerRadius: CGFloat = 22) -> some View {
        self.modifier(NeonGlassCardModifier(cornerRadius: cornerRadius, neonTint: SelfUpStyle.primaryIndigo))
    }
    
    func glowingCard(color: Color, cornerRadius: CGFloat = 22) -> some View {
        self.modifier(CyberGlowingCardModifier(glowColor: color, cornerRadius: cornerRadius))
    }
    
    func cyberGlowingCard(color: Color, cornerRadius: CGFloat = 22) -> some View {
        self.modifier(CyberGlowingCardModifier(glowColor: color, cornerRadius: cornerRadius))
    }
    
    func pressableScale(scale: CGFloat = 0.94) -> some View {
        self.buttonStyle(PressableScaleStyle(scale: scale))
    }
}

// MARK: - Gen Z Electric Design System Tokens & Gradients
enum SelfUpStyle {
    // Electric Gen Z Color Tokens
    static let primaryIndigo = Color(red: 0.45, green: 0.35, blue: 0.98) // Electric Violet Indigo
    static let cyberLime = Color(red: 0.52, green: 0.88, blue: 0.12)     // #84CC16
    static let hyperMagenta = Color(red: 0.93, green: 0.28, blue: 0.60)   // #EC4899
    static let cyberCyan = Color(red: 0.04, green: 0.76, blue: 0.96)      // #06B6D4
    static let neonGold = Color(red: 0.98, green: 0.72, blue: 0.08)       // #FACC15
    static let accentTeal = Color(red: 0.08, green: 0.82, blue: 0.68)
    static let rewardGold = Color(red: 0.98, green: 0.65, blue: 0.08)
    
    // Gen Z Dynamic Gradients
    static let cyberGradient = AngularGradient(
        colors: [cyberLime, primaryIndigo, hyperMagenta, cyberCyan, cyberLime],
        center: .center
    )
    
    static let lifeScoreGradient = AngularGradient(
        colors: [cyberLime, primaryIndigo, hyperMagenta, cyberLime],
        center: .center
    )
    
    static let heroGradient = LinearGradient(
        colors: [primaryIndigo, hyperMagenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let electricLimeGradient = LinearGradient(
        colors: [cyberLime, Color(red: 0.1, green: 0.75, blue: 0.4)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let goldGradient = LinearGradient(
        colors: [neonGold, Color(red: 0.98, green: 0.45, blue: 0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let incomeGradient = LinearGradient(
        colors: [cyberLime, Color.emerald],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let expenseGradient = LinearGradient(
        colors: [hyperMagenta, Color.coral],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let progressGradient = LinearGradient(
        colors: [cyberLime, primaryIndigo, hyperMagenta],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let darkCardGradient = LinearGradient(
        colors: [Color(red: 0.09, green: 0.09, blue: 0.12), Color(red: 0.05, green: 0.05, blue: 0.07)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    static let emerald = Color(red: 0.10, green: 0.80, blue: 0.46)
    static let coral = Color(red: 0.95, green: 0.32, blue: 0.45)
    static let darkGray = Color(white: 0.12)
}


