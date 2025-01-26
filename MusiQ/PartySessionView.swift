import SwiftUI
import MultipeerConnectivity

struct PartySessionView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var multipeerSessionManager: MultipeerSessionManager
    @StateObject private var spotifyManager = SpotifyManager()
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Search Bar
            SearchBarView(searchText: $searchText, placeholder: "Search for songs...")
                .padding(.top)
            
            // Party Info
            VStack(spacing: 8) {
                Text("Party Title: \(sessionManager.sessionName)")
                    .font(.headline)
                
                Text("Connected Devices: \(multipeerSessionManager.connectedPeers.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            // Content Area
            if !searchText.isEmpty {
                // Search Results
                if spotifyManager.searchResults.isEmpty {
                    ContentUnavailableView("Searching...", systemImage: "magnifyingglass")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(spotifyManager.searchResults) { track in
                                TrackRow(track: track)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            } else {
                // Connected Peers List
                if multipeerSessionManager.connectedPeers.isEmpty {
                    ContentUnavailableView("No Connected Devices", systemImage: "person.2")
                } else {
                    List(multipeerSessionManager.connectedPeers, id: \.self) { peer in
                        Text(peer.displayName)
                    }
                }
            }
            
            Spacer()
            
            // End Party Button
            Button(action: {
                multipeerSessionManager.stopHosting()
            }) {
                Text("End Party")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Host")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await spotifyManager.authenticate()
        }
        .onChange(of: searchText) { newValue in
            Task {
                await spotifyManager.searchTracks(query: newValue)
            }
        }
    }
}

struct TrackRow: View {
    let track: SpotifyManager.SpotifyTrack
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Art
            if let imageUrl = track.album.images.first?.url {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            }
            
            // Track Info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.name)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                
                Text(track.artists.map { $0.name }.joined(separator: ", "))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Add Button
            Button(action: {
                // Add to queue action
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    PartySessionView(
        sessionManager: SessionManager(),
        multipeerSessionManager: MultipeerSessionManager()
    )
} 