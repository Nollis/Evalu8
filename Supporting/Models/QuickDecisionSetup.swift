import Foundation

/// Represents a complete decision setup generated from a natural language query
struct QuickDecisionSetup {
    let title: String
    let description: String?
    let options: [OptionSetup]
    let criteria: [CriterionSetup]
    let scoringScale: Int16
    
    struct OptionSetup {
        let name: String
        let description: String?
        let imageURL: String?
        let internetRating: Double? // Rating from 0.0 to 5.0
    }
    
    struct CriterionSetup {
        let name: String
        let description: String?
        let weight: Int16
    }
}

