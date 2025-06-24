import SwiftUI

struct CustomTabView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0 // Start with Home
    @State private var showingActionMenu = false
    @State private var showingWorkoutCreator = false
    @State private var showingFoodLogger = false
    @State private var showingAddWeight = false
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    NutritionTabView() // Shopping
                case 2:
                    WorkoutProgressView() // Progress
                case 3:
                    SettingsView() // Profile
                default:
                    HomeView()
                }
            }
            
            // Custom tab bar
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    // Home tab
                    TabBarButton(
                        icon: "house",
                        title: "Home",
                        isSelected: selectedTab == 0,
                        action: {
                            selectedTab = 0
                            showingActionMenu = false
                        }
                    )
                    
                    // Shopping tab (renamed from Nutrition)
                    TabBarButton(
                        icon: "carrot",
                        title: "Shopping",
                        isSelected: selectedTab == 1,
                        action: {
                            selectedTab = 1
                            showingActionMenu = false
                        }
                    )
                    
                    // Training tab
                    TabBarButton(
                        icon: "dumbbell.fill",
                        title: "Training",
                        isSelected: selectedTab == 2,
                        action: {
                            selectedTab = 2
                            showingActionMenu = false
                        }
                    )
                    
                    // Profile tab
                    TabBarButton(
                        icon: "person.circle",
                        title: "Profile",
                        isSelected: selectedTab == 3,
                        action: {
                            selectedTab = 3
                            showingActionMenu = false
                        }
                    )
                    
                    Spacer(minLength: 20)
                    
                    // Plus button (far right)
                    Button(action: {
                        showingActionMenu.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: showingActionMenu ? "xmark" : "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showingActionMenu ? 45 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingActionMenu)
                        }
                    }
                    .offset(y: -55) // Adjust for taller bar
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 25) // Add more bottom padding to avoid control panel
                .frame(height: 120) // 50% taller than 80px
                .background(
                    Color(.systemBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: -1)
                )
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Action menu overlay
            if showingActionMenu {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingActionMenu = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        ActionMenuItem(
                            icon: "figure.stand",
                            label: "Log Weight",
                            color: .purple,
                            action: {
                                showingAddWeight = true
                                showingActionMenu = false
                            }
                        )
                        
                        ActionMenuItem(
                            icon: "fork.knife",
                            label: "Track Food",
                            color: .green,
                            action: {
                                showingFoodLogger = true
                                showingActionMenu = false
                            }
                        )
                        
                        ActionMenuItem(
                            icon: "figure.strengthtraining.functional",
                            label: "Start Workout",
                            color: .blue,
                            action: {
                                showingWorkoutCreator = true
                                showingActionMenu = false
                            }
                        )
                    }
                    .padding(.bottom, 120)
                    .padding(.horizontal, 10)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingActionMenu)
        .sheet(isPresented: $showingWorkoutCreator) {
            WorkoutCreatorView()
        }
        .sheet(isPresented: $showingFoodLogger) {
            FoodTrackingView()
        }
        .sheet(isPresented: $showingAddWeight) {
            AddWeightView { weight, notes in
                await addWeight(weight: weight, notes: notes)
            }
        }
    }
    
    private func addWeight(weight: Double, notes: String?) async {
        // This would be handled by HomeView's WorkoutDataManager
        print("Weight logging would be handled here")
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .black : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

struct ActionMenuItem: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40)
                
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
    }
}

