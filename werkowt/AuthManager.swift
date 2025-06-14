import Foundation
import Supabase
import Auth

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Auth.User?
    @Published var isLoading = true
    
    private let supabase = SupabaseManager.shared.client
    
    static let shared = AuthManager()
    
    private init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                await MainActor.run {
                    self.currentUser = session.user
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.isLoading = false
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let response = try await supabase.auth.signIn(email: email, password: password)
        
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
        
        // Create or update profile
        await createOrUpdateProfile()
    }
    
    func signUp(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(email: email, password: password)
        
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
        
        // Create profile for new user
        await createOrUpdateProfile()
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    private func createOrUpdateProfile() async {
        guard let user = currentUser else { return }
        
        do {
            struct ProfileData: Codable {
                let id: UUID
                let username: String?
                let full_name: String?
                let updated_at: String
            }
            
            let profileData = ProfileData(
                id: user.id,
                username: user.email?.components(separatedBy: "@").first,
                full_name: user.userMetadata["full_name"] as? String,
                updated_at: Date().ISO8601Format()
            )
            
            try await supabase
                .from("profiles")
                .upsert(profileData)
                .execute()
            
        } catch {
            print("Failed to create/update profile: \(error)")
        }
    }
    
    var userId: UUID? {
        return currentUser?.id
    }
}