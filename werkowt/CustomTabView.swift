import SwiftUI

struct CustomTabView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 1
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
                    NutritionTabView()
                case 1:
                    HomeView()
                case 2:
                    WorkoutProgressView()
                default:
                    HomeView()
                }
            }
            
            // Custom tab bar
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    // Nutrition tab
                    TabBarButton(
                        icon: "carrot",
                        title: "Nutrition",
                        isSelected: selectedTab == 0,
                        action: {
                            selectedTab = 0
                            showingActionMenu = false
                        }
                    )
                    
                    Spacer()
                    
                    // Plus button (center)
                    Button(action: {
                        if selectedTab != 1 {
                            selectedTab = 1
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingActionMenu = true
                            }
                        } else {
                            showingActionMenu.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: showingActionMenu ? "xmark" : "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showingActionMenu ? 45 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingActionMenu)
                        }
                    }
                    .offset(y: -10)
                    
                    Spacer()
                    
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
                }
                .padding(.horizontal, 40)
                .frame(height: 49)
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
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .blue : .gray)
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

