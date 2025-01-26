import Foundation

class SessionManager: ObservableObject {
    @Published var sessionName: String = ""
    
    func createSession(name: String) {
        sessionName = name
    }
} 