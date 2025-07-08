import SwiftUI


struct CustomTabView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0 // Start with Home
    @State private var showingActionMenu = false
    @State private var showingWorkoutCreator = false
    @State private var showingFoodLogger = false
    @State private var showingAddWeight = false
    @State private var showingManualSearch = false
    
    var body: some View {
        ZStack {
            // Subtle background to make tab bar stand out
            Color(.systemGray6)
                .ignoresSafeArea()
            
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
                
                ZStack {
                    // Split tab buttons with center space for plus button
                    HStack {
                        // Left group: Home and Shopping
                        HStack {
                            TabBarButton(
                                icon: "house",
                                title: "Home",
                                isSelected: selectedTab == 0,
                                action: {
                                    selectedTab = 0
                                    showingActionMenu = false
                                }
                            )
                            
                            TabBarButton(
                                icon: "leaf.fill",
                                title: "Nutrition",
                                isSelected: selectedTab == 1,
                                action: {
                                    selectedTab = 1
                                    showingActionMenu = false
                                }
                            )
                        }
                        
                        Spacer()
                        
                        // Space for center plus button
                        Color.clear
                            .frame(width: 80) // Space for plus button
                        
                        Spacer()
                        
                        // Right group: Training and Profile
                        HStack {
                            TabBarButton(
                                icon: "dumbbell.fill",
                                title: "Training",
                                isSelected: selectedTab == 2,
                                action: {
                                    selectedTab = 2
                                    showingActionMenu = false
                                }
                            )
                            
                            TabBarButton(
                                icon: "person.circle",
                                title: "Profile",
                                isSelected: selectedTab == 3,
                                action: {
                                    selectedTab = 3
                                    showingActionMenu = false
                                }
                            )
                        }
                    }
                    
                    // Plus button (centered and floating)
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
                    .offset(y: -40) // Floating above the tab bar
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
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ActionMenuItem(
                            icon: "figure.strengthtraining.functional",
                            label: "Log exercise",
                            isPrimary: true,
                            action: {
                                showingWorkoutCreator = true
                                showingActionMenu = false
                            }
                        )
                        
                        ActionMenuItem(
                            icon: "camera.viewfinder",
                            label: "Scan Food",
                            isPrimary: false,
                            action: {
                                showingFoodLogger = true
                                showingActionMenu = false
                            }
                        )
                        
                        ActionMenuItem(
                            icon: "magnifyingglass",
                            label: "Search Food",
                            isPrimary: false,
                            action: {
                                showingManualSearch = true
                                showingActionMenu = false
                            }
                        )
                        
                        ActionMenuItem(
                            icon: "figure.stand",
                            label: "Record weight",
                            isPrimary: false,
                            action: {
                                showingAddWeight = true
                                showingActionMenu = false
                            }
                        )
                    }
                    .padding(.bottom, 120)
                    .padding(.horizontal, 16)
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
        .sheet(isPresented: $showingManualSearch) {
            ManualFoodSearchView(selectedMealType: mealTypeForCurrentTime())
        }
    }
    
    private func addWeight(weight: Double, notes: String?) async {
        // This would be handled by HomeView's WorkoutDataManager
        print("Weight logging would be handled here")
    }
    
    private func mealTypeForCurrentTime() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...10:
            return .breakfast
        case 11...15:
            return .lunch
        case 16...21:
            return .dinner
        default:
            return .snack
        }
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
            .padding(.top, 12)
        }
    }
}

struct ActionMenuItem: View {
    let icon: String
    let label: String
    let isPrimary: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: isPrimary ? 36 : 32, weight: isPrimary ? .semibold : .medium))
                    .foregroundColor(isPrimary ? .primary : .primary.opacity(0.7))
                    .frame(width: 50, height: 50)
                
                Text(label)
                    .font(.system(size: isPrimary ? 17 : 16, weight: isPrimary ? .semibold : .medium))
                    .foregroundColor(isPrimary ? .primary : .primary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isPrimary ? 130 : 120)
            .background(isPrimary ? Color(.systemBackground) : Color(.systemGray6))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(isPrimary ? 0.1 : 0.05), radius: isPrimary ? 12 : 8, x: 0, y: isPrimary ? 6 : 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isPrimary ? Color(.systemGray4) : Color(.systemGray5), lineWidth: isPrimary ? 1.5 : 1)
            )
            .scaleEffect(isPrimary ? 1.0 : 0.95)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

