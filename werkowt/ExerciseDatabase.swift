import Foundation

enum ExerciseEquipment: String, CaseIterable {
    case barbell = "barbell"
    case dumbbell = "dumbbell"
    case cable = "cable"
    case bodyweight = "bodyweight"
    case machine = "machine"
    case kettlebell = "kettlebell"
    case resistance_band = "resistance_band"
    
    
    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .bodyweight: return "Bodyweight"
        case .machine: return "Machine"
        case .kettlebell: return "Kettlebell"
        case .resistance_band: return "Resistance Band"
        }
    }
}

enum ExerciseCategory: String, CaseIterable {
    case compound = "compound"
    case isolation = "isolation"
    case bodyweight = "bodyweight"
    case cardio = "cardio"
    
    var displayName: String {
        switch self {
        case .compound: return "Compound"
        case .isolation: return "Isolation"
        case .bodyweight: return "Bodyweight"
        case .cardio: return "Cardio"
        }
    }
}


struct EnhancedExercise {
    let id: String
    let name: String
    let instructions: String
    let equipment: ExerciseEquipment
    let category: ExerciseCategory
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let tips: [String]
}

struct ExerciseDatabase {
    static let exercises: [String: [EnhancedExercise]] = [
        "chest": [
            // COMPOUND MOVEMENTS (8)
            EnhancedExercise(
                id: "bench_press",
                name: "Bench Press",
                instructions: "Lie on bench, grip bar shoulder-width apart, lower to chest with control, press up explosively",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["triceps", "shoulders"],
                tips: ["Keep feet flat on floor", "Squeeze shoulder blades together", "Touch chest lightly, don't bounce"]
            ),
            EnhancedExercise(
                id: "incline_bench_press",
                name: "Incline Bench Press",
                instructions: "Set bench to 30-45°, press barbell from inclined position targeting upper chest",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["triceps", "shoulders"],
                tips: ["30-45° angle is optimal", "Don't go too steep", "Control the descent"]
            ),
            EnhancedExercise(
                id: "decline_bench_press",
                name: "Decline Bench Press",
                instructions: "Set bench to decline position, press weight from declined angle targeting lower chest",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["triceps", "shoulders"],
                tips: ["Secure feet properly", "Shorter range of motion", "Focus on lower chest"]
            ),
            EnhancedExercise(
                id: "dumbbell_bench_press",
                name: "Dumbbell Bench Press",
                instructions: "Lie on bench with dumbbells, press up while maintaining control and full range of motion",
                equipment: .dumbbell,
                category: .compound,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["triceps", "shoulders"],
                tips: ["Greater range of motion than barbell", "Control the weight", "Keep dumbbells aligned"]
            ),
            EnhancedExercise(
                id: "incline_dumbbell_press",
                name: "Incline Dumbbell Press",
                instructions: "Set bench to 30-45°, press dumbbells from inclined position with full range of motion",
                equipment: .dumbbell,
                category: .compound,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["triceps", "shoulders"],
                tips: ["Start with lighter weight", "Focus on form", "Feel stretch at bottom"]
            ),
            EnhancedExercise(
                id: "chest_dips",
                name: "Chest Dips",
                instructions: "Lean forward on dip bars, lower body with control, press up focusing on chest activation",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["triceps", "shoulders"],
                tips: ["Lean forward for chest focus", "Control the descent", "Full range of motion"]
            ),
            EnhancedExercise(
                id: "push_ups",
                name: "Push-ups",
                instructions: "Hands shoulder-width apart, lower chest to ground, push up maintaining straight body line",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["triceps", "shoulders", "core"],
                tips: ["Keep body straight", "Full range of motion", "Breathe out on push"]
            ),
            EnhancedExercise(
                id: "chest_press_machine",
                name: "Chest Press Machine",
                instructions: "Sit in machine, adjust seat height, press handles forward with controlled motion",
                equipment: .machine,
                category: .compound,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["triceps", "shoulders"],
                tips: ["Adjust seat for comfort", "Don't lock elbows", "Controlled movement"]
            ),
            
            // ISOLATION MOVEMENTS (12)
            EnhancedExercise(
                id: "dumbbell_flyes",
                name: "Dumbbell Flyes",
                instructions: "Lie flat, arms wide with slight bend, bring dumbbells together in arc motion",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: [],
                tips: ["Slight bend in elbows", "Feel the stretch", "Squeeze at top"]
            ),
            EnhancedExercise(
                id: "incline_dumbbell_flyes",
                name: "Incline Dumbbell Flyes",
                instructions: "Set bench to 30-45°, perform flyes targeting upper chest with arc motion",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: [],
                tips: ["Focus on upper chest", "Control the negative", "Don't go too heavy"]
            ),
            EnhancedExercise(
                id: "cable_flyes",
                name: "Cable Flyes",
                instructions: "Set cables at chest height, step forward, bring handles together in arc motion",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: [],
                tips: ["Slight forward lean", "Constant tension", "Squeeze chest at peak"]
            ),
            EnhancedExercise(
                id: "incline_cable_flyes",
                name: "Incline Cable Flyes",
                instructions: "Set cables low, perform upward arc motion targeting upper chest",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: [],
                tips: ["Low cable position", "Upward arc motion", "Focus on upper chest"]
            ),
            EnhancedExercise(
                id: "decline_cable_flyes",
                name: "Decline Cable Flyes",
                instructions: "Set cables high, perform downward arc motion targeting lower chest",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: [],
                tips: ["High cable position", "Downward arc motion", "Feel lower chest stretch"]
            ),
            EnhancedExercise(
                id: "pec_deck",
                name: "Pec Deck",
                instructions: "Sit in machine, place forearms on pads, bring arms together squeezing chest",
                equipment: .machine,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: [],
                tips: ["Adjust seat height", "Keep back against pad", "Squeeze and hold"]
            ),
            EnhancedExercise(
                id: "cable_crossovers",
                name: "Cable Crossovers",
                instructions: "High cable position, step forward, bring cables down and across body",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: [],
                tips: ["High cable start", "Cross body motion", "Feel the squeeze"]
            ),
            EnhancedExercise(
                id: "pullovers",
                name: "Dumbbell Pullovers",
                instructions: "Lie across bench, lower dumbbell behind head, pull over to chest",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["lats", "triceps"],
                tips: ["Lie across bench", "Control the stretch", "Don't go too low"]
            ),
            EnhancedExercise(
                id: "cable_pullovers",
                name: "Cable Pullovers",
                instructions: "High cable, straight arm pullover motion from overhead to hips",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["lats"],
                tips: ["Keep arms straight", "Controlled motion", "Feel chest stretch"]
            ),
            EnhancedExercise(
                id: "landmine_press",
                name: "Landmine Press",
                instructions: "One arm barbell press with barbell anchored at floor, press up and across",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["shoulders", "core"],
                tips: ["Anchor barbell securely", "Press up and across", "Core engagement"]
            ),
            EnhancedExercise(
                id: "squeeze_press",
                name: "Dumbbell Squeeze Press",
                instructions: "Hold dumbbells together, press up while maintaining contact between weights",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["triceps"],
                tips: ["Keep dumbbells touching", "Constant tension", "Slow controlled reps"]
            ),
            EnhancedExercise(
                id: "svend_press",
                name: "Svend Press",
                instructions: "Hold weight plates together at chest, press straight out maintaining squeeze",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["chest"],
                secondaryMuscles: [],
                tips: ["Squeeze plates together", "Straight arm extension", "Hold at end range"]
            ),
            
            // BODYWEIGHT VARIATIONS (5)
            EnhancedExercise(
                id: "diamond_push_ups",
                name: "Diamond Push-ups",
                instructions: "Form diamond with hands, perform push-ups targeting triceps and inner chest",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["chest", "triceps"],
                secondaryMuscles: ["shoulders"],
                tips: ["Form diamond with thumbs and fingers", "Keep elbows close", "Harder than regular push-ups"]
            ),
            EnhancedExercise(
                id: "wide_push_ups",
                name: "Wide Push-ups",
                instructions: "Hands wider than shoulders, perform push-ups targeting outer chest",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["shoulders"],
                tips: ["Hands wider than shoulders", "Feel outer chest stretch", "Full range of motion"]
            ),
            EnhancedExercise(
                id: "decline_push_ups",
                name: "Decline Push-ups",
                instructions: "Feet elevated on bench or surface, perform push-ups targeting upper chest",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["shoulders", "triceps"],
                tips: ["Feet higher than hands", "Targets upper chest", "Control the movement"]
            ),
            EnhancedExercise(
                id: "archer_push_ups",
                name: "Archer Push-ups",
                instructions: "Shift weight to one arm during push-up, alternate sides for unilateral chest work",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["shoulders", "triceps", "core"],
                tips: ["Shift weight to working arm", "Keep other arm straight", "Advanced movement"]
            ),
            EnhancedExercise(
                id: "clap_push_ups",
                name: "Clap Push-ups",
                instructions: "Explosive push-up with hands leaving ground to clap, land softly",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["shoulders", "triceps"],
                tips: ["Explosive push off", "Quick clap", "Land softly", "Advanced plyometric"]
            )
        ],
        
        "back": [
            // COMPOUND MOVEMENTS (15)
            EnhancedExercise(
                id: "deadlifts",
                name: "Conventional Deadlifts",
                instructions: "Feet hip-width, grip bar, lift by driving hips forward and extending legs",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["back", "glutes", "hamstrings"],
                secondaryMuscles: ["traps", "forearms", "core"],
                tips: ["Keep bar close to body", "Drive with hips", "Neutral spine"]
            ),
            EnhancedExercise(
                id: "romanian_deadlifts",
                name: "Romanian Deadlifts",
                instructions: "Keep legs slightly bent, hinge at hips, feel hamstring stretch, return to standing",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["hamstrings", "glutes", "back"],
                secondaryMuscles: ["core"],
                tips: ["Hip hinge movement", "Feel hamstring stretch", "Keep knees slightly bent"]
            ),
            EnhancedExercise(
                id: "sumo_deadlifts",
                name: "Sumo Deadlifts",
                instructions: "Wide stance, toes out, grip bar inside legs, lift with vertical torso",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["back", "glutes", "quads"],
                secondaryMuscles: ["traps", "forearms"],
                tips: ["Wide stance", "Toes pointed out", "More upright torso"]
            ),
            EnhancedExercise(
                id: "pull_ups",
                name: "Pull-ups",
                instructions: "Hang from bar with overhand grip, pull body up until chin over bar",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["lats", "rhomboids"],
                secondaryMuscles: ["biceps", "rear delts"],
                tips: ["Full hang at bottom", "Chin over bar", "Control the descent"]
            ),
            EnhancedExercise(
                id: "chin_ups",
                name: "Chin-ups",
                instructions: "Hang from bar with underhand grip, pull body up emphasizing biceps",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["lats", "biceps"],
                secondaryMuscles: ["rhomboids", "rear delts"],
                tips: ["Underhand grip", "More bicep involvement", "Squeeze at top"]
            ),
            EnhancedExercise(
                id: "wide_grip_pull_ups",
                name: "Wide Grip Pull-ups",
                instructions: "Hands wider than shoulders, pull up targeting outer lats and width",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["lats"],
                secondaryMuscles: ["rhomboids", "rear delts"],
                tips: ["Wide hand position", "Focus on lat width", "Harder than regular pull-ups"]
            ),
            EnhancedExercise(
                id: "barbell_rows",
                name: "Bent Over Barbell Rows",
                instructions: "Bent over position, pull barbell to lower chest, squeeze shoulder blades",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["lats", "rhomboids", "middle traps"],
                secondaryMuscles: ["biceps", "rear delts"],
                tips: ["Bent over 45°", "Pull to lower chest", "Squeeze shoulder blades"]
            ),
            EnhancedExercise(
                id: "pendlay_rows",
                name: "Pendlay Rows",
                instructions: "Dead stop barbell rows from floor, explosive pull to chest",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["lats", "rhomboids", "middle traps"],
                secondaryMuscles: ["biceps", "rear delts"],
                tips: ["Start from floor each rep", "Explosive movement", "Pause at chest"]
            ),
            EnhancedExercise(
                id: "t_bar_rows",
                name: "T-Bar Rows",
                instructions: "Straddle T-bar, pull to chest with neutral grip, squeeze back muscles",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["lats", "rhomboids", "middle traps"],
                secondaryMuscles: ["biceps", "rear delts"],
                tips: ["Neutral grip comfortable", "Pull to upper chest", "Squeeze at top"]
            ),
            EnhancedExercise(
                id: "dumbbell_rows",
                name: "Single Arm Dumbbell Rows",
                instructions: "One knee on bench, row dumbbell to hip, squeeze back muscles",
                equipment: .dumbbell,
                category: .compound,
                primaryMuscles: ["lats", "rhomboids"],
                secondaryMuscles: ["biceps", "rear delts"],
                tips: ["Support with opposite hand", "Row to hip", "Squeeze back"]
            ),
            EnhancedExercise(
                id: "seated_cable_rows",
                name: "Seated Cable Rows",
                instructions: "Sit at cable machine, pull handle to chest, squeeze shoulder blades together",
                equipment: .cable,
                category: .compound,
                primaryMuscles: ["lats", "rhomboids", "middle traps"],
                secondaryMuscles: ["biceps", "rear delts"],
                tips: ["Sit up straight", "Pull to lower chest", "Squeeze shoulder blades"]
            ),
            EnhancedExercise(
                id: "lat_pulldowns",
                name: "Lat Pulldowns",
                instructions: "Sit at machine, pull bar to chest with wide grip, control the weight",
                equipment: .machine,
                category: .compound,
                primaryMuscles: ["lats"],
                secondaryMuscles: ["biceps", "rhomboids", "rear delts"],
                tips: ["Lean back slightly", "Pull to upper chest", "Control the negative"]
            ),
            EnhancedExercise(
                id: "inverted_rows",
                name: "Inverted Rows",
                instructions: "Lie under bar, pull chest to bar, keep body straight",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["lats", "rhomboids", "middle traps"],
                secondaryMuscles: ["biceps", "rear delts"],
                tips: ["Keep body straight", "Pull chest to bar", "Great pull-up progression"]
            ),
            EnhancedExercise(
                id: "chest_supported_rows",
                name: "Chest Supported Rows",
                instructions: "Chest against pad, row dumbbells or barbell with strict form",
                equipment: .dumbbell,
                category: .compound,
                primaryMuscles: ["lats", "rhomboids", "middle traps"],
                secondaryMuscles: ["biceps", "rear delts"],
                tips: ["Chest supported eliminates cheating", "Strict form", "Focus on back muscles"]
            ),
            EnhancedExercise(
                id: "landmine_rows",
                name: "Landmine Rows",
                instructions: "Barbell anchored at floor, row with both hands or single arm",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["lats", "rhomboids"],
                secondaryMuscles: ["biceps", "core"],
                tips: ["Anchor barbell securely", "Can be done single or double arm", "Great variation"]
            ),
            
            // ISOLATION MOVEMENTS (10)
            EnhancedExercise(
                id: "straight_arm_pulldowns",
                name: "Straight Arm Pulldowns",
                instructions: "High cable, straight arms, pull down to hips focusing on lats",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["lats"],
                secondaryMuscles: [],
                tips: ["Keep arms straight", "Feel lat stretch at top", "Pull to hips"]
            ),
            EnhancedExercise(
                id: "reverse_flyes",
                name: "Reverse Flyes",
                instructions: "Bent over, raise arms wide targeting rear delts and rhomboids",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["rear delts", "rhomboids"],
                secondaryMuscles: ["middle traps"],
                tips: ["Bent over position", "Raise arms wide", "Squeeze shoulder blades"]
            ),
            EnhancedExercise(
                id: "face_pulls",
                name: "Face Pulls",
                instructions: "Cable at face height, pull to face with elbows high, squeeze rear delts",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["rear delts", "rhomboids"],
                secondaryMuscles: ["middle traps"],
                tips: ["High elbows", "Pull to face", "Great for posture"]
            ),
            EnhancedExercise(
                id: "shrugs",
                name: "Barbell Shrugs",
                instructions: "Hold barbell, shrug shoulders up, squeeze traps at top",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["traps"],
                secondaryMuscles: [],
                tips: ["Straight up and down", "Don't roll shoulders", "Squeeze at top"]
            ),
            EnhancedExercise(
                id: "dumbbell_shrugs",
                name: "Dumbbell Shrugs",
                instructions: "Hold dumbbells at sides, shrug shoulders up, better range than barbell",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["traps"],
                secondaryMuscles: [],
                tips: ["Better range than barbell", "Straight up motion", "Squeeze traps"]
            ),
            EnhancedExercise(
                id: "cable_reverse_flyes",
                name: "Cable Reverse Flyes",
                instructions: "Cross cables at chest height, pull apart with arms wide",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["rear delts", "rhomboids"],
                secondaryMuscles: [],
                tips: ["Cross the cables", "Pull apart with wide arms", "Constant tension"]
            ),
            EnhancedExercise(
                id: "high_pulls",
                name: "High Pulls",
                instructions: "Explosive pull from floor to chest level, emphasizing traps and upper back",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["traps", "rhomboids"],
                secondaryMuscles: ["shoulders"],
                tips: ["Explosive movement", "Pull to chest level", "Advanced technique"]
            ),
            EnhancedExercise(
                id: "cable_shrugs",
                name: "Cable Shrugs",
                instructions: "Low cable position, shrug up with constant tension",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["traps"],
                secondaryMuscles: [],
                tips: ["Low cable position", "Constant tension", "Better than free weights"]
            ),
            EnhancedExercise(
                id: "rack_pulls",
                name: "Rack Pulls",
                instructions: "Deadlift from elevated position in rack, focus on upper back and traps",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["traps", "rhomboids", "lats"],
                secondaryMuscles: ["forearms"],
                tips: ["Start from knee height", "Focus on upper back", "Heavy weight possible"]
            ),
            EnhancedExercise(
                id: "reverse_pec_deck",
                name: "Reverse Pec Deck",
                instructions: "Face away from machine, bring arms back squeezing rear delts",
                equipment: .machine,
                category: .isolation,
                primaryMuscles: ["rear delts", "rhomboids"],
                secondaryMuscles: [],
                tips: ["Face away from machine", "Squeeze rear delts", "Great isolation"]
            ),
            
            // BODYWEIGHT VARIATIONS (5)
            EnhancedExercise(
                id: "superman",
                name: "Superman",
                instructions: "Lie face down, raise chest and legs off ground, squeeze back muscles",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["lower back", "glutes"],
                secondaryMuscles: ["hamstrings"],
                tips: ["Lift chest and legs together", "Squeeze glutes", "Hold briefly"]
            ),
            EnhancedExercise(
                id: "reverse_snow_angels",
                name: "Reverse Snow Angels",
                instructions: "Lie face down, move arms in snow angel pattern squeezing upper back",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["rhomboids", "rear delts"],
                secondaryMuscles: ["middle traps"],
                tips: ["Keep chest lifted", "Squeeze shoulder blades", "Slow controlled movement"]
            ),
            EnhancedExercise(
                id: "prone_y_raises",
                name: "Prone Y Raises",
                instructions: "Lie face down, raise arms in Y position squeezing upper back",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["rear delts", "rhomboids"],
                secondaryMuscles: ["middle traps"],
                tips: ["Form Y with arms", "Squeeze at top", "Great for posture"]
            ),
            EnhancedExercise(
                id: "prone_t_raises",
                name: "Prone T Raises",
                instructions: "Lie face down, raise arms in T position targeting middle traps",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["middle traps", "rhomboids"],
                secondaryMuscles: ["rear delts"],
                tips: ["Form T with arms", "Lift chest slightly", "Focus on middle back"]
            ),
            EnhancedExercise(
                id: "wall_slides",
                name: "Wall Slides",
                instructions: "Back against wall, slide arms up and down maintaining contact",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["rhomboids", "middle traps"],
                secondaryMuscles: ["rear delts"],
                tips: ["Keep back flat against wall", "Maintain arm contact", "Great for posture"]
            )
        ],
        
        "legs": [
            // COMPOUND MOVEMENTS (20)
            EnhancedExercise(
                id: "back_squats",
                name: "Back Squats",
                instructions: "Bar on upper back, feet shoulder-width, descend until thighs parallel, drive up",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["hamstrings", "core"],
                tips: ["Keep chest up", "Knees track over toes", "Full depth if mobility allows"]
            ),
            EnhancedExercise(
                id: "front_squats",
                name: "Front Squats",
                instructions: "Bar across front shoulders, squat down keeping torso upright",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["quads"],
                secondaryMuscles: ["glutes", "core"],
                tips: ["Keep elbows up", "More upright torso", "Great for quad development"]
            ),
            EnhancedExercise(
                id: "goblet_squats",
                name: "Goblet Squats",
                instructions: "Hold dumbbell at chest, squat down between legs, drive up",
                equipment: .dumbbell,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["core"],
                tips: ["Hold weight at chest", "Squat between legs", "Great beginner movement"]
            ),
            EnhancedExercise(
                id: "overhead_squats",
                name: "Overhead Squats",
                instructions: "Hold barbell overhead, squat while maintaining arm position",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["shoulders", "core"],
                tips: ["Requires great mobility", "Keep arms locked", "Advanced movement"]
            ),
            EnhancedExercise(
                id: "bulgarian_split_squats",
                name: "Bulgarian Split Squats",
                instructions: "Rear foot elevated, lower into lunge position, drive up",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["hamstrings"],
                tips: ["Most weight on front leg", "Don't bounce off back leg", "Great unilateral exercise"]
            ),
            EnhancedExercise(
                id: "walking_lunges",
                name: "Walking Lunges",
                instructions: "Step forward into lunge, push off to step into next lunge",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["hamstrings", "calves"],
                tips: ["Step forward, not down", "Keep torso upright", "Push off front leg"]
            ),
            EnhancedExercise(
                id: "reverse_lunges",
                name: "Reverse Lunges",
                instructions: "Step backward into lunge position, push back to start",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["hamstrings"],
                tips: ["Step back, not forward", "Easier on knees", "Control the descent"]
            ),
            EnhancedExercise(
                id: "lateral_lunges",
                name: "Lateral Lunges",
                instructions: "Step to side, lower into side lunge, push back to center",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["adductors", "hamstrings"],
                tips: ["Step wide to side", "Keep one leg straight", "Great for lateral movement"]
            ),
            EnhancedExercise(
                id: "curtsy_lunges",
                name: "Curtsy Lunges",
                instructions: "Step back and across behind standing leg, lower into curtsy position",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["glutes", "quads"],
                secondaryMuscles: ["hamstrings"],
                tips: ["Step back and across", "Like doing a curtsy", "Great for glutes"]
            ),
            EnhancedExercise(
                id: "leg_press",
                name: "Leg Press",
                instructions: "Sit in machine, press weight with legs, control descent",
                equipment: .machine,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["hamstrings"],
                tips: ["Full range of motion", "Don't lock knees", "Control the weight"]
            ),
            EnhancedExercise(
                id: "hack_squats",
                name: "Hack Squats",
                instructions: "Back against pad in hack squat machine, squat down and up",
                equipment: .machine,
                category: .compound,
                primaryMuscles: ["quads"],
                secondaryMuscles: ["glutes"],
                tips: ["Back flat against pad", "Great quad isolation", "Full range of motion"]
            ),
            EnhancedExercise(
                id: "step_ups",
                name: "Step-ups",
                instructions: "Step up onto bench or box, step down with control",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["hamstrings", "calves"],
                tips: ["Step up, don't push off bottom leg", "Control the descent", "Great functional movement"]
            ),
            EnhancedExercise(
                id: "box_squats",
                name: "Box Squats",
                instructions: "Squat down to touch box, pause briefly, drive up explosively",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["hamstrings"],
                tips: ["Sit back to box", "Brief pause", "Explosive drive up"]
            ),
            EnhancedExercise(
                id: "pistol_squats",
                name: "Pistol Squats",
                instructions: "Single leg squat with other leg extended forward",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["hamstrings", "core"],
                tips: ["Single leg squat", "Requires great mobility", "Advanced bodyweight movement"]
            ),
            EnhancedExercise(
                id: "jump_squats",
                name: "Jump Squats",
                instructions: "Squat down, explode up into jump, land softly",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["calves"],
                tips: ["Explosive jump", "Land softly", "Great for power"]
            ),
            EnhancedExercise(
                id: "single_leg_deadlifts",
                name: "Single Leg Deadlifts",
                instructions: "Balance on one leg, hinge at hip, touch ground, return to standing",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["hamstrings", "glutes"],
                secondaryMuscles: ["core"],
                tips: ["Balance on one leg", "Hip hinge movement", "Great for stability"]
            ),
            EnhancedExercise(
                id: "stiff_leg_deadlifts",
                name: "Stiff Leg Deadlifts",
                instructions: "Keep legs straight, hinge at hips, feel hamstring stretch",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["hamstrings", "glutes"],
                secondaryMuscles: ["lower back"],
                tips: ["Keep legs straight", "Hip hinge movement", "Feel hamstring stretch"]
            ),
            EnhancedExercise(
                id: "sumo_squats",
                name: "Sumo Squats",
                instructions: "Wide stance, toes out, squat down emphasizing inner thighs",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["adductors"],
                tips: ["Wide stance", "Toes pointed out", "Emphasizes inner thighs"]
            ),
            EnhancedExercise(
                id: "thruster",
                name: "Thrusters",
                instructions: "Front squat combined with overhead press in one fluid movement",
                equipment: .dumbbell,
                category: .compound,
                primaryMuscles: ["quads", "glutes", "shoulders"],
                secondaryMuscles: ["core"],
                tips: ["Squat then press", "Fluid movement", "Full body exercise"]
            ),
            EnhancedExercise(
                id: "wall_sits",
                name: "Wall Sits",
                instructions: "Back against wall, slide down to squat position, hold",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["quads"],
                secondaryMuscles: ["glutes"],
                tips: ["Back flat against wall", "Thighs parallel to ground", "Isometric hold"]
            ),
            
            // ISOLATION MOVEMENTS (10)
            EnhancedExercise(
                id: "leg_extensions",
                name: "Leg Extensions",
                instructions: "Sit in machine, extend legs straight, control descent",
                equipment: .machine,
                category: .isolation,
                primaryMuscles: ["quads"],
                secondaryMuscles: [],
                tips: ["Control the weight", "Full extension", "Squeeze at top"]
            ),
            EnhancedExercise(
                id: "leg_curls",
                name: "Lying Leg Curls",
                instructions: "Lie face down, curl heels toward glutes",
                equipment: .machine,
                category: .isolation,
                primaryMuscles: ["hamstrings"],
                secondaryMuscles: [],
                tips: ["Lie flat", "Curl heels to glutes", "Control the negative"]
            ),
            EnhancedExercise(
                id: "seated_leg_curls",
                name: "Seated Leg Curls",
                instructions: "Sit in machine, curl legs down from extended position",
                equipment: .machine,
                category: .isolation,
                primaryMuscles: ["hamstrings"],
                secondaryMuscles: [],
                tips: ["Sit back in machine", "Curl down with control", "Different angle than lying"]
            ),
            EnhancedExercise(
                id: "calf_raises",
                name: "Standing Calf Raises",
                instructions: "Rise up on toes, hold briefly, lower slowly",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["calves"],
                secondaryMuscles: [],
                tips: ["Full range of motion", "Pause at top", "Slow controlled descent"]
            ),
            EnhancedExercise(
                id: "seated_calf_raises",
                name: "Seated Calf Raises",
                instructions: "Sit with weight on thighs, raise up on toes",
                equipment: .machine,
                category: .isolation,
                primaryMuscles: ["calves"],
                secondaryMuscles: [],
                tips: ["Weight on thighs", "Different muscle emphasis", "Full range of motion"]
            ),
            EnhancedExercise(
                id: "hip_thrusts",
                name: "Hip Thrusts",
                instructions: "Upper back on bench, thrust hips up squeezing glutes",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["glutes"],
                secondaryMuscles: ["hamstrings"],
                tips: ["Upper back on bench", "Squeeze glutes at top", "Great glute exercise"]
            ),
            EnhancedExercise(
                id: "glute_bridges",
                name: "Glute Bridges",
                instructions: "Lie on back, thrust hips up squeezing glutes",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["glutes"],
                secondaryMuscles: ["hamstrings"],
                tips: ["Lie flat on back", "Squeeze glutes at top", "Great for activation"]
            ),
            EnhancedExercise(
                id: "adductor_machine",
                name: "Adductor Machine",
                instructions: "Sit in machine, bring legs together against resistance",
                equipment: .machine,
                category: .isolation,
                primaryMuscles: ["adductors"],
                secondaryMuscles: [],
                tips: ["Bring legs together", "Control the movement", "Inner thigh focus"]
            ),
            EnhancedExercise(
                id: "abductor_machine",
                name: "Abductor Machine",
                instructions: "Sit in machine, push legs apart against resistance",
                equipment: .machine,
                category: .isolation,
                primaryMuscles: ["abductors"],
                secondaryMuscles: [],
                tips: ["Push legs apart", "Control the movement", "Outer thigh focus"]
            ),
            EnhancedExercise(
                id: "single_leg_calf_raises",
                name: "Single Leg Calf Raises",
                instructions: "Balance on one leg, raise up on toe, control descent",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["calves"],
                secondaryMuscles: [],
                tips: ["Single leg balance", "Full range of motion", "More challenging than bilateral"]
            ),
            
            // BODYWEIGHT VARIATIONS (5)
            EnhancedExercise(
                id: "bodyweight_squats",
                name: "Bodyweight Squats",
                instructions: "Arms out front, squat down, drive up using body weight only",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["hamstrings"],
                tips: ["Arms out for balance", "Full range of motion", "Great starting point"]
            ),
            EnhancedExercise(
                id: "broad_jumps",
                name: "Broad Jumps",
                instructions: "Jump forward as far as possible, land softly",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["calves"],
                tips: ["Jump forward, not up", "Land softly", "Great for power"]
            ),
            EnhancedExercise(
                id: "split_jumps",
                name: "Split Jumps",
                instructions: "Jump up switching legs in air, land in opposite lunge",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["calves"],
                tips: ["Switch legs in air", "Land softly", "Plyometric exercise"]
            ),
            EnhancedExercise(
                id: "single_leg_glute_bridges",
                name: "Single Leg Glute Bridges",
                instructions: "One leg extended, thrust up with other leg",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["glutes"],
                secondaryMuscles: ["hamstrings"],
                tips: ["One leg working", "Squeeze glute at top", "Great unilateral exercise"]
            ),
            EnhancedExercise(
                id: "duck_walks",
                name: "Duck Walks",
                instructions: "Stay in squat position, walk forward maintaining low position",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["quads", "glutes"],
                secondaryMuscles: ["calves"],
                tips: ["Stay low in squat", "Walk forward/backward", "Great for endurance"]
            )
        ],
        
        "shoulders": [
            // COMPOUND MOVEMENTS (8)
            EnhancedExercise(
                id: "overhead_press",
                name: "Standing Overhead Press",
                instructions: "Press bar or dumbbells overhead from shoulder level, keep core tight",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["triceps", "core"],
                tips: ["Keep core tight", "Press straight up", "Don't arch back excessively"]
            ),
            EnhancedExercise(
                id: "seated_overhead_press",
                name: "Seated Overhead Press",
                instructions: "Sit with back support, press dumbbells or barbell overhead",
                equipment: .dumbbell,
                category: .compound,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["triceps"],
                tips: ["Back supported", "Less core involvement", "Good for isolation"]
            ),
            EnhancedExercise(
                id: "dumbbell_shoulder_press",
                name: "Dumbbell Shoulder Press",
                instructions: "Press dumbbells from shoulder level to overhead",
                equipment: .dumbbell,
                category: .compound,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["triceps"],
                tips: ["Independent arm movement", "Greater range than barbell", "Control the dumbbells"]
            ),
            EnhancedExercise(
                id: "arnold_press",
                name: "Arnold Press",
                instructions: "Start palms facing you, rotate and press overhead",
                equipment: .dumbbell,
                category: .compound,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["triceps"],
                tips: ["Start palms facing you", "Rotate as you press", "Named after Arnold Schwarzenegger"]
            ),
            EnhancedExercise(
                id: "push_press",
                name: "Push Press",
                instructions: "Use leg drive to help press weight overhead",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["triceps", "legs"],
                tips: ["Use leg drive", "More weight than strict press", "Explosive movement"]
            ),
            EnhancedExercise(
                id: "pike_push_ups",
                name: "Pike Push-ups",
                instructions: "Downward dog position, lower head to ground, press up",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["triceps"],
                tips: ["Pike position", "Lower head to ground", "Great bodyweight shoulder exercise"]
            ),
            EnhancedExercise(
                id: "handstand_push_ups",
                name: "Handstand Push-ups",
                instructions: "Wall handstand, lower head to ground, press back up",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["triceps", "core"],
                tips: ["Against wall for safety", "Advanced movement", "Great strength builder"]
            ),
            EnhancedExercise(
                id: "landmine_press",
                name: "Single Arm Landmine Press",
                instructions: "Barbell anchored at floor, press up and across body",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["core", "triceps"],
                tips: ["Anchor barbell securely", "Press up and across", "Great variation"]
            ),
            
            // ISOLATION MOVEMENTS (8)
            EnhancedExercise(
                id: "lateral_raises",
                name: "Lateral Raises",
                instructions: "Arms at sides, raise dumbbells to shoulder height out to sides",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: [],
                tips: ["Raise to shoulder height", "Control the weight", "Don't swing"]
            ),
            EnhancedExercise(
                id: "front_raises",
                name: "Front Raises",
                instructions: "Raise dumbbells in front to shoulder height",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: [],
                tips: ["Raise to shoulder height", "Control the movement", "Don't swing"]
            ),
            EnhancedExercise(
                id: "rear_delt_flyes",
                name: "Rear Delt Flyes",
                instructions: "Bent over, raise arms wide targeting rear delts",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["rear delts"],
                secondaryMuscles: [],
                tips: ["Bent over position", "Squeeze shoulder blades", "Often neglected muscle"]
            ),
            EnhancedExercise(
                id: "cable_lateral_raises",
                name: "Cable Lateral Raises",
                instructions: "Low cable, raise arm to side with constant tension",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: [],
                tips: ["Constant tension", "Low cable position", "One arm at a time"]
            ),
            EnhancedExercise(
                id: "upright_rows",
                name: "Upright Rows",
                instructions: "Pull bar up along body to chest height, elbows high",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["shoulders", "traps"],
                secondaryMuscles: [],
                tips: ["Pull to chest height", "Elbows high", "Can irritate some shoulders"]
            ),
            EnhancedExercise(
                id: "cable_rear_delt_flyes",
                name: "Cable Rear Delt Flyes",
                instructions: "High cable, pull handles apart targeting rear delts",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["rear delts"],
                secondaryMuscles: [],
                tips: ["High cable position", "Pull apart", "Squeeze rear delts"]
            ),
            EnhancedExercise(
                id: "reverse_pec_deck",
                name: "Reverse Pec Deck",
                instructions: "Face away from machine, bring arms back",
                equipment: .machine,
                category: .isolation,
                primaryMuscles: ["rear delts"],
                secondaryMuscles: [],
                tips: ["Face away from machine", "Controlled movement", "Great rear delt isolation"]
            ),
            EnhancedExercise(
                id: "shoulder_shrugs",
                name: "Shoulder Shrugs",
                instructions: "Hold weight, shrug shoulders up toward ears",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["traps"],
                secondaryMuscles: [],
                tips: ["Straight up and down", "Squeeze at top", "Don't roll shoulders"]
            ),
            
            // BODYWEIGHT VARIATIONS (4)
            EnhancedExercise(
                id: "wall_handstand_hold",
                name: "Wall Handstand Hold",
                instructions: "Kick up to handstand against wall, hold position",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["core", "triceps"],
                tips: ["Use wall for support", "Build up hold time", "Advanced exercise"]
            ),
            EnhancedExercise(
                id: "bear_crawl",
                name: "Bear Crawl",
                instructions: "Hands and feet on ground, crawl forward keeping knees off ground",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["core", "legs"],
                tips: ["Keep knees just off ground", "Crawl forward/backward", "Great stability exercise"]
            ),
            EnhancedExercise(
                id: "crab_walk",
                name: "Crab Walk",
                instructions: "Sit, hands behind, lift hips, walk on hands and feet",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["shoulders"],
                secondaryMuscles: ["triceps", "glutes"],
                tips: ["Keep hips up", "Walk backward mainly", "Great for posterior chain"]
            ),
            EnhancedExercise(
                id: "wall_angels",
                name: "Wall Angels",
                instructions: "Back against wall, move arms like snow angels maintaining wall contact",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["rear delts"],
                secondaryMuscles: ["rhomboids"],
                tips: ["Maintain wall contact", "Slow controlled movement", "Great for mobility"]
            )
        ],
        
        "arms": [
            // BICEP EXERCISES (12)
            EnhancedExercise(
                id: "barbell_bicep_curls",
                name: "Barbell Bicep Curls",
                instructions: "Arms at sides, curl barbell up with biceps, control descent",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["biceps"],
                secondaryMuscles: ["forearms"],
                tips: ["Keep elbows close to body", "Control the negative", "Full range of motion"]
            ),
            EnhancedExercise(
                id: "dumbbell_bicep_curls",
                name: "Dumbbell Bicep Curls",
                instructions: "Curl dumbbells alternating or together, focus on bicep contraction",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["biceps"],
                secondaryMuscles: ["forearms"],
                tips: ["Can alternate or together", "Supinate at top", "Control the weight"]
            ),
            EnhancedExercise(
                id: "hammer_curls",
                name: "Hammer Curls",
                instructions: "Neutral grip, curl dumbbells without rotating wrists",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["biceps", "brachialis"],
                secondaryMuscles: ["forearms"],
                tips: ["Neutral grip throughout", "Targets brachialis", "Don't rotate wrists"]
            ),
            EnhancedExercise(
                id: "preacher_curls",
                name: "Preacher Curls",
                instructions: "Arms on preacher bench, curl weight with strict form",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["biceps"],
                secondaryMuscles: [],
                tips: ["Arms supported", "Strict form", "Great for isolation"]
            ),
            EnhancedExercise(
                id: "cable_bicep_curls",
                name: "Cable Bicep Curls",
                instructions: "Low cable, curl handle up with constant tension",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["biceps"],
                secondaryMuscles: ["forearms"],
                tips: ["Constant tension", "Various handle options", "Control the movement"]
            ),
            EnhancedExercise(
                id: "concentration_curls",
                name: "Concentration Curls",
                instructions: "Seated, elbow braced on thigh, curl dumbbell with focus",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["biceps"],
                secondaryMuscles: [],
                tips: ["Elbow braced on thigh", "Great for peak contraction", "Strict form"]
            ),
            EnhancedExercise(
                id: "incline_bicep_curls",
                name: "Incline Bicep Curls",
                instructions: "On incline bench, curl dumbbells with arms hanging back",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["biceps"],
                secondaryMuscles: [],
                tips: ["Arms hang back on incline", "Great stretch position", "Control the negative"]
            ),
            EnhancedExercise(
                id: "spider_curls",
                name: "Spider Curls",
                instructions: "Chest against incline bench, curl dumbbells hanging down",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["biceps"],
                secondaryMuscles: [],
                tips: ["Chest against bench", "Arms hanging down", "Strict isolation"]
            ),
            EnhancedExercise(
                id: "21s_bicep_curls",
                name: "21s Bicep Curls",
                instructions: "7 bottom half reps, 7 top half reps, 7 full reps",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["biceps"],
                secondaryMuscles: [],
                tips: ["21 total reps", "Bottom half, top half, full", "Intense bicep exercise"]
            ),
            EnhancedExercise(
                id: "cable_hammer_curls",
                name: "Cable Hammer Curls",
                instructions: "Rope attachment, curl with neutral grip maintaining rope position",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["biceps", "brachialis"],
                secondaryMuscles: ["forearms"],
                tips: ["Rope attachment", "Neutral grip", "Don't let rope spread"]
            ),
            EnhancedExercise(
                id: "chin_ups",
                name: "Chin-ups (Bicep Focus)",
                instructions: "Underhand grip pull-ups emphasizing bicep engagement",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["biceps", "lats"],
                secondaryMuscles: ["rhomboids"],
                tips: ["Underhand grip", "Focus on biceps", "Chin over bar"]
            ),
            EnhancedExercise(
                id: "zottman_curls",
                name: "Zottman Curls",
                instructions: "Curl up with palms up, rotate to palms down, lower slowly",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["biceps"],
                secondaryMuscles: ["forearms"],
                tips: ["Rotate at top", "Lower slowly with palms down", "Great for forearms too"]
            ),
            
            // TRICEP EXERCISES (13)
            EnhancedExercise(
                id: "close_grip_bench_press",
                name: "Close Grip Bench Press",
                instructions: "Narrow grip bench press focusing on triceps",
                equipment: .barbell,
                category: .compound,
                primaryMuscles: ["triceps"],
                secondaryMuscles: ["chest", "shoulders"],
                tips: ["Hands closer than shoulder width", "Keep elbows close", "Focus on triceps"]
            ),
            EnhancedExercise(
                id: "tricep_dips",
                name: "Tricep Dips",
                instructions: "Hands on bench or bars, lower body, press up with triceps",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["triceps"],
                secondaryMuscles: ["shoulders", "chest"],
                tips: ["Keep torso upright", "Lower until 90°", "Push through palms"]
            ),
            EnhancedExercise(
                id: "overhead_tricep_extension",
                name: "Overhead Tricep Extension",
                instructions: "Weight overhead, lower behind head, extend back up",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["triceps"],
                secondaryMuscles: [],
                tips: ["Keep elbows stationary", "Lower behind head", "Full stretch"]
            ),
            EnhancedExercise(
                id: "tricep_pushdowns",
                name: "Tricep Pushdowns",
                instructions: "High cable, push down extending triceps fully",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["triceps"],
                secondaryMuscles: [],
                tips: ["Keep elbows stationary", "Full extension", "Squeeze at bottom"]
            ),
            EnhancedExercise(
                id: "diamond_push_ups",
                name: "Diamond Push-ups",
                instructions: "Form diamond with hands, perform push-ups targeting triceps",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["triceps"],
                secondaryMuscles: ["chest", "shoulders"],
                tips: ["Diamond shape with hands", "Keep elbows close", "Harder than regular push-ups"]
            ),
            EnhancedExercise(
                id: "tricep_kickbacks",
                name: "Tricep Kickbacks",
                instructions: "Bent over, extend dumbbell back squeezing tricep",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["triceps"],
                secondaryMuscles: [],
                tips: ["Keep upper arm stationary", "Squeeze at full extension", "Light weight"]
            ),
            EnhancedExercise(
                id: "lying_tricep_extensions",
                name: "Lying Tricep Extensions",
                instructions: "Lie down, lower weight to forehead, extend up",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["triceps"],
                secondaryMuscles: [],
                tips: ["Lower to forehead", "Keep elbows stationary", "Also called skull crushers"]
            ),
            EnhancedExercise(
                id: "rope_pushdowns",
                name: "Rope Pushdowns",
                instructions: "Cable with rope, push down and spread rope at bottom",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["triceps"],
                secondaryMuscles: [],
                tips: ["Spread rope at bottom", "Full extension", "Squeeze triceps"]
            ),
            EnhancedExercise(
                id: "reverse_grip_pushdowns",
                name: "Reverse Grip Pushdowns",
                instructions: "Cable pushdown with underhand grip",
                equipment: .cable,
                category: .isolation,
                primaryMuscles: ["triceps"],
                secondaryMuscles: [],
                tips: ["Underhand grip", "Different tricep emphasis", "Keep elbows stable"]
            ),
            EnhancedExercise(
                id: "bench_dips",
                name: "Bench Dips",
                instructions: "Hands on bench behind you, lower and raise body",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["triceps"],
                secondaryMuscles: ["shoulders"],
                tips: ["Hands on bench behind", "Lower until 90°", "Can add weight on lap"]
            ),
            EnhancedExercise(
                id: "single_arm_tricep_extension",
                name: "Single Arm Tricep Extension",
                instructions: "One arm overhead extension focusing on unilateral tricep work",
                equipment: .dumbbell,
                category: .isolation,
                primaryMuscles: ["triceps"],
                secondaryMuscles: [],
                tips: ["One arm at a time", "Keep elbow stationary", "Full range of motion"]
            ),
            EnhancedExercise(
                id: "tricep_push_ups",
                name: "Tricep Push-ups",
                instructions: "Hands close together, elbows back, emphasizing triceps",
                equipment: .bodyweight,
                category: .compound,
                primaryMuscles: ["triceps"],
                secondaryMuscles: ["chest", "shoulders"],
                tips: ["Hands close together", "Elbows back along body", "Focus on triceps"]
            ),
            EnhancedExercise(
                id: "jm_press",
                name: "JM Press",
                instructions: "Hybrid between close grip press and tricep extension",
                equipment: .barbell,
                category: .isolation,
                primaryMuscles: ["triceps"],
                secondaryMuscles: [],
                tips: ["Advanced technique", "Combines two movements", "Lower to throat/upper chest"]
            )
        ],
        
        "core": [
            // STATIC EXERCISES (8)
            EnhancedExercise(
                id: "planks",
                name: "Planks",
                instructions: "Hold push-up position, keep body straight, engage core",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["core"],
                secondaryMuscles: ["shoulders", "glutes"],
                tips: ["Keep body straight", "Don't let hips sag", "Breathe normally"]
            ),
            EnhancedExercise(
                id: "side_planks",
                name: "Side Planks",
                instructions: "Lie on side, prop up on elbow, lift hips creating straight line",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["core", "obliques"],
                secondaryMuscles: ["shoulders"],
                tips: ["Straight line from head to feet", "Don't let hips drop", "Both sides"]
            ),
            EnhancedExercise(
                id: "hollow_body_hold",
                name: "Hollow Body Hold",
                instructions: "Lie on back, press lower back down, hold position",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["core"],
                secondaryMuscles: [],
                tips: ["Press lower back to floor", "Lift shoulders and feet", "Hold the position"]
            ),
            EnhancedExercise(
                id: "bear_crawl_hold",
                name: "Bear Crawl Hold",
                instructions: "Hands and feet on ground, knees just off ground, hold",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["core"],
                secondaryMuscles: ["shoulders", "legs"],
                tips: ["Knees just off ground", "Flat back", "Hold the position"]
            ),
            EnhancedExercise(
                id: "l_sit",
                name: "L-Sit",
                instructions: "Support body on hands, legs straight out forming L shape",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["core"],
                secondaryMuscles: ["shoulders", "triceps"],
                tips: ["Advanced exercise", "Legs straight out", "Support on hands"]
            ),
            EnhancedExercise(
                id: "wall_sit_hold",
                name: "Wall Sit Hold",
                instructions: "Back against wall in squat position, hold",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["core", "quads"],
                secondaryMuscles: ["glutes"],
                tips: ["Back flat against wall", "Thighs parallel", "Isometric hold"]
            ),
            EnhancedExercise(
                id: "single_arm_plank",
                name: "Single Arm Plank",
                instructions: "Plank position, lift one arm forward, hold",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["core"],
                secondaryMuscles: ["shoulders"],
                tips: ["Lift one arm", "Don't rotate hips", "Advanced stability"]
            ),
            EnhancedExercise(
                id: "dead_bug_hold",
                name: "Dead Bug Hold",
                instructions: "On back, opposite arm and leg extended, hold position",
                equipment: .bodyweight,
                category: .bodyweight,
                primaryMuscles: ["core"],
                secondaryMuscles: [],
                tips: ["Opposite arm and leg", "Keep lower back pressed down", "Hold position"]
            ),
            
            // DYNAMIC EXERCISES (8)
            EnhancedExercise(
                id: "crunches",
                name: "Crunches",
                instructions: "Lie down, hands behind head, crunch up engaging abs",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core"],
                secondaryMuscles: [],
                tips: ["Don't pull on neck", "Crunch up, not just lift", "Squeeze abs"]
            ),
            EnhancedExercise(
                id: "bicycle_crunches",
                name: "Bicycle Crunches",
                instructions: "Alternate bringing elbow to opposite knee in cycling motion",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core", "obliques"],
                secondaryMuscles: [],
                tips: ["Bicycle motion", "Elbow to opposite knee", "Control the movement"]
            ),
            EnhancedExercise(
                id: "russian_twists",
                name: "Russian Twists",
                instructions: "Sit with feet up, rotate torso side to side",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core", "obliques"],
                secondaryMuscles: [],
                tips: ["Feet off ground", "Rotate side to side", "Can add weight"]
            ),
            EnhancedExercise(
                id: "mountain_climbers",
                name: "Mountain Climbers",
                instructions: "Plank position, alternate bringing knees to chest quickly",
                equipment: .bodyweight,
                category: .cardio,
                primaryMuscles: ["core"],
                secondaryMuscles: ["shoulders", "legs"],
                tips: ["Fast alternating legs", "Keep hips level", "Cardio element"]
            ),
            EnhancedExercise(
                id: "dead_bugs",
                name: "Dead Bugs",
                instructions: "On back, opposite arm/leg extensions while keeping core tight",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core"],
                secondaryMuscles: [],
                tips: ["Opposite arm and leg", "Keep core engaged", "Great for stability"]
            ),
            EnhancedExercise(
                id: "leg_raises",
                name: "Leg Raises",
                instructions: "Lie down, raise straight legs up and lower slowly",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core"],
                secondaryMuscles: ["hip flexors"],
                tips: ["Keep legs straight", "Control the descent", "Don't let feet touch ground"]
            ),
            EnhancedExercise(
                id: "flutter_kicks",
                name: "Flutter Kicks",
                instructions: "Lie on back, alternate small leg kicks keeping legs straight",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core"],
                secondaryMuscles: ["hip flexors"],
                tips: ["Small quick kicks", "Keep legs straight", "Core engaged"]
            ),
            EnhancedExercise(
                id: "v_ups",
                name: "V-Ups",
                instructions: "Lie flat, simultaneously raise legs and torso to form V",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core"],
                secondaryMuscles: [],
                tips: ["Legs and torso up together", "Form V shape", "Advanced crunch variation"]
            ),
            
            // HANGING EXERCISES (4)
            EnhancedExercise(
                id: "hanging_leg_raises",
                name: "Hanging Leg Raises",
                instructions: "Hang from pull-up bar, raise legs up to 90 degrees, lower with control",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core"],
                secondaryMuscles: ["hip flexors", "forearms"],
                tips: ["Hang from bar", "Raise legs to 90°", "Control the negative"]
            ),
            EnhancedExercise(
                id: "hanging_knee_raises",
                name: "Hanging Knee Raises",
                instructions: "Hang from bar, bring knees to chest, lower with control",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core"],
                secondaryMuscles: ["hip flexors", "forearms"],
                tips: ["Easier than straight leg", "Knees to chest", "Good progression"]
            ),
            EnhancedExercise(
                id: "windshield_wipers",
                name: "Windshield Wipers",
                instructions: "Hanging with legs up, rotate legs side to side",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core", "obliques"],
                secondaryMuscles: ["forearms"],
                tips: ["Legs up in L position", "Rotate side to side", "Advanced exercise"]
            ),
            EnhancedExercise(
                id: "toes_to_bar",
                name: "Toes to Bar",
                instructions: "Hang from bar, bring toes all the way up to touch bar",
                equipment: .bodyweight,
                category: .isolation,
                primaryMuscles: ["core"],
                secondaryMuscles: ["hip flexors", "lats", "forearms"],
                tips: ["Toes touch the bar", "Use lat pulldown motion", "Very advanced"]
            )
        ]
    ]
}