import Foundation

// MARK: - Master Serving Size Enum (Single Source of Truth)

enum MasterServingSize: String, CaseIterable, Codable {
    
    // MARK: - Contextual Food-Specific Servings (Claude's preferred picks)
    case handful = "handful"
    case slice = "slice"
    case bowl = "bowl"
    case cup = "cup"
    case glass = "glass"
    case pint = "pint"
    case bottle = "bottle"
    case can = "can"
    case piece = "piece"
    case portion = "portion"
    case scoop = "scoop"
    case tablespoon = "tablespoon"
    case teaspoon = "teaspoon"
    case small = "small"
    case medium = "medium"
    case large = "large"
    case serving = "serving"
    case packet = "packet"
    case bag = "bag"
    case container = "container"
    case bar = "bar"
    case stick = "stick"
    case wedge = "wedge"
    
    // MARK: - Metric Weight Options
    case grams10 = "10g"
    case grams15 = "15g"
    case grams20 = "20g"
    case grams25 = "25g"
    case grams30 = "30g"
    case grams40 = "40g"
    case grams50 = "50g"
    case grams75 = "75g"
    case grams100 = "100g"
    case grams125 = "125g"
    case grams150 = "150g"
    case grams200 = "200g"
    case grams250 = "250g"
    case grams300 = "300g"
    
    // MARK: - Imperial Weight Options
    case oz0_5 = "0.5oz"
    case oz1 = "1oz"
    case oz1_5 = "1.5oz"
    case oz2 = "2oz"
    case oz3 = "3oz"
    case oz4 = "4oz"
    case oz5 = "5oz"
    case oz6 = "6oz"
    case oz8 = "8oz"
    case oz10 = "10oz"
    
    // MARK: - Metric Volume Options  
    case ml50 = "50ml"
    case ml100 = "100ml"
    case ml150 = "150ml"
    case ml200 = "200ml"
    case ml250 = "250ml"
    case ml300 = "300ml"
    case ml400 = "400ml"
    case ml500 = "500ml"
    case ml750 = "750ml"
    case ml1000 = "1000ml"
    
    // MARK: - Imperial Volume Options
    case flOz2 = "2 fl oz"
    case flOz4 = "4 fl oz"
    case flOz6 = "6 fl oz"
    case flOz8 = "8 fl oz"
    case flOz10 = "10 fl oz"
    case flOz12 = "12 fl oz"
    case flOz16 = "16 fl oz"
    case flOz20 = "20 fl oz"
    
    // MARK: - Properties
    
    /// Convert serving size to grams equivalent for nutrition calculation
    var gramsEquivalent: Double {
        switch self {
        // Contextual servings (estimated averages)
        case .handful: return 30.0
        case .slice: return 25.0
        case .bowl: return 150.0
        case .cup: return 240.0  // Standard cup for liquids
        case .glass: return 200.0
        case .pint: return 473.0  // US pint
        case .bottle: return 350.0  // Standard bottle
        case .can: return 330.0   // Standard can
        case .piece: return 50.0
        case .portion: return 100.0
        case .scoop: return 60.0
        case .tablespoon: return 15.0
        case .teaspoon: return 5.0
        case .small: return 80.0
        case .medium: return 120.0
        case .large: return 180.0
        case .serving: return 100.0
        case .packet: return 25.0
        case .bag: return 35.0
        case .container: return 150.0
        case .bar: return 40.0
        case .stick: return 15.0
        case .wedge: return 30.0
            
        // Metric weights (direct conversion)
        case .grams10: return 10.0
        case .grams15: return 15.0
        case .grams20: return 20.0
        case .grams25: return 25.0
        case .grams30: return 30.0
        case .grams40: return 40.0
        case .grams50: return 50.0
        case .grams75: return 75.0
        case .grams100: return 100.0
        case .grams125: return 125.0
        case .grams150: return 150.0
        case .grams200: return 200.0
        case .grams250: return 250.0
        case .grams300: return 300.0
            
        // Imperial weights (convert to grams: 1 oz = 28.3495g)
        case .oz0_5: return 14.17
        case .oz1: return 28.35
        case .oz1_5: return 42.52
        case .oz2: return 56.70
        case .oz3: return 85.05
        case .oz4: return 113.40
        case .oz5: return 141.75
        case .oz6: return 170.10
        case .oz8: return 226.80
        case .oz10: return 283.50
            
        // Metric volumes (1ml ≈ 1g for water-based liquids)
        case .ml50: return 50.0
        case .ml100: return 100.0
        case .ml150: return 150.0
        case .ml200: return 200.0
        case .ml250: return 250.0
        case .ml300: return 300.0
        case .ml400: return 400.0
        case .ml500: return 500.0
        case .ml750: return 750.0
        case .ml1000: return 1000.0
            
        // Imperial volumes (convert fl oz to grams: 1 fl oz = 29.5735ml ≈ 29.57g)
        case .flOz2: return 59.15
        case .flOz4: return 118.29
        case .flOz6: return 177.44
        case .flOz8: return 236.59
        case .flOz10: return 295.74
        case .flOz12: return 354.88
        case .flOz16: return 473.18
        case .flOz20: return 591.47
        }
    }
    
    /// True for contextual servings that depend on food type
    var isContextual: Bool {
        switch self {
        case .handful, .slice, .bowl, .cup, .glass, .pint, .bottle, .can, .piece, .portion, 
             .scoop, .tablespoon, .teaspoon, .small, .medium, .large, .serving, .packet, 
             .bag, .container, .bar, .stick, .wedge:
            return true
        default:
            return false
        }
    }
    
    /// True for metric units
    var isMetric: Bool {
        switch self {
        case .grams10, .grams15, .grams20, .grams25, .grams30, .grams40, .grams50, .grams75, 
             .grams100, .grams125, .grams150, .grams200, .grams250, .grams300,
             .ml50, .ml100, .ml150, .ml200, .ml250, .ml300, .ml400, .ml500, .ml750, .ml1000:
            return true
        default:
            return false
        }
    }
    
    /// True for imperial units
    var isImperial: Bool {
        switch self {
        case .oz0_5, .oz1, .oz1_5, .oz2, .oz3, .oz4, .oz5, .oz6, .oz8, .oz10,
             .flOz2, .flOz4, .flOz6, .flOz8, .flOz10, .flOz12, .flOz16, .flOz20:
            return true
        default:
            return false
        }
    }
    
    /// Display name for UI
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Serving Size Context Logic

extension MasterServingSize {
    
    /// Get contextually appropriate serving sizes for different food types
    static func contextualSuggestions(for foodType: FoodType, preferMetric: Bool = true) -> [MasterServingSize] {
        let contextual = contextualServingsFor(foodType: foodType)
        let fallbacks = preferMetric ? metricFallbacks(for: foodType) : imperialFallbacks(for: foodType)
        
        return contextual + fallbacks
    }
    
    private static func contextualServingsFor(foodType: FoodType) -> [MasterServingSize] {
        switch foodType {
        case .nuts, .seeds:
            return [.handful, .packet, .small, .portion]
        case .bread, .baked:
            return [.slice, .piece, .small, .medium]
        case .liquids, .beverages:
            return [.cup, .glass, .bottle, .can]
        case .cereal, .pasta, .rice:
            return [.bowl, .portion, .serving, .cup]
        case .fruits:
            return [.piece, .small, .medium, .large]
        case .vegetables:
            return [.portion, .cup, .piece, .serving]
        case .meat, .fish:
            return [.portion, .piece, .serving, .small]
        case .dairy:
            return [.serving, .portion, .cup, .container]
        case .snacks:
            return [.bag, .packet, .portion, .piece]
        case .desserts:
            return [.scoop, .piece, .slice, .portion]
        case .generic:
            return [.portion, .serving, .piece, .small]
        }
    }
    
    private static func metricFallbacks(for foodType: FoodType) -> [MasterServingSize] {
        switch foodType {
        case .nuts, .seeds, .snacks:
            return [.grams25, .grams50, .grams30]
        case .bread, .baked:
            return [.grams30, .grams50, .grams25]
        case .liquids, .beverages:
            return [.ml200, .ml250, .ml300, .ml500]
        case .cereal, .pasta, .rice:
            return [.grams75, .grams100, .grams150]
        case .fruits, .vegetables:
            return [.grams100, .grams150, .grams200]
        case .meat, .fish:
            return [.grams100, .grams150, .grams200]
        case .dairy:
            return [.grams100, .ml200, .grams150]
        case .desserts:
            return [.grams50, .grams75, .grams100]
        case .generic:
            return [.grams100, .grams50, .grams150]
        }
    }
    
    private static func imperialFallbacks(for foodType: FoodType) -> [MasterServingSize] {
        switch foodType {
        case .nuts, .seeds, .snacks:
            return [.oz1, .oz2, .oz1_5]
        case .bread, .baked:
            return [.oz1, .oz2, .oz1_5]
        case .liquids, .beverages:
            return [.flOz8, .flOz12, .flOz16]
        case .cereal, .pasta, .rice:
            return [.oz3, .oz4, .oz5]
        case .fruits, .vegetables:
            return [.oz4, .oz5, .oz6]
        case .meat, .fish:
            return [.oz4, .oz5, .oz6]
        case .dairy:
            return [.oz4, .flOz8, .oz5]
        case .desserts:
            return [.oz2, .oz3, .oz4]
        case .generic:
            return [.oz4, .oz2, .oz5]
        }
    }
}

// MARK: - Food Type Classification

enum FoodType: String, CaseIterable {
    case nuts = "nuts"
    case seeds = "seeds" 
    case bread = "bread"
    case baked = "baked"
    case liquids = "liquids"
    case beverages = "beverages"
    case cereal = "cereal"
    case pasta = "pasta"
    case rice = "rice"
    case fruits = "fruits"
    case vegetables = "vegetables"
    case meat = "meat"
    case fish = "fish"
    case dairy = "dairy"
    case snacks = "snacks"
    case desserts = "desserts"
    case generic = "generic"
    
    /// Classify food type from food name using simple keyword matching
    static func classify(foodName: String) -> FoodType {
        let name = foodName.lowercased()
        
        if name.contains("pistachio") || name.contains("almond") || name.contains("walnut") || 
           name.contains("peanut") || name.contains("cashew") || name.contains("pecan") {
            return .nuts
        }
        
        if name.contains("seed") || name.contains("sunflower") || name.contains("pumpkin") {
            return .seeds
        }
        
        if name.contains("bread") || name.contains("toast") || name.contains("bagel") || name.contains("roll") {
            return .bread
        }
        
        if name.contains("milk") || name.contains("juice") || name.contains("water") || name.contains("soda") || 
           name.contains("coffee") || name.contains("tea") || name.contains("beer") || name.contains("wine") {
            return .beverages
        }
        
        if name.contains("cereal") || name.contains("oats") || name.contains("granola") {
            return .cereal
        }
        
        if name.contains("pasta") || name.contains("spaghetti") || name.contains("macaroni") {
            return .pasta
        }
        
        if name.contains("rice") {
            return .rice
        }
        
        if name.contains("apple") || name.contains("banana") || name.contains("orange") || 
           name.contains("berry") || name.contains("grape") {
            return .fruits
        }
        
        if name.contains("chicken") || name.contains("beef") || name.contains("pork") || name.contains("turkey") {
            return .meat
        }
        
        if name.contains("fish") || name.contains("salmon") || name.contains("tuna") {
            return .fish
        }
        
        if name.contains("cheese") || name.contains("yogurt") || name.contains("cream") {
            return .dairy
        }
        
        if name.contains("chip") || name.contains("cracker") || name.contains("cookie") {
            return .snacks
        }
        
        if name.contains("cake") || name.contains("pie") || name.contains("ice cream") || name.contains("chocolate") {
            return .desserts
        }
        
        return .generic
    }
}

// MARK: - Legacy ServingSize Compatibility

struct ServingSize: Identifiable, Codable {
    let id: UUID
    let name: String
    let gramsEquivalent: Double
    let volumeML: Double?
    let category: ServingCategory
    let isStandard: Bool
    
    var shortDisplayText: String {
        return name
    }
    
    init(from masterSize: MasterServingSize) {
        self.id = UUID()
        self.name = masterSize.rawValue
        self.gramsEquivalent = masterSize.gramsEquivalent
        
        // Set volumeML for volume-based servings
        switch masterSize {
        case .ml50, .ml100, .ml150, .ml200, .ml250, .ml300, .ml400, .ml500, .ml750, .ml1000:
            self.volumeML = masterSize.gramsEquivalent // For liquids, 1ml ≈ 1g
        case .flOz2, .flOz4, .flOz6, .flOz8, .flOz10, .flOz12, .flOz16, .flOz20:
            self.volumeML = masterSize.gramsEquivalent // Already converted to ml equivalent
        case .cup:
            self.volumeML = 240.0
        case .glass:
            self.volumeML = 200.0
        case .pint:
            self.volumeML = 473.0
        case .tablespoon:
            self.volumeML = 15.0
        case .teaspoon:
            self.volumeML = 5.0
        default:
            self.volumeML = nil
        }
        
        self.category = masterSize.isContextual ? .custom : (masterSize.isMetric ? .weight : .piece)
        self.isStandard = !masterSize.isContextual
    }
    
    init(id: UUID = UUID(), name: String, gramsEquivalent: Double, volumeML: Double? = nil, category: ServingCategory, isStandard: Bool = false) {
        self.id = id
        self.name = name
        self.gramsEquivalent = gramsEquivalent
        self.volumeML = volumeML
        self.category = category
        self.isStandard = isStandard
    }
}

enum ServingCategory: String, CaseIterable, Codable {
    case weight = "weight"
    case volume = "volume" 
    case piece = "piece"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .weight: return "Weight"
        case .volume: return "Volume"
        case .piece: return "Piece/Unit"
        case .custom: return "Custom"
        }
    }
}

// MARK: - ServingSizeManager for Backward Compatibility

class ServingSizeManager: ObservableObject {
    @Published var customServingSizes: [ServingSize] = []
    
    func getAllServingSizes(for foodType: FoodType? = nil) -> [ServingSize] {
        // Return standard serving sizes converted from master list
        let contextualSuggestions = MasterServingSize.contextualSuggestions(for: foodType ?? .generic, preferMetric: true)
        return contextualSuggestions.map { ServingSize(from: $0) }
    }
}