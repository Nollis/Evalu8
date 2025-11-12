import Foundation

/// Service for interacting with OpenAI API to generate decision setups
class OpenAIService {
    static let shared = OpenAIService()
    
    private let apiKey: String?
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {
        // Get API key from environment variable or Info.plist
        // In production, you'd want to store this securely
        apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? 
                 Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String
    }
    
    var isAvailable: Bool {
        return apiKey != nil && !apiKey!.isEmpty
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
                    2. At least 2-5 relevant options to compare
                    3. 3-6 relevant criteria with appropriate weights (1-5 scale, where 5 is most important)
                    
                    Return ONLY valid JSON in this exact format:
                    {
                        "title": "Decision Title",
                        "description": "Brief description",
                        "options": ["Option 1", "Option 2", "Option 3"],
                        "criteria": [
                            {"name": "Criterion 1", "weight": 5},
                            {"name": "Criterion 2", "weight": 4}
                        ],
                        "scoringScale": 5
                    }
                    
                    Make criteria relevant to the decision type. For products, consider: Price, Quality, Features, Design, etc.
                    For relationships or abstract concepts, be thoughtful and appropriate.
                    """
                ],
                [
                    "role": "user",
                    "content": query
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 1000,
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
        
        guard let optionsArray = json["options"] as? [String],
              optionsArray.count >= 2 else {
            throw AIError.invalidResponseFormat
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
            return QuickDecisionSetup.CriterionSetup(
                name: name,
                weight: Int16(max(1, min(5, weight))) // Clamp between 1-5
            )
        }
        
        return QuickDecisionSetup(
            title: title,
            description: description,
            options: optionsArray,
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

