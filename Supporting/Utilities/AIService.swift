import Foundation

class AIService {
    static let shared = AIService()
    
    private let openAIService = OpenAIService.shared
    
    private init() {}
    
    /// Generates a complete decision setup from a natural language query
    /// Example: "I am planning on buying a putter. Can you give me some choices?"
    /// Uses OpenAI API if available, otherwise falls back to local pattern matching
    func generateQuickDecision(from query: String) async throws -> QuickDecisionSetup {
        // Try OpenAI first if available
        if openAIService.isAvailable {
            do {
                Logger.shared.log("Using OpenAI API for decision generation", level: .info)
                return try await openAIService.generateQuickDecision(from: query)
            } catch {
                Logger.shared.log("OpenAI API failed, falling back to local generation: \(error.localizedDescription)", level: .warning)
                // Fall through to local generation
            }
        } else {
            Logger.shared.log("OpenAI API not configured, using local generation", level: .info)
        }
        
        // Fallback to local pattern-based generation
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Parse the query to extract decision type and context
        let parsed = parseQuery(query)
        
        // Generate options based on the decision type
        let options = generateOptions(for: parsed.decisionType, context: parsed.context)
        
        // Generate criteria
        let criteria = generateCriteriaWithWeights(
            for: parsed.decisionType,
            description: parsed.context
        )
        
        return QuickDecisionSetup(
            title: parsed.title,
            description: parsed.context,
            options: options,
            criteria: criteria,
            scoringScale: 5
        )
    }
    
    func generateCriteria(for decisionName: String, description: String) async throws -> [String] {
        // In a real implementation, you would call an AI API like OpenAI here
        // For now, we'll use a simple implementation that generates criteria based on the decision
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Generate criteria based on decision name
        let criteria = generateCriteriaLocally(decisionName: decisionName, description: description)
        return criteria
    }
    
    // MARK: - Query Parsing
    
    private struct ParsedQuery {
        let decisionType: String
        let title: String
        let context: String
    }
    
    private func parseQuery(_ query: String) -> ParsedQuery {
        let lowercased = query.lowercased()
        var decisionType = ""
        var title = ""
        let context = query
        
        // Try to extract product/item name using regex
        let patterns = [
            "buying a (.+?)(\\.|\\?|$)",
            "purchasing a (.+?)(\\.|\\?|$)",
            "choosing (.+?)(\\.|\\?|$)",
            "deciding on (.+?)(\\.|\\?|$)",
            "looking for (.+?)(\\.|\\?|$)",
            "need (.+?)(\\.|\\?|$)",
            "want (.+?)(\\.|\\?|$)",
            "compare (.+?)(\\.|\\?|$)",
            "comparing (.+?)(\\.|\\?|$)",
            "to (.+?)(\\.|\\?|$)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: query, options: [], range: NSRange(query.startIndex..., in: query)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: query) {
                decisionType = String(query[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                // Remove common words
                decisionType = decisionType.replacingOccurrences(of: "some ", with: "")
                decisionType = decisionType.replacingOccurrences(of: "a ", with: "")
                decisionType = decisionType.replacingOccurrences(of: "an ", with: "")
                decisionType = decisionType.trimmingCharacters(in: .punctuationCharacters)
                
                if !decisionType.isEmpty {
                    title = "Best \(decisionType.capitalized)"
                    break
                }
            }
        }
        
        // Fallback: try to extract key words
        if decisionType.isEmpty {
            let productKeywords = [
                "putter", "golf putter", "putters",
                "car", "vehicle", "automobile",
                "house", "home", "apartment",
                "phone", "smartphone", "mobile",
                "laptop", "computer", "notebook",
                "job", "career", "position",
                "vacation", "trip", "holiday",
                "restaurant", "hotel", "camera",
                "headphones", "watch", "smartwatch"
            ]
            for keyword in productKeywords {
                if lowercased.contains(keyword) {
                    decisionType = keyword
                    // Create a better title
                    if keyword.contains("putter") {
                        title = "Golf Putter Comparison"
                    } else {
                        title = "Best \(keyword.capitalized)"
                    }
                    break
                }
            }
        }
        
        // If still empty, use a generic title
        if decisionType.isEmpty {
            decisionType = "item"
            title = "Decision"
        }
        
        return ParsedQuery(decisionType: decisionType, title: title, context: context)
    }
    
    // MARK: - Option Generation
    
    private func generateOptions(for decisionType: String, context: String) -> [String] {
        let type = decisionType.lowercased()
        let ctx = context.lowercased()
        
        // Product-specific options
        if type.contains("putter") || ctx.contains("putter") || ctx.contains("golf putter") {
            return [
                "Ping",
                "TaylorMade",
                "Cleveland",
                "Odyssey",
                "Scotty Cameron"
            ]
        } else if type.contains("car") || type.contains("vehicle") {
            return [
                "Toyota Camry",
                "Honda Accord",
                "Tesla Model 3",
                "BMW 3 Series",
                "Mercedes-Benz C-Class"
            ]
        } else if type.contains("phone") || type.contains("smartphone") {
            return [
                "iPhone 15 Pro",
                "Samsung Galaxy S24",
                "Google Pixel 8",
                "OnePlus 12",
                "Xiaomi 14"
            ]
        } else if type.contains("laptop") {
            return [
                "MacBook Pro",
                "Dell XPS 15",
                "HP Spectre",
                "Lenovo ThinkPad",
                "ASUS ZenBook"
            ]
        } else if type.contains("restaurant") {
            return [
                "Italian Bistro",
                "Japanese Sushi Bar",
                "Mexican Cantina",
                "French Brasserie",
                "American Steakhouse"
            ]
        } else if type.contains("hotel") {
            return [
                "Luxury Resort",
                "Boutique Hotel",
                "Business Hotel",
                "Budget Inn",
                "Bed & Breakfast"
            ]
        } else if type.contains("job") || type.contains("career") {
            return [
                "Software Engineer",
                "Product Manager",
                "Data Scientist",
                "Designer",
                "Marketing Manager"
            ]
        }
        
        // Try to extract from context if available
        if !context.isEmpty {
            // Look for common patterns like "between X and Y" or "X vs Y"
            let betweenPattern = "between (.+?) and (.+?)(\\.|\\?|$)"
            let vsPattern = "(.+?) vs (.+?)(\\.|\\?|$)"
            
            if let regex = try? NSRegularExpression(pattern: betweenPattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: context, options: [], range: NSRange(context.startIndex..., in: context)),
               match.numberOfRanges > 2,
               let range1 = Range(match.range(at: 1), in: context),
               let range2 = Range(match.range(at: 2), in: context) {
                return [
                    String(context[range1]).trimmingCharacters(in: .whitespacesAndNewlines),
                    String(context[range2]).trimmingCharacters(in: .whitespacesAndNewlines)
                ]
            }
            
            if let regex = try? NSRegularExpression(pattern: vsPattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: context, options: [], range: NSRange(context.startIndex..., in: context)),
               match.numberOfRanges > 2,
               let range1 = Range(match.range(at: 1), in: context),
               let range2 = Range(match.range(at: 2), in: context) {
                return [
                    String(context[range1]).trimmingCharacters(in: .whitespacesAndNewlines),
                    String(context[range2]).trimmingCharacters(in: .whitespacesAndNewlines)
                ]
            }
        }
        
        // Generic fallback - ensure at least 2 options
        return [
            "Option A",
            "Option B",
            "Option C"
        ]
    }
    
    // MARK: - Criteria Generation with Weights
    
    private func generateCriteriaWithWeights(for decisionType: String, description: String) -> [QuickDecisionSetup.CriterionSetup] {
        let type = decisionType.lowercased()
        let desc = description.lowercased()
        
        var criteria: [QuickDecisionSetup.CriterionSetup] = []
        
        // Product-specific criteria with automatic weighting
        if type.contains("putter") || desc.contains("putter") || desc.contains("golf putter") {
            criteria = [
                QuickDecisionSetup.CriterionSetup(name: "Price", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Look", weight: 3),
                QuickDecisionSetup.CriterionSetup(name: "Feel", weight: 5),
                QuickDecisionSetup.CriterionSetup(name: "Balance", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Brand", weight: 3)
            ]
        } else if type.contains("car") || type.contains("vehicle") {
            criteria = [
                QuickDecisionSetup.CriterionSetup(name: "Price", weight: 5),
                QuickDecisionSetup.CriterionSetup(name: "Fuel Efficiency", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Safety Features", weight: 5),
                QuickDecisionSetup.CriterionSetup(name: "Reliability", weight: 5),
                QuickDecisionSetup.CriterionSetup(name: "Resale Value", weight: 3)
            ]
        } else if type.contains("phone") || type.contains("smartphone") {
            criteria = [
                QuickDecisionSetup.CriterionSetup(name: "Price", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Camera Quality", weight: 5),
                QuickDecisionSetup.CriterionSetup(name: "Battery Life", weight: 5),
                QuickDecisionSetup.CriterionSetup(name: "Performance", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Design", weight: 3)
            ]
        } else if type.contains("laptop") {
            criteria = [
                QuickDecisionSetup.CriterionSetup(name: "Price", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Performance", weight: 5),
                QuickDecisionSetup.CriterionSetup(name: "Battery Life", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Portability", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Build Quality", weight: 4)
            ]
        } else {
            // Generic criteria - always generate at least 3-4 relevant criteria
            criteria = [
                QuickDecisionSetup.CriterionSetup(name: "Price", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Quality", weight: 5),
                QuickDecisionSetup.CriterionSetup(name: "Features", weight: 4),
                QuickDecisionSetup.CriterionSetup(name: "Reputation", weight: 3),
                QuickDecisionSetup.CriterionSetup(name: "Value for Money", weight: 4)
            ]
        }
        
        // Adjust weights based on description keywords for better context understanding
        if desc.contains("budget") || desc.contains("cheap") || desc.contains("affordable") {
            if let index = criteria.firstIndex(where: { $0.name.lowercased().contains("price") }) {
                criteria[index] = QuickDecisionSetup.CriterionSetup(name: criteria[index].name, weight: 6)
            }
        }
        
        if desc.contains("quality") || desc.contains("premium") || desc.contains("luxury") {
            if let index = criteria.firstIndex(where: { $0.name.lowercased().contains("quality") }) {
                criteria[index] = QuickDecisionSetup.CriterionSetup(name: criteria[index].name, weight: 6)
            }
        }
        
        if desc.contains("performance") || desc.contains("speed") {
            if let index = criteria.firstIndex(where: { $0.name.lowercased().contains("performance") || $0.name.lowercased().contains("features") }) {
                criteria[index] = QuickDecisionSetup.CriterionSetup(name: criteria[index].name, weight: 6)
            }
        }
        
        // Ensure we have at least 2 criteria
        if criteria.count < 2 {
            criteria.append(QuickDecisionSetup.CriterionSetup(name: "Overall Value", weight: 4))
        }
        
        return criteria
    }
    
    private func generateCriteriaLocally(decisionName: String, description: String) -> [String] {
        // This is a simple implementation that generates criteria based on common decision factors
        // In a real app, you would use an AI API to generate more relevant criteria
        
        let nameLower = decisionName.lowercased()
        
        // General criteria that apply to most decisions
        var criteria = [
            "Cost effectiveness",
            "Long-term value",
            "Ease of implementation",
            "Time required",
            "Risk level"
        ]
        
        // Add decision-specific criteria
        if nameLower.contains("car") || nameLower.contains("vehicle") {
            criteria.append(contentsOf: [
                "Fuel efficiency",
                "Safety features",
                "Maintenance costs",
                "Resale value",
                "Comfort and convenience"
            ])
        } else if nameLower.contains("house") || nameLower.contains("home") {
            criteria.append(contentsOf: [
                "Location quality",
                "Size and layout",
                "Property condition",
                "Neighborhood safety",
                "Investment potential"
            ])
        } else if nameLower.contains("job") || nameLower.contains("career") {
            criteria.append(contentsOf: [
                "Salary and benefits",
                "Work-life balance",
                "Growth opportunities",
                "Company culture",
                "Commute time"
            ])
        } else if nameLower.contains("vacation") || nameLower.contains("trip") {
            criteria.append(contentsOf: [
                "Destination appeal",
                "Accommodation quality",
                "Activities available",
                "Travel convenience",
                "Weather conditions"
            ])
        }
        
        // Use description to add more specific criteria if possible
        let descriptionLower = description.lowercased()
        if descriptionLower.contains("budget") || descriptionLower.contains("money") {
            criteria.append("Budget alignment")
        }
        if descriptionLower.contains("family") {
            criteria.append("Family-friendliness")
        }
        if descriptionLower.contains("time") {
            criteria.append("Time efficiency")
        }
        
        // Return a maximum of 10 criteria
        return Array(criteria.prefix(10))
    }
}

