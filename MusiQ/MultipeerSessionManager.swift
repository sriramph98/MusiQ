import Foundation
import MultipeerConnectivity

class MultipeerSessionManager: NSObject, ObservableObject {
    private let serviceType = "musq-party"
    
    private var peerID: MCPeerID!
    private var mcSession: MCSession!
    private var mcAdvertiserAssistant: MCNearbyServiceAdvertiser!
    private var mcNearbyServiceBrowser: MCNearbyServiceBrowser!
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var availableHosts: [MCPeerID] = []
    @Published var isHosting: Bool = false
    
    override init() {
        super.init()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        mcAdvertiserAssistant = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        mcAdvertiserAssistant.delegate = self
        
        mcNearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        mcNearbyServiceBrowser.delegate = self
    }
    
    func startHosting() {
        isHosting = true
        mcAdvertiserAssistant.startAdvertisingPeer()
    }
    
    func stopHosting() {
        isHosting = false
        mcAdvertiserAssistant.stopAdvertisingPeer()
    }
    
    func startBrowsing() {
        availableHosts.removeAll()
        mcNearbyServiceBrowser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        mcNearbyServiceBrowser.stopBrowsingForPeers()
        availableHosts.removeAll()
    }
    
    func connectToHost(_ host: MCPeerID) {
        mcNearbyServiceBrowser.invitePeer(host, to: mcSession, withContext: nil, timeout: 30)
    }
    
    func disconnect() {
        mcSession.disconnect()
        stopBrowsing()
        stopHosting()
        connectedPeers.removeAll()
        availableHosts.removeAll()
    }
}

// MARK: - MCSessionDelegate
extension MultipeerSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            DispatchQueue.main.async {
                self.connectedPeers.append(peerID)
            }
        case .notConnected:
            DispatchQueue.main.async {
                self.connectedPeers.removeAll { $0 == peerID }
            }
        default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Handle received stream
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Handle resource receiving start
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Handle resource receiving completion
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, mcSession)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        // Handle advertising error
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            if !self.availableHosts.contains(peerID) {
                self.availableHosts.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.availableHosts.removeAll { $0 == peerID }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error)")
    }
} 
