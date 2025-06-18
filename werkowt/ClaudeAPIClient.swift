import Foundation

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
        // Try to find JSON object markers
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Look for the start and end of JSON object
        guard let startIndex = trimmedText.firstIndex(of: "{"),
              let endIndex = trimmedText.lastIndex(of: "}") else {
            return nil
        }
        
        let jsonString = String(trimmedText[startIndex...endIndex])
        return jsonString.data(using: .utf8)
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
}
