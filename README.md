# Werkout 💪

A modern iOS workout tracking app built with SwiftUI that helps you log, track, and analyze your fitness journey with seamless cloud synchronization.

## Features

### 🏋️ Comprehensive Exercise Library
- **Pre-loaded exercise database** with detailed instructions
- **Multiple exercise types** supported:
  - Weight-based exercises (bench press, squats, deadlifts)
  - Bodyweight exercises (push-ups, pull-ups, planks)
  - Timed exercises (planks, wall sits, cardio)
- **Organized by muscle groups**: Chest, Back, Legs, Arms, Shoulders, Core
- **Visual muscle group indicators** with color-coded icons

### 📱 Intuitive Live Workout Interface
- **Real-time workout tracking** with elapsed time display
- **Exercise navigation tabs** with progress indicators
- **Previous workout reference** - see your last performance for each exercise
- **Smart input forms** adapted to exercise type (weight+reps, reps only, or duration)
- **Automatic keyboard dismissal** after adding sets
- **Set management** with delete functionality

### ⏱️ Built-in Timers
- **Rest timers** with customizable durations (1m, 2m, 3m)
- **Exercise timers** for timed exercises (30s, 60s, 90s presets)
- **Visual timer displays** with skip options
- **Auto-start rest timers** after completing sets

### 📊 Workout Management
- **Custom workout creation** with exercise selection
- **Quick class logger** for fitness classes and cardio
- **Workout history** with comprehensive session tracking
- **Calendar view** for workout scheduling and review
- **Session statistics** including duration and exercise count

### ☁️ Cloud Sync & Authentication
- **Supabase integration** for secure cloud storage
- **User authentication** with secure login/signup
- **Cross-device synchronization** of all workout data
- **Offline capability** with sync when connected

### 🎨 Modern UI/UX
- **SwiftUI native design** following iOS design guidelines
- **Dark/Light mode support**
- **Responsive layouts** optimized for all iPhone sizes
- **Smooth animations** and transitions
- **Intuitive navigation** with tab-based interface

## Screenshots

*Add screenshots here showing key features*

## Tech Stack

- **Frontend**: SwiftUI (iOS 15+)
- **Backend**: Supabase (PostgreSQL, Authentication, Real-time sync)
- **Architecture**: MVVM with ObservableObject
- **Data Management**: CoreData equivalent with cloud sync
- **Authentication**: Supabase Auth

## Project Structure

```
werkowt/
├── werkowt/
│   ├── werkowtApp.swift           # App entry point
│   ├── Models.swift               # Data models and types
│   ├── exercises.json             # Exercise database
│   ├── Views/
│   │   ├── HomeView.swift         # Main dashboard with calendar
│   │   ├── LiveWorkoutView.swift  # Active workout tracking
│   │   ├── WorkoutCreatorView.swift # Custom workout builder
│   │   ├── AuthView.swift         # Login/signup interface
│   │   └── QuickClassLoggerView.swift # Quick logging for classes
│   ├── AuthManager.swift          # Authentication handling
│   ├── SupabaseManager.swift      # Backend integration
│   ├── WorkoutDataManager.swift   # Workout data operations
│   ├── ExerciseDataManager.swift  # Exercise data management
│   └── Assets.xcassets/           # App icons and assets
├── Config.xcconfig.example        # Configuration template
└── supabase_schema.sql           # Database schema
```

## Getting Started

### Prerequisites

- Xcode 14.0 or later
- iOS 15.0 or later
- Active Apple Developer account (for device testing)
- Supabase account for backend services

### Installation

1. **Clone the repository**
   ```bash
   git clone git@github.com:chrisdoyleIE/werkout.git
   cd werkout
   ```

2. **Set up Supabase backend**
   - Create a new project at [supabase.com](https://supabase.com)
   - Run the SQL schema from `supabase_schema.sql` in your Supabase SQL editor
   - Note your project URL and anon key

3. **Configure the app**
   ```bash
   cp Config.xcconfig.example Config.xcconfig
   ```
   Edit `Config.xcconfig` and add your Supabase credentials:
   ```
   SUPABASE_URL = your_supabase_project_url
   SUPABASE_ANON_KEY = your_supabase_anon_key
   ```

4. **Open in Xcode**
   ```bash
   open werkowt.xcodeproj
   ```

5. **Build and run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

## Database Schema

The app uses the following main tables in Supabase:

- **workout_sessions**: Stores workout metadata (name, duration, timestamps)
- **workout_sets**: Stores individual set data (reps, weight, duration)
- **User profiles**: Managed by Supabase Auth

See `supabase_schema.sql` for the complete database structure.

## Development

### Key Components

- **ActiveWorkout**: ObservableObject managing current workout state
- **WorkoutDataManager**: Handles all workout-related data operations
- **ExerciseDataManager**: Manages exercise library and muscle groups
- **AuthManager**: Handles user authentication and session management
- **SupabaseManager**: Central integration with Supabase services

### Adding New Features

1. **New Exercise Types**: Update `ExerciseType` enum in `Models.swift`
2. **New Exercises**: Add to `exercises.json` following the existing format
3. **UI Components**: Create new SwiftUI views in the `Views/` directory
4. **Data Operations**: Extend managers with new functions

### Testing

```bash
# Run unit tests
cmd + U in Xcode

# Test on device
# Connect iPhone and select as build target
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

- [ ] **Exercise Analytics**: Progress charts and performance tracking
- [ ] **Workout Templates**: Pre-built workout routines
- [ ] **Social Features**: Share workouts and compete with friends
- [ ] **Apple Health Integration**: Sync with HealthKit
- [ ] **Apple Watch Support**: Companion watchOS app
- [ ] **Exercise Video Guides**: In-app exercise demonstrations
- [ ] **Custom Exercise Creation**: User-defined exercises
- [ ] **Workout Planning**: Schedule future workouts
- [ ] **Export Data**: CSV/JSON export functionality
- [ ] **Offline Mode Enhancement**: Full offline workout capability

## Privacy & Security

- All user data is securely stored in Supabase with row-level security
- Authentication uses industry-standard JWT tokens
- No personal data is shared with third parties
- Local data is encrypted on device

## Support

For bug reports and feature requests, please [create an issue](https://github.com/chrisdoyleIE/werkout/issues).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Exercise database curated from fitness industry standards
- UI/UX inspired by modern fitness apps
- Built with love for the fitness community

---

**Werkout** - Track your gains, achieve your goals 🎯