import Foundation
import UIKit

class ClaudeAPIClient {
    static let shared = ClaudeAPIClient()
    
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"
    private let apiVersion = "2023-06-01"
    
    private init() {}
    
    @MainActor
    func generateMealPlan(
        numberOfDays: Int,
        startDate: Date,
        macroGoals: MacroGoals?,
        configuration: MealPlanningConfiguration,
        measurementUnit: MeasurementUnit = .metric,
        temperatureUnit: TemperatureUnit = .celsius
    ) async throws -> GeneratedMealPlan {
        
        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }
        
        let apiKey = Config.anthropicKey
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.noAPIKey
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120.0 // 2 minutes timeout for Claude API
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let prompt = buildMealPlanPrompt(
            numberOfDays: numberOfDays,
            startDate: startDate,
            macroGoals: macroGoals,
            configuration: configuration,
            measurementUnit: measurementUnit,
            temperatureUnit: temperatureUnit
        )
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 8096
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // Log request details for debugging
            print("🚀 Sending Claude API Request:")
            print("🚀 URL: \(url)")
            print("🚀 Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let bodyData = request.httpBody,
               let bodyString = String(data: bodyData, encoding: .utf8) {
                print("🚀 Request Body (first 1000 chars): \(String(bodyString.prefix(1000)))")
            }
        } catch {
            throw ClaudeAPIError.jsonParsingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Log the response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 Claude API Response Status: \(httpResponse.statusCode)")
                print("🌐 Response Headers: \(httpResponse.allHeaderFields)")
                
                // Handle non-success status codes
                if httpResponse.statusCode != 200 {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("❌ Claude API Error Response: \(responseString)")
                    
                    // Create specific error based on status code
                    switch httpResponse.statusCode {
                    case 401:
                        throw ClaudeAPIError.noAPIKey
                    case 400:
                        throw ClaudeAPIError.invalidResponse
                    case 429:
                        throw ClaudeAPIError.networkError(NSError(domain: "ClaudeAPI", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"]))
                    case 500...599:
                        throw ClaudeAPIError.networkError(NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"]))
                    default:
                        throw ClaudeAPIError.networkError(NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(responseString)"]))
                    }
                }
            }
            
            // Log successful response data for debugging
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("✅ Claude API Response Data (first 500 chars): \(String(responseString.prefix(500)))")
            
            return try parseClaudeResponse(data)
        } catch {
            print("🚨 Claude API Error: \(error)")
            if error is ClaudeAPIError {
                throw error
            } else {
                throw ClaudeAPIError.networkError(error)
            }
        }
    }
    
    private func buildMealPlanPrompt(
        numberOfDays: Int,
        startDate: Date,
        macroGoals: MacroGoals?,
        configuration: MealPlanningConfiguration,
        measurementUnit: MeasurementUnit,
        temperatureUnit: TemperatureUnit
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var prompt = """
        Create a detailed meal plan in JSON format with the following specifications:
        
        **User Requirements:**
        - Duration: \(numberOfDays) days starting from \(dateFormatter.string(from: startDate))
        - Meal types to generate: \(configuration.selectedMealTypes.map { $0.displayName }.sorted().joined(separator: ", "))
        - Household size: \(configuration.householdSize) people
        - Maximum prep time per meal: \(configuration.maxPrepTime.rawValue) (\(configuration.maxPrepTime.minutes) minutes)
        - Diet type: \(configuration.dietType.rawValue)
        - Cooking skill level: \(configuration.skillLevel.rawValue)
        - Budget level: \(configuration.budgetLevel.rawValue)
        - Shopping preference: \(configuration.shopType.rawValue)
        - Allergens to avoid: \(configuration.selectedAllergens.isEmpty ? "None" : Array(configuration.selectedAllergens).joined(separator: ", "))
        """
        
        if !configuration.additionalNotes.isEmpty {
            prompt += """
            - Additional preferences: \(configuration.additionalNotes)
            """
        }
        
        if let goals = macroGoals {
            prompt += """
            
            **Daily Macro Targets:**
            - Calories: \(Int(goals.calories))
            - Protein: \(Int(goals.protein))g
            - Carbs: \(Int(goals.carbs))g
            - Fat: \(Int(goals.fat))g
            """
        }
        
        prompt += """
        
        **Required JSON Structure:**
        {
            "title": "Brief descriptive title for the meal plan",
            "description": "2-3 sentence overview of the meal plan approach",
            "totalDays": \(numberOfDays),
            "dailyMeals": [
                {
                    "day": 1,
                    "date": "June 16, 2025",
                    "meals": [
                        {
                            "type": "breakfast",
                            "name": "Meal name",
                            "description": "Brief description",
                            "ingredients": ["ingredient 1", "ingredient 2"],
                            "instructions": ["step 1", "step 2"],
                            "prepTime": 15,
                            "nutrition": {
                                "calories": 400,
                                "protein": 25,
                                "carbs": 45,
                                "fat": 12,
                                "fiber": 8,
                                "sugar": 5
                            }
                        }
                    ],
                    "dailyNutrition": {
                        "totalCalories": 2000,
                        "totalProtein": 150,
                        "totalCarbs": 200,
                        "totalFat": 80
                    }
                }
            ],
            "shoppingList": [
                {"name": "chicken breast", "amount": "500g", "category": "Meat & Fish"},
                {"name": "bell peppers", "amount": "3 large", "category": "Fruit & Veg"},
                {"name": "cheddar cheese", "amount": "200g", "category": "Dairy"}
            ],
            "totalNutrition": {
                "totalCalories": 14000,
                "totalProtein": 1050,
                "totalCarbs": 1400,
                "totalFat": 560
            }
        }
        
        **Instructions:**
        
        **MEASUREMENT UNITS**: \(measurementUnit == .metric ? "Use ONLY metric measurements throughout (grams, milliliters, liters, kilograms). Never use imperial units like ounces, cups, pounds, or tablespoons." : "Use ONLY imperial measurements throughout (ounces, cups, pounds, tablespoons, teaspoons). Never use metric units like grams, milliliters, or kilograms.")
        **TEMPERATURE UNITS**: \(temperatureUnit == .celsius ? "Use ONLY Celsius (°C) for all cooking temperatures. Never use Fahrenheit." : "Use ONLY Fahrenheit (°F) for all cooking temperatures. Never use Celsius.")
        
        1. Include only these meal types each day: \(configuration.selectedMealTypes.map { $0.displayName }.sorted().joined(separator: ", "))
        2. All meals must be suitable for \(configuration.dietType.rawValue) diet
        3. **PRIORITIZE LEFTOVERS**: When both lunch and dinner are selected, design dinners that intentionally create leftovers perfect for the next day's lunch. Make this a key strategy for meal efficiency and variety.
        4. Respect the \(configuration.skillLevel.rawValue) cooking skill level in recipe complexity
        5. Keep all prep times at or under \(configuration.maxPrepTime.minutes) minutes
        6. Account for \(configuration.budgetLevel.rawValue) budget level in ingredient selection
        7. Strictly avoid all listed allergens: \(configuration.selectedAllergens.isEmpty ? "None" : Array(configuration.selectedAllergens).joined(separator: ", "))
        8. Scale recipes appropriately for \(configuration.householdSize) people
        9. Provide realistic nutrition estimates
        10. Create a comprehensive shopping list tailored for \(configuration.shopType.rawValue) shopping - use \(measurementUnit.rawValue.lowercased()) units only
        11. Choose ingredients that are typically available at \(configuration.shopType.rawValue.lowercased()) locations
        12. Ensure meals are varied and interesting
        13. Instructions should be clear and appropriate for the skill level, using \(temperatureUnit.symbol) for temperatures
        14. **LEFTOVER OPTIMIZATION**: For lunches that use dinner leftovers, provide simple transformation tips (add fresh herbs, different sauce, serve over greens, etc.) to make them feel like new meals
        15. **MINIMIZE INGREDIENT WASTE**: Design meals that strategically reuse ingredients across multiple recipes to minimize waste and the length of the shopping list. Prefer recipes that share common ingredients and use full quantities purchased.
        16. **SHOPPING LIST FORMAT**: The shoppingList must be an array of objects with exactly these keys:
            - "name": specific item name (e.g., "chicken breast", "bell peppers", "whole milk")
            - "amount": quantity with units (e.g., "500g", "3 large", "1 liter", "2 cups")
            - "category": MUST be one of these exact values: "Dairy", "Meat & Fish", "Fruit & Veg", "Store Cupboard", "Frozen", "Breads & Grains", "Other"
        17. **CATEGORIZATION GUIDELINES**:
            - Dairy: milk, cheese, yogurt, butter, cream, eggs
            - Meat & Fish: all meats, poultry, fish, seafood
            - Fruit & Veg: fresh fruits, vegetables, herbs, salads
            - Store Cupboard: spices, oils, vinegars, canned goods, pasta, rice, flour, sugar
            - Frozen: frozen vegetables, frozen fruits, ice cream, frozen meals
            - Breads & Grains: bread, cereals, oats, quinoa, fresh grains
            - Other: cleaning supplies, non-food items, unusual ingredients
        
        Return ONLY the JSON object, no additional text or formatting.
        """
        
        return prompt
    }
    
    private func getCookingFrequencyInstructions(_ frequency: CookingFrequency) -> String {
        switch frequency {
        case .daily:
            return "design meals that can be prepared fresh each day with minimal prep work and simple cooking methods."
        case .everyOtherDay:
            return "create recipes that can be made in larger batches to cover 2 days, with proper storage and reheating instructions. Include both fresh meals and leftover-friendly dishes."
        case .twicePerWeek:
            return "focus on batch cooking and meal prep. Design 2-3 base recipes that can be prepared in large quantities and transformed into different meals throughout the week. Include detailed storage, reheating, and meal variation instructions."
        case .oncePerWeek:
            return "create a comprehensive meal prep plan where most cooking is done in one session. Focus on recipes that freeze well, can be portioned easily, and maintain quality throughout the week. Include detailed prep timeline and storage instructions."
        }
    }
    
    private func parseClaudeResponse(_ data: Data) throws -> GeneratedMealPlan {
        print("🔍 Parsing Claude Response...")
        
        do {
            guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Failed to parse response as JSON object")
                let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                print("❌ Raw response: \(responseString)")
                throw ClaudeAPIError.invalidResponse
            }
            
            print("✅ Successfully parsed outer JSON")
            print("🔍 JSON keys: \(jsonResult.keys)")
            
            guard let content = jsonResult["content"] as? [[String: Any]] else {
                print("❌ No 'content' array found in response")
                print("❌ Full response: \(jsonResult)")
                throw ClaudeAPIError.invalidResponse
            }
            
            guard let firstContent = content.first else {
                print("❌ Content array is empty")
                throw ClaudeAPIError.invalidResponse
            }
            
            guard let text = firstContent["text"] as? String else {
                print("❌ No 'text' field in first content item")
                print("❌ First content: \(firstContent)")
                throw ClaudeAPIError.invalidResponse
            }
            
            print("✅ Extracted text from Claude response")
            print("🔍 Text preview (first 200 chars): \(String(text.prefix(200)))")
            
            // Extract JSON from Claude's response text
            guard let jsonData = extractJSON(from: text) else {
                print("❌ Failed to extract JSON from Claude's text response")
                print("❌ Full text: \(text)")
                throw ClaudeAPIError.invalidMealPlanFormat
            }
            
            print("✅ Successfully extracted JSON from text")
            
            do {
                let mealPlan = try JSONDecoder().decode(GeneratedMealPlan.self, from: jsonData)
                print("✅ Successfully decoded GeneratedMealPlan")
                return mealPlan
            } catch {
                print("❌ JSON decoding error: \(error)")
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("❌ Failed JSON: \(jsonString)")
                }
                throw ClaudeAPIError.jsonParsingError
            }
        } catch {
            print("❌ JSON serialization error: \(error)")
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
            print("❌ Raw response data: \(responseString)")
            throw ClaudeAPIError.invalidResponse
        }
    }
    
    private func extractJSON(from text: String) -> Data? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First, try to extract JSON from markdown code blocks (```json ... ```)
        if let jsonFromCodeBlock = extractJSONFromCodeBlock(trimmedText) {
            return jsonFromCodeBlock
        }
        
        // Fallback: Look for raw JSON object markers
        guard let startIndex = trimmedText.firstIndex(of: "{"),
              let endIndex = trimmedText.lastIndex(of: "}") else {
            return nil
        }
        
        let jsonString = String(trimmedText[startIndex...endIndex])
        return jsonString.data(using: .utf8)
    }
    
    private func extractJSONFromCodeBlock(_ text: String) -> Data? {
        // Look for ```json ... ``` code blocks
        let patterns = [
            "```json\\s*\\n([\\s\\S]*?)\\n```",  // ```json\n{...}\n```
            "```json([\\s\\S]*?)```",           // ```json{...}```
            "`json([\\s\\S]*?)`"                // `json{...}`
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let jsonRange = Range(match.range(at: 1), in: text) {
                let jsonString = String(text[jsonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                return jsonString.data(using: .utf8)
            }
        }
        
        return nil
    }
}

// MARK: - Helper Extensions
extension ClaudeAPIClient {
    
    func generateQuickMealSuggestion(preferences: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }
        
        let apiKey = Config.anthropicKey
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.noAPIKey
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120.0 // 2 minutes timeout for Claude API
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let prompt = """
        Based on these preferences: "\(preferences)"
        
        Suggest 3 simple meal ideas with brief descriptions. Keep it concise and practical.
        Format as a simple text response, not JSON.
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 512
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResult["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw ClaudeAPIError.invalidResponse
        }
        
        return text
    }
    
    func estimateNutritionFromLabel(image: UIImage, foodName: String, brand: String? = nil) async throws -> NutritionInfo {
        let rawData = try await extractRawNutritionFromLabel(image: image, foodName: foodName, brand: brand)
        return rawData.nutrition
    }
    
    func extractRawNutritionFromLabel(image: UIImage, foodName: String, brand: String? = nil) async throws -> RawNutritionData {
        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }
        
        let apiKey = Config.anthropicKey
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.noAPIKey
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ClaudeAPIError.invalidResponse
        }
        
        let base64Image = imageData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120.0
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let brandText = brand.map { " (brand: \($0))" } ?? ""
        
        // Get the complete list of valid serving sizes
        let validServingSizes = MasterServingSize.allCases.map { $0.rawValue }.joined(separator: ", ")
        
        let prompt = """
        I need you to extract nutrition information AND suggest an appropriate serving size from this nutrition label photo for: \(foodName)\(brandText)
        
        Please analyze the nutrition facts panel, extract the nutrition data, convert to per-100g values, AND suggest a realistic serving size based on the food type and package context.
        
        IMPORTANT: Do NOT use web search tools. Only use information visible in the image.
        
        REQUIRED JSON FORMAT (always return this exact structure):
        {
            "nutrition": {
                "calories": 560.0,
                "protein": 20.9,
                "carbs": 28.0,
                "fat": 45.3,
                "fiber": 10.6,
                "sugar": 5.8,
                "sodium": 1.0
            },
            "originalUnit": "100g",
            "originalServingSize": null,
            "suggestedServingSize": "handful",
            "suggestedServingGrams": 30.0,
            "confidence": 0.95,
            "source": "Nutrition label from photo"
        }
        
        Field explanations:
        - "nutrition": All values must be normalized to per 100g (calculate if needed)
        - "originalUnit": What the label shows ("100g", "100ml", "per packet", "per serving")
        - "originalServingSize": If label shows serving size in grams (e.g., 30), put that number here
        - "suggestedServingSize": MUST be one of these exact values: \(validServingSizes)
        - "suggestedServingGrams": Realistic serving size in grams for typical consumption
        - "confidence": 0.9-0.95 for clear labels, 0.6-0.8 for partially visible
        - "source": Always "Nutrition label from photo"
        
        SERVING SIZE SELECTION RULES:
        1. ONLY use serving sizes from this exact list: \(validServingSizes)
        2. Choose the most contextually appropriate option for the food type
        3. Consider label units: metric labels → prefer contextual then metric options, imperial labels → prefer contextual then imperial options
        4. Food type guidelines:
           * Nuts/seeds: "handful" (preferred), then "1oz", "2oz" (imperial) or "25g", "30g" (metric)
           * Bread/baked goods: "slice" (preferred), then "1oz", "2oz" (imperial) or "25g", "50g" (metric)
           * Liquids/beverages: "cup", "glass", "bottle", then "8 fl oz", "12 fl oz" (imperial) or "200ml", "250ml" (metric)
           * Cereal/pasta/rice: "bowl", "portion", then "3oz", "4oz" (imperial) or "75g", "100g" (metric)
           * Fruits: "piece", "small", "medium", "large", then weight options
           * Meat/fish: "portion", "serving", then "4oz", "6oz" (imperial) or "100g", "150g" (metric)
           * Snacks: "bag", "packet", "portion", then "1oz", "2oz" (imperial) or "25g", "30g" (metric)
        5. Default fallback: "portion" for unknown foods
        
        Unit consistency examples:
        - Metric label ("per 100g"): pistachios → "handful" (best), "30g" (fallback)
        - Imperial context: pistachios → "handful" (best), "1oz" (fallback)
        - Liquid (any): milk → "cup" (best), "8 fl oz" or "250ml" (fallback based on region)
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user", 
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 2048
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("❌ Claude API Error Response: \(responseString)")
            throw ClaudeAPIError.networkError(NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString]))
        }
        
        guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResult["content"] as? [[String: Any]] else {
            throw ClaudeAPIError.invalidResponse
        }
        
        // Look for JSON in any content item
        var jsonData: Data?
        var allText = ""
        
        for contentItem in content {
            if let text = contentItem["text"] as? String, !text.isEmpty {
                allText += text + "\n"
                
                // Try to extract JSON from this content item
                if jsonData == nil {
                    jsonData = extractJSON(from: text)
                }
            }
        }
        
        // If no JSON found in individual items, try the combined text
        if jsonData == nil {
            jsonData = extractJSON(from: allText)
        }
        
        guard let extractedJsonData = jsonData else {
            print("❌ Failed to extract JSON from Claude nutrition label response. All text: \(allText)")
            print("🔄 Providing fallback nutrition estimate for: \(foodName)")
            
            // Fallback: return reasonable default estimates with lower confidence
            let fallbackNutrition = NutritionInfo(
                calories: 200,  // Higher default for processed foods
                protein: 8,
                carbs: 25,
                fat: 8,
                fiber: 3,
                sugar: 8,
                sodium: 200
            )
            return RawNutritionData(
                nutrition: fallbackNutrition,
                originalUnit: "100g",
                originalServingSize: nil,
                suggestedServingSize: nil,
                suggestedServingGrams: nil,
                confidence: 0.3,
                source: "Fallback estimate (label unreadable)"
            )
        }
        
        do {
            let nutritionDict = try JSONSerialization.jsonObject(with: extractedJsonData) as? [String: Any]
            guard let nutritionDict = nutritionDict else {
                print("❌ Failed to parse extracted JSON data from nutrition label")
                print("🔄 Providing fallback nutrition estimate for: \(foodName)")
                
                // Fallback: return reasonable default estimates
                let fallbackNutrition = NutritionInfo(
                    calories: 200,
                    protein: 8,
                    carbs: 25,
                    fat: 8,
                    fiber: 3,
                    sugar: 8,
                    sodium: 200
                )
                return RawNutritionData(
                    nutrition: fallbackNutrition,
                    originalUnit: "100g",
                    originalServingSize: nil,
                    suggestedServingSize: nil,
                    suggestedServingGrams: nil,
                    confidence: 0.3,
                    source: "Fallback estimate (parsing failed)"
                )
            }
            
            // Parse the nested nutrition data
            guard let nutritionData = nutritionDict["nutrition"] as? [String: Any] else {
                print("❌ Missing 'nutrition' field in response")
                let fallbackNutrition = NutritionInfo(calories: 200, protein: 8, carbs: 25, fat: 8, fiber: 3, sugar: 8, sodium: 200)
                return RawNutritionData(nutrition: fallbackNutrition, originalUnit: "100g", originalServingSize: nil, suggestedServingSize: nil, suggestedServingGrams: nil, confidence: 0.3, source: "Fallback estimate (malformed response)")
            }
            
            let nutrition = NutritionInfo(
                calories: (nutritionData["calories"] as? Double) ?? 200,
                protein: (nutritionData["protein"] as? Double) ?? 8,
                carbs: (nutritionData["carbs"] as? Double) ?? 25,
                fat: (nutritionData["fat"] as? Double) ?? 8,
                fiber: (nutritionData["fiber"] as? Double) ?? 3,
                sugar: (nutritionData["sugar"] as? Double) ?? 8,
                sodium: (nutritionData["sodium"] as? Double) ?? 200
            )
            
            return RawNutritionData(
                nutrition: nutrition,
                originalUnit: (nutritionDict["originalUnit"] as? String) ?? "100g",
                originalServingSize: nutritionDict["originalServingSize"] as? Double,
                suggestedServingSize: nutritionDict["suggestedServingSize"] as? String,
                suggestedServingGrams: nutritionDict["suggestedServingGrams"] as? Double,
                confidence: (nutritionDict["confidence"] as? Double) ?? 0.8,
                source: (nutritionDict["source"] as? String) ?? "Nutrition label from photo"
            )
        } catch {
            print("❌ JSON parsing error for nutrition label: \(error)")
            print("🔄 Providing fallback nutrition estimate for: \(foodName)")
            
            // Fallback: return reasonable default estimates
            let fallbackNutrition = NutritionInfo(
                calories: 200,
                protein: 8,
                carbs: 25,
                fat: 8,
                fiber: 3,
                sugar: 8,
                sodium: 200
            )
            return RawNutritionData(
                nutrition: fallbackNutrition,
                originalUnit: "100g",
                originalServingSize: nil,
                suggestedServingSize: nil,
                suggestedServingGrams: nil,
                confidence: 0.3,
                source: "Fallback estimate (JSON error)"
            )
        }
    }
    
    func estimateNutrition(foodName: String, brand: String? = nil, userFeedback: String? = nil) async throws -> NutritionInfo {
        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }
        
        let apiKey = Config.anthropicKey
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.noAPIKey
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120.0
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let brandText = brand.map { " (brand: \($0))" } ?? ""
        let feedbackText = userFeedback.map { "\n\nUser feedback for refinement: \($0)" } ?? ""
        
        let prompt = """
        I need nutrition information per 100g for: \(foodName)\(brandText)\(feedbackText)
        
        CRITICAL: You MUST return a JSON response in ALL cases, even if exact data is unavailable.
        
        Search strategy:®
        - Make ONE focused web search for nutrition data from sources like USDA FoodData Central, official brand websites, or verified nutrition databases
        - If exact match found: use that data (confidence: 0.8-0.95)
        - If no exact match: provide reasonable estimate based on similar foods (confidence: 0.3-0.7)
        
        \(userFeedback != nil ? "The user has provided feedback to help refine the estimate. Please use this to improve accuracy and increase confidence if the feedback helps." : "")
        
        The user will be able to correct estimates using our feedback system, so provide your best guess rather than no response.
        
        REQUIRED JSON FORMAT (no exceptions - always return this structure):
        {
            "calories": 165.0,
            "protein": 31.0,
            "carbs": 0.0,
            "fat": 3.6,
            "fiber": 0.0,
            "sugar": 0.0,
            "sodium": 74.0,
            "confidence": 0.75,
            "sources": "Web search result or estimation based on similar foods"
        }
        
        All nutrition values must be per 100 grams. Use decimal numbers only.
        Confidence score: 0.8-0.95 for exact matches, 0.3-0.7 for estimates.
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "tools": [
                [
                    "type": "web_search_20250305",
                    "name": "web_search",
                    "max_uses": 1
                ]
            ],
            "max_tokens": 2048
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("❌ Claude API Error Response: \(responseString)")
            throw ClaudeAPIError.networkError(NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString]))
        }
        
        guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResult["content"] as? [[String: Any]] else {
            throw ClaudeAPIError.invalidResponse
        }
        
        // Look for JSON in any content item (Claude returns multiple text blocks)
        var jsonData: Data?
        var allText = ""
        
        for contentItem in content {
            if let text = contentItem["text"] as? String, !text.isEmpty {
                allText += text + "\n"
                
                // Try to extract JSON from this content item
                if jsonData == nil {
                    jsonData = extractJSON(from: text)
                }
            }
        }
        
        // If no JSON found in individual items, try the combined text
        if jsonData == nil {
            jsonData = extractJSON(from: allText)
        }
        
        guard let extractedJsonData = jsonData else {
            print("❌ Failed to extract JSON from Claude response. All text: \(allText)")
            print("🔄 Providing fallback nutrition estimate for: \(foodName)")
            
            // Fallback: return reasonable default estimates
            return NutritionInfo(
                calories: 150,  // Reasonable average for most foods
                protein: 10,
                carbs: 20,
                fat: 5,
                fiber: 2,
                sugar: 5,
                sodium: 100
            )
        }
        
        do {
            let nutritionDict = try JSONSerialization.jsonObject(with: extractedJsonData) as? [String: Any]
            guard let nutritionDict = nutritionDict else {
                print("❌ Failed to parse extracted JSON data")
                print("🔄 Providing fallback nutrition estimate for: \(foodName)")
                
                // Fallback: return reasonable default estimates
                return NutritionInfo(
                    calories: 150,
                    protein: 10,
                    carbs: 20,
                    fat: 5,
                    fiber: 2,
                    sugar: 5,
                    sodium: 100
                )
            }
            
            return NutritionInfo(
                calories: (nutritionDict["calories"] as? Double) ?? 150,
                protein: (nutritionDict["protein"] as? Double) ?? 10,
                carbs: (nutritionDict["carbs"] as? Double) ?? 20,
                fat: (nutritionDict["fat"] as? Double) ?? 5,
                fiber: (nutritionDict["fiber"] as? Double) ?? 2,
                sugar: (nutritionDict["sugar"] as? Double) ?? 5,
                sodium: (nutritionDict["sodium"] as? Double) ?? 100
            )
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("🔄 Providing fallback nutrition estimate for: \(foodName)")
            
            // Fallback: return reasonable default estimates
            return NutritionInfo(
                calories: 150,
                protein: 10,
                carbs: 20,
                fat: 5,
                fiber: 2,
                sugar: 5,
                sodium: 100
            )
        }
    }
}

// MARK: - Food Analysis with Tool Use
extension ClaudeAPIClient {
    
    struct ClaudeToolDefinition {
        let name: String
        let description: String
        let inputSchema: [String: Any]
    }
    
    enum FoodInputType: String {
        case text = "text"
        case voice = "voice"
        case camera = "camera"
    }
    
    struct FoodAnalysisResult {
        let identifiedFoods: [AnalyzedFood]
        let estimatedAmounts: [String: Double]
        let confidence: Double
        let needsVerification: [AnalyzedFood]
    }
    
    struct AnalyzedFood {
        let name: String
        let brand: String?
        let nutrition: NutritionPer100g
        let confidence: Double
        let existsInDatabase: Bool
        let databaseId: UUID?
    }
    
    struct NutritionPer100g {
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let fiber: Double?
        let sugar: Double?
        let sodium: Double?
    }
    
    struct ServingSuggestion: Codable {
        let serving_name: String
        let grams_equivalent: Double
        let category: String
        let confidence: Double
        
        var servingCategory: ServingCategory {
            switch category.lowercased() {
            case "piece":
                return .piece
            case "volume":
                return .volume
            case "weight":
                return .weight
            default:
                return .piece
            }
        }
    }
    
    private var foodAnalysisTools: [ClaudeToolDefinition] {
        [
            ClaudeToolDefinition(
                name: "search_food_database",
                description: "Search the app's Supabase food database for existing food items by name or brand",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "query": [
                            "type": "string",
                            "description": "Food name or brand to search for"
                        ],
                        "limit": [
                            "type": "integer", 
                            "description": "Maximum number of results to return",
                            "default": 10
                        ]
                    ],
                    "required": ["query"]
                ]
            ),
            ClaudeToolDefinition(
                name: "web_search_nutrition",
                description: "Search the web for accurate nutrition information about food items from trusted sources like USDA",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "food_name": [
                            "type": "string",
                            "description": "The specific food item to search nutrition for"
                        ],
                        "brand": [
                            "type": "string",
                            "description": "Optional brand name for more specific results"
                        ]
                    ],
                    "required": ["food_name"]
                ]
            ),
            ClaudeToolDefinition(
                name: "verify_nutrition_data",
                description: "Cross-reference and verify nutrition data from multiple sources",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "food_name": ["type": "string"],
                        "nutrition_data": [
                            "type": "object",
                            "properties": [
                                "calories_per_100g": ["type": "number"],
                                "protein_per_100g": ["type": "number"],
                                "carbs_per_100g": ["type": "number"],
                                "fat_per_100g": ["type": "number"]
                            ]
                        ]
                    ],
                    "required": ["food_name", "nutrition_data"]
                ]
            )
        ]
    }
    
    @MainActor
    func analyzeFoodPhoto(
        image: UIImage,
        hasNutritionInfo: Bool
    ) async throws -> FoodAnalysisResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ClaudeAPIError.invalidResponse
        }
        
        let instruction = hasNutritionInfo ? 
            "Extract nutrition information from the food photo. Use only the nutrition facts visible in the image." :
            "Identify the food in the photo and estimate nutrition values. Use web search if needed to find accurate nutrition data."
        
        return try await analyzeFoodWithTools(
            input: instruction,
            inputType: .camera,
            imageData: imageData
        )
    }
    
    func analyzeFoodWithTools(
        input: String,
        inputType: FoodInputType,
        imageData: Data? = nil
    ) async throws -> FoodAnalysisResult {
        
        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }
        
        let apiKey = Config.anthropicKey
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.noAPIKey
        }
        
        let prompt = buildFoodAnalysisPrompt(input: input, inputType: inputType)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120.0
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "tools": foodAnalysisTools.map { tool in
                [
                    "name": tool.name,
                    "description": tool.description,
                    "input_schema": tool.inputSchema
                ]
            },
            "max_tokens": 4096
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("❌ Claude API Error Response: \(responseString)")
            throw ClaudeAPIError.networkError(NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString]))
        }
        
        return try await processToolUseResponse(data)
    }
    
    @MainActor
    private func processToolUseResponse(_ data: Data) async throws -> FoodAnalysisResult {
        guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResult["content"] as? [[String: Any]] else {
            throw ClaudeAPIError.invalidResponse
        }
        
        var messages: [[String: Any]] = [
            ["role": "user", "content": "Please analyze the food input and use the available tools to gather information."]
        ]
        
        // Check if Claude wants to use tools
        var hasToolUse = false
        var toolResults: [[String: Any]] = []
        
        for contentItem in content {
            if let toolUse = contentItem["tool_use"] as? [String: Any],
               let toolName = toolUse["name"] as? String,
               let toolInput = toolUse["input"] as? [String: Any],
               let toolId = toolUse["id"] as? String {
                
                hasToolUse = true
                
                // Execute the tool
                let result = try await executeToolCall(name: toolName, input: toolInput)
                
                toolResults.append([
                    "type": "tool_result",
                    "tool_use_id": toolId,
                    "content": result
                ])
            }
        }
        
        if hasToolUse {
            // Add assistant message with tool use
            messages.append(["role": "assistant", "content": content])
            
            // Add tool results
            messages.append(["role": "user", "content": toolResults])
            
            // Get final response from Claude
            let finalBody: [String: Any] = [
                "model": model,
                "messages": messages,
                "max_tokens": 4096
            ]
            
            var request = URLRequest(url: URL(string: baseURL)!)
            request.httpMethod = "POST"
            request.timeoutInterval = 120.0
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.anthropicKey, forHTTPHeaderField: "x-api-key")
            request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
            request.httpBody = try JSONSerialization.data(withJSONObject: finalBody)
            
            let (finalData, _) = try await URLSession.shared.data(for: request)
            return try parseFoodAnalysisResult(finalData, toolResults: toolResults)
        } else {
            // No tools used, parse direct response
            return try parseFoodAnalysisResult(data, toolResults: [])
        }
    }
    
    @MainActor
    private func executeToolCall(name: String, input: [String: Any]) async throws -> [String: Any] {
        switch name {
        case "search_food_database":
            return try await searchFoodDatabase(input: input)
        case "web_search_nutrition":
            return try await webSearchNutrition(input: input)
        case "verify_nutrition_data":
            return try await verifyNutritionData(input: input)
        default:
            throw ClaudeAPIError.invalidResponse
        }
    }
    
    @MainActor
    private func searchFoodDatabase(input: [String: Any]) async throws -> [String: Any] {
        guard let query = input["query"] as? String else {
            return ["error": "Missing query parameter"]
        }
        
        let limit = input["limit"] as? Int ?? 10
        
        do {
            let foods = try await SupabaseService.shared.searchFoodDatabaseForClaude(
                query: query,
                limit: limit
            )
            
            return [
                "success": true,
                "foods": foods
            ]
        } catch {
            return [
                "error": "Failed to search database: \(error.localizedDescription)",
                "success": false
            ]
        }
    }
    
    func suggestServingSize(foodName: String, brand: String? = nil) async throws -> ServingSuggestion {
        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }
        
        let apiKey = Config.anthropicKey
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.noAPIKey
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let brandText = brand.map { " (brand: \($0))" } ?? ""
        
        let prompt = """
        I need to suggest the most natural serving size for: \(foodName)\(brandText)
        
        Consider what serving size people would most naturally use when eating this food.
        
        Examples:
        - Banana → "1 medium" (120g)
        - Apple → "1 medium" (180g)
        - Bread → "1 slice" (25g)
        - Milk → "1 cup" (240ml)
        - Chicken breast → "1 piece" (150g)
        - Cookie → "1 piece" (15g)
        - Pizza → "1 slice" (100g)
        - Rice → "1 cup cooked" (175g)
        
        Return ONLY a JSON object with this exact structure:
        {
            "serving_name": "1 medium",
            "grams_equivalent": 120,
            "category": "piece",
            "confidence": 0.9
        }
        
        Categories: "piece", "volume", "weight"
        Confidence: 0.1-1.0 (1.0 = very confident this is natural)
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 200,
            "temperature": 0.3,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("❌ Claude API Error Response: \(responseString)")
            throw ClaudeAPIError.networkError(NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString]))
        }
        
        guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResult["content"] as? [[String: Any]] else {
            throw ClaudeAPIError.invalidResponse
        }
        
        var allText = ""
        for item in content {
            if let text = item["text"] as? String {
                allText += text + "\n"
            }
        }
        
        // Extract JSON from Claude's response
        guard let jsonData = extractJSON(from: allText) else {
            print("❌ Failed to extract JSON from Claude's serving size response")
            print("❌ Full text: \(allText)")
            throw ClaudeAPIError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ServingSuggestion.self, from: jsonData)
        } catch {
            print("❌ JSON decoding error for serving size: \(error)")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("❌ Failed JSON: \(jsonString)")
            }
            throw ClaudeAPIError.jsonParsingError
        }
    }
    
    private func webSearchNutrition(input: [String: Any]) async throws -> [String: Any] {
        guard let foodName = input["food_name"] as? String else {
            return ["error": "Missing food_name parameter"]
        }
        
        let brand = input["brand"] as? String
        
        // Mock nutrition data - in real implementation, this would search web
        print("Web searching nutrition for: \(foodName)" + (brand != nil ? " (brand: \(brand!))" : ""))
        
        return [
            "success": true,
            "nutrition_data": [
                "name": foodName,
                "brand": brand ?? "",
                "calories_per_100g": 150,
                "protein_per_100g": 20,
                "carbs_per_100g": 10,
                "fat_per_100g": 5,
                "fiber_per_100g": 2,
                "sugar_per_100g": 3,
                "sodium_per_100g": 300
            ],
            "source": "web_search",
            "confidence": 0.8
        ]
    }
    
    private func verifyNutritionData(input: [String: Any]) async throws -> [String: Any] {
        // Mock verification - in real implementation, cross-reference multiple sources
        return [
            "verified": true,
            "confidence_score": 0.95,
            "corrections": [:],
            "sources": ["USDA", "FoodData Central"]
        ]
    }
    
    private func buildFoodAnalysisPrompt(input: String, inputType: FoodInputType) -> String {
        return """
        I need you to analyze food input and help me track nutrition. Here's what the user provided:

        **Input Type**: \(inputType.rawValue)
        **User Input**: "\(input)"

        Please help me:
        1. Identify all food items mentioned
        2. Estimate the quantities of each food
        3. Use the available tools to:
           - Search the existing food database first
           - Look up nutrition information for any foods not in the database
           - Verify nutrition data accuracy

        For each food item, I need:
        - Name and brand (if applicable)
        - Estimated quantity in grams
        - Nutrition information per 100g (calories, protein, carbs, fat, fiber, sugar, sodium)
        - Confidence level of the identification

        Please use the tools available to gather accurate information, then provide a structured response that I can parse into the app.
        """
    }
    
    private func parseFoodAnalysisResult(_ data: Data, toolResults: [[String: Any]]) throws -> FoodAnalysisResult {
        // Mock implementation - in real app, this would parse Claude's structured response
        let mockFood = AnalyzedFood(
            name: "Banana",
            brand: nil,
            nutrition: NutritionPer100g(
                calories: 89,
                protein: 1.1,
                carbs: 22.8,
                fat: 0.3,
                fiber: 2.6,
                sugar: 12.2,
                sodium: 1
            ),
            confidence: 0.9,
            existsInDatabase: true,
            databaseId: UUID()
        )
        
        return FoodAnalysisResult(
            identifiedFoods: [mockFood],
            estimatedAmounts: ["Banana": 120], // 120g = 1 medium banana
            confidence: 0.9,
            needsVerification: []
        )
    }
}
