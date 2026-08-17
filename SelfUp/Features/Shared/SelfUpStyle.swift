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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Surface System
// A restrained surface treatment keeps information hierarchy clear without
// relying on decorative glow, gradients, or saturated borders.
struct AdaptiveCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var contentPadding: CGFloat = SelfUpStyle.Spacing.large
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(contentPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(
                        color: colorScheme == .light ? Color.black.opacity(0.035) : .clear,
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.55), lineWidth: 0.5)
            )
    }
}

// Legacy modifier types remain as thin wrappers so existing feature code and
// widgets can migrate without a source-breaking change.
struct PremiumCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
}

struct GlowingCardModifier: ViewModifier {
    var glowColor: Color
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
}

struct BentoCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
}

struct CyberGlowingCardModifier: ViewModifier {
    var glowColor: Color
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
}

struct NeonGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var neonTint: Color
    
    func body(content: Content) -> some View {
        content.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
}

extension View {
    func bentoCard(cornerRadius: CGFloat = 18) -> some View {
        self.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
    
    func premiumCard(cornerRadius: CGFloat = 18) -> some View {
        self.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
    
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        self.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
    
    func glowingCard(color: Color, cornerRadius: CGFloat = 18) -> some View {
        self.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
    
    func cyberGlowingCard(color: Color, cornerRadius: CGFloat = 18) -> some View {
        self.modifier(AdaptiveCardModifier(cornerRadius: cornerRadius))
    }
    
    func pressableScale(scale: CGFloat = 0.94) -> some View {
        self.buttonStyle(PressableScaleStyle(scale: scale))
    }
}

// MARK: - Professional Design Tokens
enum SelfUpStyle {
    enum Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let xxLarge: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 18
        static let large: CGFloat = 18
        static let pill: CGFloat = 999
    }

    enum Control {
        static let minimumTapTarget: CGFloat = 44
        static let compactIcon: CGFloat = 36
        static let regularIcon: CGFloat = 44
    }

    // Flat aliases support feature views while they migrate to grouped tokens.
    static let spacingSM = Spacing.small
    static let spacingMD = Spacing.medium
    static let spacingLG = Spacing.large
    static let spacingXL = Spacing.xLarge
    static let minimumControlSize = Control.minimumTapTarget

    private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let brand = adaptiveColor(
        light: UIColor(red: 30 / 255, green: 64 / 255, blue: 175 / 255, alpha: 1),
        dark: UIColor(red: 157 / 255, green: 185 / 255, blue: 255 / 255, alpha: 1)
    )
    static let brandFill = adaptiveColor(
        light: UIColor(red: 30 / 255, green: 64 / 255, blue: 175 / 255, alpha: 1),
        dark: UIColor(red: 49 / 255, green: 89 / 255, blue: 184 / 255, alpha: 1)
    )
    static let success = adaptiveColor(
        light: UIColor(red: 4 / 255, green: 120 / 255, blue: 87 / 255, alpha: 1),
        dark: UIColor(red: 110 / 255, green: 231 / 255, blue: 183 / 255, alpha: 1)
    )
    static let successFill = adaptiveColor(
        light: UIColor(red: 4 / 255, green: 120 / 255, blue: 87 / 255, alpha: 1),
        dark: UIColor(red: 4 / 255, green: 120 / 255, blue: 87 / 255, alpha: 1)
    )
    static let danger = adaptiveColor(
        light: UIColor(red: 185 / 255, green: 28 / 255, blue: 28 / 255, alpha: 1),
        dark: UIColor(red: 252 / 255, green: 165 / 255, blue: 165 / 255, alpha: 1)
    )
    static let dangerFill = adaptiveColor(
        light: UIColor(red: 185 / 255, green: 28 / 255, blue: 28 / 255, alpha: 1),
        dark: UIColor(red: 153 / 255, green: 27 / 255, blue: 27 / 255, alpha: 1)
    )
    static let warning = adaptiveColor(
        light: UIColor(red: 161 / 255, green: 98 / 255, blue: 7 / 255, alpha: 1),
        dark: UIColor(red: 252 / 255, green: 211 / 255, blue: 77 / 255, alpha: 1)
    )
    static let warningFill = adaptiveColor(
        light: UIColor(red: 161 / 255, green: 98 / 255, blue: 7 / 255, alpha: 1),
        dark: UIColor(red: 146 / 255, green: 64 / 255, blue: 14 / 255, alpha: 1)
    )
    static let info = adaptiveColor(
        light: UIColor(red: 3 / 255, green: 105 / 255, blue: 161 / 255, alpha: 1),
        dark: UIColor(red: 125 / 255, green: 211 / 255, blue: 252 / 255, alpha: 1)
    )
    static let infoFill = adaptiveColor(
        light: UIColor(red: 3 / 255, green: 105 / 255, blue: 161 / 255, alpha: 1),
        dark: UIColor(red: 7 / 255, green: 89 / 255, blue: 133 / 255, alpha: 1)
    )
    static let achievement = adaptiveColor(
        light: UIColor(red: 161 / 255, green: 98 / 255, blue: 7 / 255, alpha: 1),
        dark: UIColor(red: 252 / 255, green: 211 / 255, blue: 77 / 255, alpha: 1)
    )
    static let achievementFill = adaptiveColor(
        light: UIColor(red: 161 / 255, green: 98 / 255, blue: 7 / 255, alpha: 1),
        dark: UIColor(red: 146 / 255, green: 64 / 255, blue: 14 / 255, alpha: 1)
    )

    // Compatibility aliases retained for existing feature and widget code.
    static let primaryIndigo = brand
    static let cyberLime = success
    static let hyperMagenta = danger
    static let cyberCyan = info
    static let neonGold = achievement
    static let accentTeal = info
    static let rewardGold = achievement

    static func habitTint(named name: String) -> Color {
        switch name.lowercased() {
        case "blue", "teal": return info
        case "green": return success
        case "orange": return warning
        case "red": return danger
        case "purple", "indigo": return brand
        default: return brand
        }
    }

    static func habitFill(named name: String) -> Color {
        switch name.lowercased() {
        case "blue", "teal": return infoFill
        case "green": return successFill
        case "orange": return warningFill
        case "red": return dangerFill
        case "purple", "indigo": return brandFill
        default: return brandFill
        }
    }
    
    // Kept as gradients for API compatibility, but deliberately low-contrast.
    static let cyberGradient = AngularGradient(
        colors: [brandFill, infoFill, brandFill],
        center: .center
    )
    
    static let lifeScoreGradient = AngularGradient(
        colors: [brandFill, info, brandFill],
        center: .center
    )
    
    static let heroGradient = LinearGradient(
        colors: [brandFill, infoFill],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let electricLimeGradient = LinearGradient(
        colors: [successFill, successFill.opacity(0.78)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let goldGradient = LinearGradient(
        colors: [warningFill, achievementFill],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let incomeGradient = LinearGradient(
        colors: [successFill, successFill.opacity(0.78)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let expenseGradient = LinearGradient(
        colors: [dangerFill, dangerFill.opacity(0.78)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let progressGradient = LinearGradient(
        colors: [brandFill, infoFill],
        startPoint: .leading,
        endPoint: .trailing
    )
    
}

// MARK: - Completion Motion
struct CompletionMotionView: View {
    var color: Color = SelfUpStyle.successFill
    var compact = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    .fill(index.isMultiple(of: 2) ? color : SelfUpStyle.brandFill)
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
            guard !reduceMotion else {
                progress = 1
                checkScale = 1
                return
            }
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
