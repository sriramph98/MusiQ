import SwiftUI
import MultipeerConnectivity

struct JoinPartyView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var multipeerSessionManager: MultipeerSessionManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedHost: MCPeerID?
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Available Hosts")
                    .font(.title)
                    .padding()
                
                if multipeerSessionManager.availableHosts.isEmpty {
                    Text("Searching for hosts...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(multipeerSessionManager.availableHosts, id: \.self) { host in
                        Button(action: {
                            multipeerSessionManager.connectToHost(host)
                            dismiss()
                        }) {
                            HStack {
                                Text(host.displayName)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                multipeerSessionManager.stopBrowsing()
                dismiss()
            })
        }
    }
}

#Preview {
    JoinPartyView(
        sessionManager: SessionManager(),
        multipeerSessionManager: MultipeerSessionManager()
    )
} 