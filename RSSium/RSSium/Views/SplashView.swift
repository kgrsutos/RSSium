import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            Color.primary
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "newspaper")
                    .font(.system(size: 80))
                    .foregroundStyle(.background)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("RSSium")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.background)
                    .opacity(isAnimating ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .opacity(showSplash ? 1.0 : 0.0)
    }
}

#Preview {
    SplashView()
}