import SwiftUI

struct SplashScreenView<MainContent: View>: View {
    @ViewBuilder let mainContent: MainContent
    
    @State private var isAnimating = false
    @State private var pulseRing = false
    @State private var isSplashFinished = false
    @State private var fadeOut = false
    
    var body: some View {
        ZStack {
            if isSplashFinished {
                mainContent
                    .transition(.opacity)
            } else {
                ZStack {
                    // Dark/Light Dynamic Backdrop
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    // Expanding Radial Glow Rings
                    ZStack {
                        Circle()
                            .fill(SelfUpStyle.primaryIndigo.opacity(0.12))
                            .frame(width: 240, height: 240)
                            .scaleEffect(pulseRing ? 1.4 : 0.8)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(SelfUpStyle.rewardGold.opacity(0.1))
                            .frame(width: 160, height: 160)
                            .scaleEffect(pulseRing ? 1.2 : 0.6)
                            .blur(radius: 15)
                    }
                    
                    // Hero Animated Brand Logo
                    VStack(spacing: 20) {
                        SelfUpLogoView(style: .splashHero)
                            .scaleEffect(isAnimating ? 1.0 : 0.6)
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .rotationEffect(.degrees(isAnimating ? 0 : -10))
                    }
                }
                .opacity(fadeOut ? 0 : 1)
                .onAppear {
                    // Start Animation Sequence
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
                        isAnimating = true
                    }
                    
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseRing = true
                    }
                    
                    Haptics.success()
                    
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
