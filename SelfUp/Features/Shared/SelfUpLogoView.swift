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
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundStyle(.primary)
                    Text("Up")
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundStyle(SelfUpStyle.primaryIndigo)
                }
            }
            
        case .splashHero:
            VStack(spacing: 16) {
                LogoEmblem(size: 84)
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                
                HStack(spacing: 0) {
                    Text("Self")
                        .font(.system(size: 42, weight: .semibold, design: .default))
                        .foregroundStyle(.primary)
                    Text("Up")
                        .font(.system(size: 42, weight: .semibold, design: .default))
                        .foregroundStyle(SelfUpStyle.primaryIndigo)
                }
                
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
                .shadow(color: Color.black.opacity(0.12), radius: size * 0.12, x: 0, y: size * 0.06)
            
            // Ascending Growth Arrow Chevron + Pulse Ring
            ZStack {
                // Subtle structure ring
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
                        colors: [.white, .white.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.44, height: size * 0.44)
            }
        }
    }
}
