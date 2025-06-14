import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User Info
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    if let user = authManager.currentUser {
                        Text(user.email ?? "Unknown User")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text("Member since \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
                
                // Settings/Options
                VStack(spacing: 16) {
                    ProfileRowButton(
                        icon: "gear",
                        title: "Settings",
                        action: { /* TODO: Add settings */ }
                    )
                    
                    ProfileRowButton(
                        icon: "questionmark.circle",
                        title: "Help & Support",
                        action: { /* TODO: Add help */ }
                    )
                    
                    ProfileRowButton(
                        icon: "star",
                        title: "Rate App",
                        action: { /* TODO: Add rating */ }
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Sign Out Button
                Button(action: { showingSignOutAlert = true }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Sign Out")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Profile")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await authManager.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct ProfileRowButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}