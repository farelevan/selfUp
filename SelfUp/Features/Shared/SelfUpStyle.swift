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

// MARK: - Surface System
// A restrained surface treatment keeps information hierarchy clear without
// relying on decorative glow, gradients, or saturated borders.
struct PremiumCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
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
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
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
                    .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
            )
    }
}

// Legacy modifier names are retained so feature views can migrate gradually.
struct BentoCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
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
                    .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
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
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
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

// MARK: - Professional Design Tokens
enum SelfUpStyle {
    static let primaryIndigo = Color(red: 0.18, green: 0.31, blue: 0.55)
    static let cyberLime = Color(red: 0.16, green: 0.56, blue: 0.38)
    static let hyperMagenta = Color(red: 0.72, green: 0.25, blue: 0.29)
    static let cyberCyan = Color(red: 0.16, green: 0.47, blue: 0.61)
    static let neonGold = Color(red: 0.68, green: 0.48, blue: 0.14)
    static let accentTeal = Color(red: 0.12, green: 0.48, blue: 0.45)
    static let rewardGold = Color(red: 0.68, green: 0.48, blue: 0.14)
    
    // Kept as gradients for API compatibility, but deliberately low-contrast.
    static let cyberGradient = AngularGradient(
        colors: [primaryIndigo, cyberCyan, primaryIndigo],
        center: .center
    )
    
    static let lifeScoreGradient = AngularGradient(
        colors: [primaryIndigo, cyberCyan, primaryIndigo],
        center: .center
    )
    
    static let heroGradient = LinearGradient(
        colors: [primaryIndigo, Color(red: 0.24, green: 0.39, blue: 0.64)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let electricLimeGradient = LinearGradient(
        colors: [cyberLime, cyberLime.opacity(0.82)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let goldGradient = LinearGradient(
        colors: [neonGold, Color(red: 0.55, green: 0.37, blue: 0.10)],
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
        colors: [primaryIndigo, cyberCyan],
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
    static let emerald = Color(red: 0.16, green: 0.56, blue: 0.38)
    static let coral = Color(red: 0.72, green: 0.25, blue: 0.29)
    static let darkGray = Color(white: 0.12)
}

// MARK: - Completion Motion
struct CompletionMotionView: View {
    var color: Color = SelfUpStyle.cyberLime
    var compact = false

    @State private var progress: CGFloat = 0
    @State private var checkScale: CGFloat = 0.35

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(1 - progress), lineWidth: compact ? 2 : 4)
                .frame(width: compact ? 34 : 76, height: compact ? 34 : 76)
                .scaleEffect(0.55 + progress * 1.15)

            ForEach(0..<10, id: \.self) { index in
                let angle = Double(index) / 10 * Double.pi * 2
                Capsule()
                    .fill(index.isMultiple(of: 2) ? color : SelfUpStyle.primaryIndigo)
                    .frame(width: compact ? 3 : 5, height: compact ? 7 : 12)
                    .offset(
                        x: cos(angle) * progress * (compact ? 29 : 64),
                        y: sin(angle) * progress * (compact ? 29 : 64)
                    )
                    .rotationEffect(.radians(angle + Double.pi / 2))
                    .opacity(1 - progress)
            }

            Image(systemName: "checkmark")
                .font(.system(size: compact ? 12 : 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: compact ? 28 : 58, height: compact ? 28 : 58)
                .background(Circle().fill(color))
                .scaleEffect(checkScale)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.58)) {
                checkScale = 1
            }
            withAnimation(.easeOut(duration: 0.72)) {
                progress = 1
            }
        }
        .accessibilityHidden(true)
    }
}
