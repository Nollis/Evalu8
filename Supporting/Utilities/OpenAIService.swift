import Foundation

/// Service for interacting with OpenAI API to generate decision setups
class OpenAIService {
    static let shared = OpenAIService()
    
    private let apiKey: String?
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {
        // Get API key from environment variable or Info.plist
        // In production, you'd want to store this securely
        
        // Try environment variable first
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            // Validate API key format (OpenAI keys start with "sk-")
            if !envKey.hasPrefix("sk-") && !envKey.hasPrefix("sk-proj-") {
                Logger.shared.log("Warning: API key doesn't appear to be an OpenAI key (should start with 'sk-' or 'sk-proj-'). Current key starts with: \(String(envKey.prefix(4)))...", level: .warning)
            }
            self.apiKey = envKey
            Logger.shared.log("OpenAI API Key loaded from environment variable", level: .info)
            return
        }
        
        // Fallback to Info.plist
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String,
           !plistKey.isEmpty,
           plistKey != "YOUR_OPENAI_API_KEY_HERE" {
            // Validate API key format (OpenAI keys start with "sk-")
            if !plistKey.hasPrefix("sk-") && !plistKey.hasPrefix("sk-proj-") {
                Logger.shared.log("Warning: API key doesn't appear to be an OpenAI key (should start with 'sk-' or 'sk-proj-'). Current key starts with: \(String(plistKey.prefix(4)))...", level: .warning)
            }
            self.apiKey = plistKey
            Logger.shared.log("OpenAI API Key loaded from Info.plist", level: .info)
            return
        }
        
        self.apiKey = nil
        Logger.shared.log("OpenAI API Key not found or not configured", level: .warning)
    }
    
    var isAvailable: Bool {
        guard let key = apiKey, !key.isEmpty, key != "YOUR_OPENAI_API_KEY_HERE" else {
            return false
        }
        return true
    }
    
    /// Generates a decision setup using OpenAI API
    func generateQuickDecision(from query: String) async throws -> QuickDecisionSetup {
        guard let apiKey = apiKey else {
            throw AIError.apiKeyNotConfigured
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini", // Using mini for cost efficiency
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You are a helpful assistant that helps users make decisions by generating structured comparison data.
                    When given a query about comparing items, generate:
                    1. A clear title for the decision
                    2. At least 2-5 relevant options to compare, each with:
                       - A brief description (1-2 sentences)
                       - An image URL if applicable (use Unsplash API format: https://source.unsplash.com/400x300/?[keyword] or provide a relevant product image URL)
                       - An internet rating if available (0.0 to 5.0, based on common review sites or your knowledge)
                    3. 3-6 relevant criteria with appropriate weights (1-5 scale, where 5 is most important) and brief descriptions
                    
                    Return ONLY valid JSON in this exact format:
                    {
                        "title": "Decision Title",
                        "description": "Brief description of the decision",
                        "options": [
                            {
                                "name": "Option 1",
                                "description": "Brief description of this option",
                                "imageURL": "https://example.com/image.jpg",
                                "internetRating": 4.5
                            },
                            {
                                "name": "Option 2",
                                "description": "Brief description of this option",
                                "imageURL": null,
                                "internetRating": null
                            }
                        ],
                        "criteria": [
                            {
                                "name": "Criterion 1",
                                "description": "Brief explanation of what this criterion measures",
                                "weight": 5
                            },
                            {
                                "name": "Criterion 2",
                                "description": "Brief explanation of what this criterion measures",
                                "weight": 4
                            }
                        ],
                        "scoringScale": 5
                    }
                    
                    Important:
                    - For products: Include real product names, descriptions, and try to find actual ratings from review sites
                    - For images: Use Unsplash URLs (https://source.unsplash.com/400x300/?[keyword]) or product image URLs when available
                    - For ratings: Use actual ratings from Amazon, Google Reviews, or similar sources when possible. If unavailable, use null
                    - For criteria descriptions: Explain what each criterion measures (e.g., "Price" -> "The cost and value for money")
                    - Make criteria relevant to the decision type. For products, consider: Price, Quality, Features, Design, etc.
                    - For relationships or abstract concepts, be thoughtful and appropriate.
                    """
                ],
                [
                    "role": "user",
                    "content": query
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 2000,
            "response_format": ["type": "json_object"] as [String: Any]
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.shared.log("OpenAI API error: \(httpResponse.statusCode) - \(errorMessage)", level: .error)
            throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidResponseFormat
        }
        
        // Parse the JSON content from the message
        guard let contentData = content.data(using: .utf8),
              let decisionJSON = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            Logger.shared.log("Failed to parse OpenAI response content: \(content)", level: .error)
            throw AIError.invalidResponseFormat
        }
        
        return try parseDecisionJSON(decisionJSON)
    }
    
    private func parseDecisionJSON(_ json: [String: Any]) throws -> QuickDecisionSetup {
        guard let title = json["title"] as? String else {
            throw AIError.invalidResponseFormat
        }
        
        let description = json["description"] as? String
        let scoringScale = (json["scoringScale"] as? Int) ?? 5
        
        guard let optionsArray = json["options"] as? [[String: Any]],
              optionsArray.count >= 2 else {
            throw AIError.invalidResponseFormat
        }
        
        let options = try optionsArray.map { optionDict -> QuickDecisionSetup.OptionSetup in
            guard let name = optionDict["name"] as? String else {
                throw AIError.invalidResponseFormat
            }
            let description = optionDict["description"] as? String
            var imageURL = optionDict["imageURL"] as? String
            // Filter out null strings and empty strings
            if imageURL == "null" || imageURL?.isEmpty == true {
                imageURL = nil
            }
            let internetRating = optionDict["internetRating"] as? Double
            
            // Log image URL for debugging
            if let url = imageURL {
                Logger.shared.log("Option '\(name)' has image URL: \(url)", level: .info)
            } else {
                Logger.shared.log("Option '\(name)' has no image URL", level: .info)
            }
            
            // Validate rating is between 0.0 and 5.0
            let validatedRating: Double?
            if let rating = internetRating {
                validatedRating = max(0.0, min(5.0, rating))
            } else {
                validatedRating = nil
            }
            
            return QuickDecisionSetup.OptionSetup(
                name: name,
                description: description,
                imageURL: imageURL,
                internetRating: validatedRating
            )
        }
        
        guard let criteriaArray = json["criteria"] as? [[String: Any]],
              criteriaArray.count >= 2 else {
            throw AIError.invalidResponseFormat
        }
        
        let criteria = try criteriaArray.map { criterionDict -> QuickDecisionSetup.CriterionSetup in
            guard let name = criterionDict["name"] as? String,
                  let weight = criterionDict["weight"] as? Int else {
                throw AIError.invalidResponseFormat
            }
            let description = criterionDict["description"] as? String
            return QuickDecisionSetup.CriterionSetup(
                name: name,
                description: description,
                weight: Int16(max(1, min(5, weight))) // Clamp between 1-5
            )
        }
        
        return QuickDecisionSetup(
            title: title,
            description: description,
            options: options,
            criteria: criteria,
            scoringScale: Int16(scoringScale)
        )
    }
}

enum AIError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "OpenAI API key is not configured. Please add your API key to use AI features."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .invalidResponseFormat:
            return "AI service returned invalid format"
        case .apiError(let statusCode, let message):
            return "AI API error (\(statusCode)): \(message)"
        }
    }
}

