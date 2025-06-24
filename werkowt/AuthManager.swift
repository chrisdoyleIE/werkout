import Foundation
import Supabase
import Auth
import os

enum AuthError: Error {
    case timeout
    case invalidCredentials
    case networkError
}

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
            print("🔐 AuthManager: Starting auth status check...")
            
            do {
                // Add timeout protection to prevent infinite loading
                let session = try await withTaskTimeout(seconds: 10) { [self] in
                    try await supabase.auth.session
                }
                
                print("🔐 AuthManager: Successfully retrieved session")
                await MainActor.run {
                    self.currentUser = session.user
                    self.isAuthenticated = true
                    self.isLoading = false
                }
                print("🔐 AuthManager: User authenticated successfully")
                
            } catch {
                print("🔐 AuthManager: Auth check failed with error: \(error)")
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.isLoading = false
                }
                print("🔐 AuthManager: Set to unauthenticated state")
            }
        }
    }
    
    // Helper function to add timeout to async operations
    private func withTaskTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AuthError.timeout
            }
            
            guard let result = try await group.next() else {
                throw AuthError.timeout
            }
            
            group.cancelAll()
            return result
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
            Logger.error("Failed to create/update profile: \(error)", category: Logger.auth)
        }
    }
    
    var userId: UUID? {
        return currentUser?.id
    }
}