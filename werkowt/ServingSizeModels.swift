import Foundation

// MARK: - Serving Size Models

struct ServingSize: Identifiable, Codable {
    let id: UUID
    let name: String              // "1 medium", "1 cup", "100ml"
    let gramsEquivalent: Double   // Weight equivalent for nutrition calculation
    let volumeML: Double?         // For liquids/volume-based servings
    let category: ServingCategory
    let isStandard: Bool          // true for universal servings like "100g"
    let foodCategory: FoodCategory? // nil if applies to all foods
    
    init(
        id: UUID = UUID(),
        name: String,
        gramsEquivalent: Double,
        volumeML: Double? = nil,
        category: ServingCategory,
        isStandard: Bool = false,
        foodCategory: FoodCategory? = nil
    ) {
        self.id = id
        self.name = name
        self.gramsEquivalent = gramsEquivalent
        self.volumeML = volumeML
        self.category = category
        self.isStandard = isStandard
        self.foodCategory = foodCategory
    }
}

enum ServingCategory: String, CaseIterable, Codable {
    case weight = "weight"        // 100g, 50g, 250g
    case volume = "volume"        // 100ml, 1 cup, 1 tbsp
    case piece = "piece"          // 1 medium, 1 slice, 1 piece
    case custom = "custom"        // user-defined
    
    var displayName: String {
        switch self {
        case .weight: return "Weight"
        case .volume: return "Volume"
        case .piece: return "Piece/Unit"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .weight: return "scalemass"
        case .volume: return "drop"
        case .piece: return "circle"
        case .custom: return "person.fill"
        }
    }
}

enum FoodCategory: String, CaseIterable, Codable {
    case fruits = "fruits"
    case vegetables = "vegetables"
    case dairy = "dairy"
    case grains = "grains"
    case protein = "protein"
    case beverages = "beverages"
    case snacks = "snacks"
    case desserts = "desserts"
    case condiments = "condiments"
    
    var displayName: String {
        switch self {
        case .fruits: return "Fruits"
        case .vegetables: return "Vegetables"
        case .dairy: return "Dairy"
        case .grains: return "Grains"
        case .protein: return "Protein"
        case .beverages: return "Beverages"
        case .snacks: return "Snacks"
        case .desserts: return "Desserts"
        case .condiments: return "Condiments"
        }
    }
}

// MARK: - Standard Serving Sizes

extension ServingSize {
    
    static let standardServingSizes: [ServingSize] = [
        // Universal weight servings
        ServingSize(name: "100g", gramsEquivalent: 100, category: .weight, isStandard: true),
        ServingSize(name: "50g", gramsEquivalent: 50, category: .weight, isStandard: true),
        ServingSize(name: "25g", gramsEquivalent: 25, category: .weight, isStandard: true),
        ServingSize(name: "250g", gramsEquivalent: 250, category: .weight, isStandard: true),
        
        // Universal volume servings
        ServingSize(name: "100ml", gramsEquivalent: 100, volumeML: 100, category: .volume, isStandard: true),
        ServingSize(name: "250ml", gramsEquivalent: 250, volumeML: 250, category: .volume, isStandard: true),
        ServingSize(name: "500ml", gramsEquivalent: 500, volumeML: 500, category: .volume, isStandard: true),
        ServingSize(name: "1 cup (240ml)", gramsEquivalent: 240, volumeML: 240, category: .volume, isStandard: true),
        ServingSize(name: "1/2 cup (120ml)", gramsEquivalent: 120, volumeML: 120, category: .volume, isStandard: true),
        ServingSize(name: "1 tablespoon", gramsEquivalent: 15, volumeML: 15, category: .volume, isStandard: true),
        ServingSize(name: "1 teaspoon", gramsEquivalent: 5, volumeML: 5, category: .volume, isStandard: true),
        
        // Fruit servings
        ServingSize(name: "1 small", gramsEquivalent: 80, category: .piece, foodCategory: .fruits),
        ServingSize(name: "1 medium", gramsEquivalent: 120, category: .piece, foodCategory: .fruits),
        ServingSize(name: "1 large", gramsEquivalent: 180, category: .piece, foodCategory: .fruits),
        
        // Dairy servings
        ServingSize(name: "1 cup", gramsEquivalent: 240, volumeML: 240, category: .volume, foodCategory: .dairy),
        ServingSize(name: "1 slice (20g)", gramsEquivalent: 20, category: .piece, foodCategory: .dairy),
        ServingSize(name: "1 serving (30g)", gramsEquivalent: 30, category: .piece, foodCategory: .dairy),
        
        // Grain servings
        ServingSize(name: "1 slice", gramsEquivalent: 25, category: .piece, foodCategory: .grains),
        ServingSize(name: "1 cup cooked", gramsEquivalent: 175, category: .volume, foodCategory: .grains),
        ServingSize(name: "1/2 cup cooked", gramsEquivalent: 90, category: .volume, foodCategory: .grains),
        
        // Protein servings
        ServingSize(name: "1 piece (100g)", gramsEquivalent: 100, category: .piece, foodCategory: .protein),
        ServingSize(name: "1 serving (150g)", gramsEquivalent: 150, category: .piece, foodCategory: .protein),
        
        // Beverage servings
        ServingSize(name: "1 can (330ml)", gramsEquivalent: 330, volumeML: 330, category: .volume, foodCategory: .beverages),
        ServingSize(name: "1 bottle (500ml)", gramsEquivalent: 500, volumeML: 500, category: .volume, foodCategory: .beverages),
        ServingSize(name: "1 glass (200ml)", gramsEquivalent: 200, volumeML: 200, category: .volume, foodCategory: .beverages),
        
        // Snack/dessert servings
        ServingSize(name: "1 piece", gramsEquivalent: 15, category: .piece, foodCategory: .snacks),
        ServingSize(name: "1 small portion", gramsEquivalent: 30, category: .piece, foodCategory: .snacks),
        ServingSize(name: "1 serving", gramsEquivalent: 40, category: .piece, foodCategory: .snacks),
        ServingSize(name: "1 scoop (65ml)", gramsEquivalent: 60, volumeML: 65, category: .volume, foodCategory: .desserts),
        ServingSize(name: "1/2 cup (100ml)", gramsEquivalent: 92, volumeML: 100, category: .volume, foodCategory: .desserts),
    ]
    
    // Get suggested serving sizes for a specific food category
    static func suggestedServings(for foodCategory: FoodCategory?) -> [ServingSize] {
        let universalServings = standardServingSizes.filter { $0.isStandard }
        let categorySpecific = standardServingSizes.filter { $0.foodCategory == foodCategory }
        
        // Return category-specific servings first, then universal ones
        return categorySpecific + universalServings
    }
    
    // Get the most appropriate serving size for a food based on its name and category
    static func suggestedDefaultServing(for foodName: String, foodCategory: FoodCategory?) -> ServingSize {
        let foodNameLower = foodName.lowercased()
        
        // Smart suggestions based on food name patterns
        if foodNameLower.contains("banana") {
            return ServingSize(name: "1 medium", gramsEquivalent: 120, category: .piece, foodCategory: .fruits)
        } else if foodNameLower.contains("apple") {
            return ServingSize(name: "1 medium", gramsEquivalent: 180, category: .piece, foodCategory: .fruits)
        } else if foodNameLower.contains("milk") || foodNameLower.contains("juice") {
            return ServingSize(name: "1 cup (240ml)", gramsEquivalent: 240, volumeML: 240, category: .volume, foodCategory: .beverages)
        } else if foodNameLower.contains("ice cream") || foodNameLower.contains("yogurt") {
            return ServingSize(name: "1/2 cup (100ml)", gramsEquivalent: 92, volumeML: 100, category: .volume, foodCategory: .dairy)
        } else if foodNameLower.contains("bread") {
            return ServingSize(name: "1 slice", gramsEquivalent: 25, category: .piece, foodCategory: .grains)
        } else if foodNameLower.contains("chicken") || foodNameLower.contains("beef") || foodNameLower.contains("fish") {
            return ServingSize(name: "1 serving (150g)", gramsEquivalent: 150, category: .piece, foodCategory: .protein)
        }
        
        // Default to 100g for most foods
        return ServingSize(name: "100g", gramsEquivalent: 100, category: .weight, isStandard: true)
    }
}

// MARK: - ServingSize Manager

class ServingSizeManager: ObservableObject {
    @Published var customServingSizes: [ServingSize] = []
    
    private let userDefaults = UserDefaults.standard
    private let customServingsKey = "customServingSizes"
    
    init() {
        loadCustomServingSizes()
    }
    
    func getAllServingSizes(for foodCategory: FoodCategory? = nil) -> [ServingSize] {
        let standard = ServingSize.suggestedServings(for: foodCategory)
        let custom = customServingSizes.filter { size in
            foodCategory == nil || size.foodCategory == nil || size.foodCategory == foodCategory
        }
        
        return standard + custom
    }
    
    func addCustomServingSize(_ servingSize: ServingSize) {
        customServingSizes.append(servingSize)
        saveCustomServingSizes()
    }
    
    func removeCustomServingSize(_ servingSize: ServingSize) {
        customServingSizes.removeAll { $0.id == servingSize.id }
        saveCustomServingSizes()
    }
    
    private func saveCustomServingSizes() {
        if let encoded = try? JSONEncoder().encode(customServingSizes) {
            userDefaults.set(encoded, forKey: customServingsKey)
        }
    }
    
    private func loadCustomServingSizes() {
        if let data = userDefaults.data(forKey: customServingsKey),
           let servings = try? JSONDecoder().decode([ServingSize].self, from: data) {
            customServingSizes = servings
        }
    }
}

// MARK: - Helper Extensions

extension ServingSize {
    var displayText: String {
        switch category {
        case .volume:
            if let volumeML = volumeML {
                return "\(name) (\(Int(volumeML))ml)"
            }
            return name
        case .weight:
            return "\(name) (\(Int(gramsEquivalent))g)"
        case .piece, .custom:
            return name
        }
    }
    
    var shortDisplayText: String {
        return name
    }
}