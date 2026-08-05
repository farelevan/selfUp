import SwiftUI

enum LogoStyle {
    case iconOnly(size: CGFloat)
    case compactHeader
    case splashHero
}

struct SelfUpLogoView: View {
    var style: LogoStyle = .compactHeader
    
    var body: some View {
        switch style {
        case .iconOnly(let size):
            LogoEmblem(size: size)
            
        case .compactHeader:
            HStack(spacing: 8) {
                LogoEmblem(size: 32)
                
                HStack(spacing: 0) {
                    Text("Self")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Up")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(SelfUpStyle.heroGradient)
                }
            }
            
        case .splashHero:
            VStack(spacing: 16) {
                LogoEmblem(size: 84)
                    .shadow(color: SelfUpStyle.primaryIndigo.opacity(0.4), radius: 20, x: 0, y: 10)
                
                HStack(spacing: 0) {
                    Text("Self")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Up")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(SelfUpStyle.heroGradient)
                }
                
                Text("ELEVATE YOUR DAILY LIFE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(3)
            }
        }
    }
}

// MARK: - Logo Emblem (Pure SwiftUI Vector Graphic)
struct LogoEmblem: View {
    var size: CGFloat = 32
    
    var body: some View {
        ZStack {
            // Background Badge Shape
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(SelfUpStyle.heroGradient)
                .frame(width: size, height: size)
                .shadow(color: SelfUpStyle.primaryIndigo.opacity(0.3), radius: size * 0.2, x: 0, y: size * 0.1)
            
            // Ascending Growth Arrow Chevron + Pulse Ring
            ZStack {
                // Outer Glow Loop
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size * 0.05
                    )
                    .frame(width: size * 0.65, height: size * 0.65)
                
                // Ascending Arrow Chevron
                Path { path in
                    let width = size * 0.44
                    let height = size * 0.44
                    
                    // Outer Chevron Top Point
                    path.move(to: CGPoint(x: width * 0.5, y: height * 0.15))
                    path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.52))
                    path.addLine(to: CGPoint(x: width * 0.70, y: height * 0.52))
                    path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.32))
                    path.addLine(to: CGPoint(x: width * 0.30, y: height * 0.52))
                    path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.52))
                    path.closeSubpath()
                    
                    // Lower Parallel Chevron Accent
                    path.move(to: CGPoint(x: width * 0.5, y: height * 0.42))
                    path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.78))
                    path.addLine(to: CGPoint(x: width * 0.70, y: height * 0.78))
                    path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.58))
                    path.addLine(to: CGPoint(x: width * 0.30, y: height * 0.78))
                    path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.78))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 1.0, green: 0.85, blue: 0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.44, height: size * 0.44)
            }
        }
    }
}
