import SwiftUI
import MultipeerConnectivity

struct GuestView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var multipeerSessionManager: MultipeerSessionManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBarView(searchText: $searchText, placeholder: "Search for songs...")
                    .padding(.vertical)
                
                Text("Connected to: \(multipeerSessionManager.connectedPeers.first?.displayName ?? "Unknown Host")")
                    .font(.title2)
                    .padding()
                
                Spacer()
                
                // Add more guest features here
                
                Button(action: {
                    // Disconnect from host
                    multipeerSessionManager.disconnect()
                    dismiss()
                }) {
                    Text("Leave Party")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Guest")
            .navigationBarTitleDisplayMode(.large)
        }
    }
} 