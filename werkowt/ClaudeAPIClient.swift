import Foundation

class ClaudeAPIClient {
    static let shared = ClaudeAPIClient()
    
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-5-sonnet-20240620"
    private let apiVersion = "2023-06-01"
    
    private init() {}
    
    @MainActor
    func generateMealPlan(
        userPreferences: String,
        numberOfDays: Int,
        startDate: Date,
        macroGoals: MacroGoals?
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
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let prompt = buildMealPlanPrompt(
            userPreferences: userPreferences,
            numberOfDays: numberOfDays,
            startDate: startDate,
            macroGoals: macroGoals
        )
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 4096
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw ClaudeAPIError.jsonParsingError
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try parseClaudeResponse(data)
        } catch {
            if error is ClaudeAPIError {
                throw error
            } else {
                throw ClaudeAPIError.networkError(error)
            }
        }
    }
    
    private func buildMealPlanPrompt(
        userPreferences: String,
        numberOfDays: Int,
        startDate: Date,
        macroGoals: MacroGoals?
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var prompt = """
        Create a detailed meal plan in JSON format with the following specifications:
        
        **User Requirements:**
        - Duration: \(numberOfDays) days starting from \(dateFormatter.string(from: startDate))
        - User preferences: \(userPreferences)
        """
        
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
            "shoppingList": ["item 1", "item 2"],
            "totalNutrition": {
                "totalCalories": 14000,
                "totalProtein": 1050,
                "totalCarbs": 1400,
                "totalFat": 560
            }
        }
        
        **Instructions:**
        1. Include breakfast, lunch, and dinner for each day
        2. Make recipes practical and achievable
        3. Provide realistic nutrition estimates
        4. Consider the user's preferences and any dietary restrictions mentioned
        5. Include prep times in minutes
        6. Create a comprehensive shopping list
        7. Ensure meals are varied and interesting
        8. Instructions should be clear and concise
        
        Return ONLY the JSON object, no additional text or formatting.
        """
        
        return prompt
    }
    
    private func parseClaudeResponse(_ data: Data) throws -> GeneratedMealPlan {
        guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResult["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw ClaudeAPIError.invalidResponse
        }
        
        // Extract JSON from Claude's response text
        guard let jsonData = extractJSON(from: text) else {
            throw ClaudeAPIError.invalidMealPlanFormat
        }
        
        do {
            let mealPlan = try JSONDecoder().decode(GeneratedMealPlan.self, from: jsonData)
            return mealPlan
        } catch {
            print("JSON parsing error: \(error)")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Raw JSON: \(jsonString)")
            }
            throw ClaudeAPIError.jsonParsingError
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