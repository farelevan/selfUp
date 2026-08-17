import SwiftUI

struct SplashScreenView<MainContent: View>: View {
    @ViewBuilder let mainContent: MainContent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var isAnimating = false
    @State private var pulseRing = false
    @State private var isSplashFinished = false
    @State private var fadeOut = false
    @State private var orbitRotation = -35.0
    @State private var taglineVisible = false
    
    var body: some View {
        ZStack {
            if isSplashFinished {
                mainContent
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                ZStack {
                    // Dark/Light Dynamic Backdrop
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    // Restrained ambient depth
                    ZStack {
                        Circle()
                            .fill(SelfUpStyle.brand.opacity(0.10))
                            .frame(width: 260, height: 260)
                            .scaleEffect(pulseRing ? 1.24 : 0.86)
                            .blur(radius: 30)
                        
                        Circle()
                            .trim(from: 0.08, to: 0.72)
                            .stroke(
                                SelfUpStyle.heroGradient,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: 190, height: 190)
                            .rotationEffect(.degrees(orbitRotation))
                            .opacity(isAnimating ? 0.65 : 0)

                        Circle()
                            .fill(SelfUpStyle.brandFill)
                            .frame(width: 7, height: 7)
                            .offset(y: -95)
                            .rotationEffect(.degrees(orbitRotation))
                            .opacity(isAnimating ? 1 : 0)
                    }
                    
                    // Hero Animated Brand Logo
                    VStack(spacing: 20) {
                        SelfUpLogoView(style: .splashHero)
                            .scaleEffect(isAnimating ? 1.0 : 0.6)
                            .opacity(isAnimating ? 1.0 : 0.0)

                        Text("FOCUS · CONSISTENCY · GROWTH")
                            .font(.caption2.weight(.semibold))
                            .tracking(2.2)
                            .foregroundStyle(.secondary)
                            .opacity(taglineVisible ? 1 : 0)
                            .offset(y: taglineVisible ? 0 : 8)
                    }
                }
                .opacity(fadeOut ? 0 : 1)
                .onAppear {
                    guard !reduceMotion else {
                        isSplashFinished = true
                        return
                    }

                    // Start Animation Sequence
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
                        isAnimating = true
                    }
                    
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        pulseRing = true
                    }

                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        orbitRotation = 325
                    }

                    withAnimation(.easeOut(duration: 0.5).delay(0.55)) {
                        taglineVisible = true
                    }
                    
                    // Dismiss Splash after 1.8 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            fadeOut = true
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation {
                            isSplashFinished = true
                        }
                    }
                }
            }
        }
    }
}
