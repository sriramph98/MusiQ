import Foundation
import MediaPlayer

class SpotifyManager: ObservableObject {
    private let clientId = "eaa54ae378f84abe96b67b88686260d5"
    private let clientSecret = "51846ac87d714a60a5580823c888f61e"
    @Published var searchResults: [SpotifyTrack] = []
    @Published var isLoading = false
    @Published var nowPlayingItem: MPMediaItem?
    @Published var playbackState: MPMusicPlaybackState = .stopped
    @Published var playbackTime: TimeInterval = 0
    
    private var playbackObserver: NSObjectProtocol?
    private var timeObserver: Timer?
    
    struct SpotifyTrack: Identifiable, Codable {
        let id: String
        let name: String
        let artists: [Artist]
        let album: Album
        let duration_ms: Int
        
        struct Artist: Codable {
            let name: String
        }
        
        struct Album: Codable {
            let name: String
            let images: [Image]
        }
        
        struct Image: Codable {
            let url: String
        }
    }
    
    struct SearchResponse: Codable {
        let tracks: TracksResponse
        
        struct TracksResponse: Codable {
            let items: [SpotifyTrack]
        }
    }
    
    private var accessToken: String = ""
    
    init() {
        setupNowPlayingObservers()
    }
    
    private func setupNowPlayingObservers() {
        // Request permission for media library access
        MPMediaLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            
            DispatchQueue.main.async {
                // Observe now playing item changes
                self?.playbackObserver = NotificationCenter.default.addObserver(
                    forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
                    object: MPMusicPlayerController.systemMusicPlayer,
                    queue: .main
                ) { [weak self] _ in
                    self?.updateNowPlayingInfo()
                }
                
                // Start playback time updates
                self?.timeObserver = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                    self?.updatePlaybackTime()
                }
                
                // Initial update
                self?.updateNowPlayingInfo()
                MPMusicPlayerController.systemMusicPlayer.beginGeneratingPlaybackNotifications()
            }
        }
    }
    
    private func updateNowPlayingInfo() {
        nowPlayingItem = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem
        playbackState = MPMusicPlayerController.systemMusicPlayer.playbackState
    }
    
    private func updatePlaybackTime() {
        playbackTime = MPMusicPlayerController.systemMusicPlayer.currentPlaybackTime
    }
    
    func togglePlayPause() {
        switch MPMusicPlayerController.systemMusicPlayer.playbackState {
        case .playing:
            MPMusicPlayerController.systemMusicPlayer.pause()
        case .paused, .stopped:
            MPMusicPlayerController.systemMusicPlayer.play()
        default:
            break
        }
    }
    
    func authenticate() async {
        let auth = "\(clientId):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
        
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)
            self.accessToken = response.access_token
        } catch {
            print("Authentication error: \(error)")
        }
    }
    
    func searchTracks(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                self.searchResults = []
            }
            return
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=track&limit=10") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            await MainActor.run {
                self.searchResults = response.tracks.items
            }
        } catch {
            print("Search error: \(error)")
        }
    }
    
    private struct AuthResponse: Codable {
        let access_token: String
    }
    
    deinit {
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        timeObserver?.invalidate()
        MPMusicPlayerController.systemMusicPlayer.endGeneratingPlaybackNotifications()
    }
} 