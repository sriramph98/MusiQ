//
//  MusiQApp.swift
//  MusiQ
//
//  Created by Sriram P H on 1/25/25.
//

import SwiftUI

@main
struct MusiQApp: App {
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                        .scaleEffect(showSplash ? 1.1 : 1.0)
                        .opacity(showSplash ? 1 : 0)
                } else {
                    HomeView() // Show HomeView after splash
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            Text("MusiQ")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    SplashScreen()
}
