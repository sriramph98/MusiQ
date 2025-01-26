import SwiftUI

struct HomeView: View {
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var multipeerSessionManager = MultipeerSessionManager()
    @State private var showJoinModal = false
    @State private var sessionNameInput = ""
    @State private var isNavigatingToPartySession = false
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                // Host Button
                Button(action: {
                    sessionManager.createSession(name: sessionNameInput)
                    multipeerSessionManager.startHosting()
                    isNavigatingToPartySession = true
                }) {
                    VStack {
                        Text("Host a Party")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Create a music queue and let guests request songs.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .frame(maxWidth: 320)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .padding(.bottom, 20)
                .background(
                    NavigationLink(destination: PartySessionView(sessionManager: sessionManager, multipeerSessionManager: multipeerSessionManager), isActive: $isNavigatingToPartySession) {
                        EmptyView()
                    }
                )
                
                // Join Button
                Button(action: {
                    multipeerSessionManager.startBrowsing()
                    showJoinModal.toggle()
                }) {
                    VStack {
                        Text("Join a Party")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Request and vote for songs in the host's music queue.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .frame(maxWidth: 320)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .sheet(isPresented: $showJoinModal) {
                    JoinPartyView(
                        sessionManager: sessionManager,
                        multipeerSessionManager: multipeerSessionManager
                    )
                }
                
                Spacer()
                
                // Connected devices list (if needed)
                if !multipeerSessionManager.connectedPeers.isEmpty {
                    VStack {
                        Text("Connected Devices")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        List(multipeerSessionManager.connectedPeers, id: \.self) { peer in
                            Text(peer.displayName)
                        }
                        .frame(maxHeight: 150)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .navigationTitle("MusiQ")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    HomeView()
} 