import Foundation

/// Represents a complete decision setup generated from a natural language query
struct QuickDecisionSetup {
    let title: String
    let description: String?
    let options: [String]
    let criteria: [CriterionSetup]
    let scoringScale: Int16
    
    struct CriterionSetup {
        let name: String
        let weight: Int16
    }
}

