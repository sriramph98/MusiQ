import SwiftUI
import MultipeerConnectivity

struct PartySessionView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var multipeerSessionManager: MultipeerSessionManager
    @StateObject private var spotifyManager = SpotifyManager()
    @State private var searchText = ""
    @State private var queue: [SpotifyManager.SpotifyTrack] = []
    @State private var showAddedFeedback = false
    @State private var lastAddedTrack: SpotifyManager.SpotifyTrack?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBarView(searchText: $searchText, placeholder: "Search for songs...")
                .padding(.top)
            
            // Party Info
            HStack {
                Text("Party: \(sessionManager.sessionName)")
                    .font(.headline)
                Spacer()
                Text("\(multipeerSessionManager.connectedPeers.count) Connected")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            
            // Dynamic Content Area
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Search Results or Queue
                    VStack {
                        if !searchText.isEmpty {
                            // Search Results
                            if spotifyManager.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if spotifyManager.searchResults.isEmpty {
                                ContentUnavailableView("No Results", systemImage: "magnifyingglass")
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 8) {
                                        ForEach(spotifyManager.searchResults) { track in
                                            TrackRow(track: track, onAdd: {
                                                withAnimation {
                                                    addToQueue(track)
                                                }
                                            })
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .frame(width: searchText.isEmpty ? 0 : geometry.size.width)
                    
                    // Queue (Always Visible)
                    VStack {
                        HStack {
                            Text("Queue")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(queue.count) tracks")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                        if queue.isEmpty {
                            ContentUnavailableView("Queue Empty", systemImage: "music.note.list")
                                .frame(maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(queue) { track in
                                    TrackRow(track: track, isInQueue: true, onAdd: nil)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    removeFromQueue(track)
                                                }
                                            } label: {
                                                Label("Remove", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                    .frame(width: searchText.isEmpty ? geometry.size.width : 0)
                }
                .animation(.spring(response: 0.3), value: searchText)
            }
            
            // Now Playing Bar
            if let nowPlaying = spotifyManager.nowPlayingItem {
                VStack(spacing: 0) {
                    // Progress Bar
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (spotifyManager.playbackTime / nowPlaying.playbackDuration))
                            .animation(.linear(duration: 0.5), value: spotifyManager.playbackTime)
                    }
                    .frame(height: 2)
                    
                    HStack(spacing: 16) {
                        // Album Art
                        if let artwork = nowPlaying.artwork {
                            Image(uiImage: artwork.image(at: CGSize(width: 40, height: 40)) ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .cornerRadius(6)
                        }
                        
                        // Track Info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(nowPlaying.title ?? "Unknown Title")
                                .font(.system(size: 15, weight: .medium))
                                .lineLimit(1)
                            
                            Text(nowPlaying.artist ?? "Unknown Artist")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Play/Pause Button
                        Button(action: {
                            spotifyManager.togglePlayPause()
                        }) {
                            Image(systemName: spotifyManager.playbackState == .playing ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.thinMaterial)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showAddedFeedback, let track = lastAddedTrack {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(track.name) added to queue")
                        .font(.subheadline)
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(20)
                .padding(.bottom, spotifyManager.nowPlayingItem != nil ? 80 : 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Host")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await spotifyManager.authenticate()
        }
        .onChange(of: searchText) { oldValue, newValue in
            Task {
                await spotifyManager.searchTracks(query: newValue)
            }
        }
    }
    
    private func addToQueue(_ track: SpotifyManager.SpotifyTrack) {
        queue.append(track)
        lastAddedTrack = track
        withAnimation {
            showAddedFeedback = true
        }
        
        // Auto-play if this is the first track and nothing is playing
        if queue.count == 1 && spotifyManager.nowPlayingItem == nil {
            // Instead of directly playing, we should handle this differently
            // since we're using system playback
            // TODO: Implement proper queue management
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showAddedFeedback = false
            }
        }
    }
    
    private func removeFromQueue(_ track: SpotifyManager.SpotifyTrack) {
        queue.removeAll { $0.id == track.id }
    }
}

struct TrackRow: View {
    let track: SpotifyManager.SpotifyTrack
    var isInQueue: Bool = false
    var onAdd: (() -> Void)?
    
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
            
            // Add Button (only shown in search results)
            if let onAdd = onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
    }
}

#Preview {
    PartySessionView(
        sessionManager: SessionManager(),
        multipeerSessionManager: MultipeerSessionManager()
    )
} 