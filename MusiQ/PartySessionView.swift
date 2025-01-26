import SwiftUI

struct PartySessionView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var multipeerSessionManager: MultipeerSessionManager
    
    var body: some View {
        VStack {
            Text("Party Session")
                .font(.largeTitle)
                .padding()
            
            Text("Party Title: \(sessionManager.sessionName)")
                .font(.title2)
                .padding()
            
            Text("Connected Devices: \(multipeerSessionManager.connectedPeers.count)")
                .font(.title3)
                .padding()
            
            List(multipeerSessionManager.connectedPeers, id: \.self) { peer in
                Text(peer.displayName)
            }
            
            Button("End Party") {
                multipeerSessionManager.stopHosting()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .navigationTitle("Party Session")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PartySessionView(
        sessionManager: SessionManager(),
        multipeerSessionManager: MultipeerSessionManager()
    )
} 