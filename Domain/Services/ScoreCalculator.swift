import Foundation

enum ScoreCalculator {
    /// Calculates a normalized score between 0 and 1
    /// - Parameters:
    ///   - ratingValue: The raw rating value
    ///   - criterionWeight: The weight of the criterion
    ///   - maxWeight: The maximum possible weight
    /// - Returns: A normalized score between 0 and 1
    static func normalizedScore(ratingValue: Int16, criterionWeight: Int16, maxWeight: Int16) -> Double {
        // Guard against division by zero
        guard maxWeight > 0 else {
            return 0.0
        }
        
        let denominator = 5.0 * Double(maxWeight)
        guard denominator > 0 else {
            return 0.0
        }
        
        // Normalize so that the score is between 0 and 1
        let score = (Double(ratingValue) * Double(criterionWeight)) / denominator
        
        // Ensure score is valid (not NaN or Infinity)
        guard score.isFinite else {
            return 0.0
        }
        
        return score
    }
    
    /// Calculates weighted score for an option across all criteria
    /// - Parameters:
    ///   - ratings: Dictionary mapping criterion ID to rating value
    ///   - criterionWeights: Dictionary mapping criterion ID to weight
    ///   - maxWeight: The maximum possible weight
    /// - Returns: Total weighted score
    static func weightedScore(
        ratings: [String: Int16],
        criterionWeights: [String: Int16],
        maxWeight: Int16
    ) -> Double {
        // Guard against invalid maxWeight
        guard maxWeight > 0 else {
            return 0.0
        }
        
        var totalScore: Double = 0.0
        
        for (criterionID, rating) in ratings {
            if let weight = criterionWeights[criterionID] {
                totalScore += normalizedScore(
                    ratingValue: rating,
                    criterionWeight: weight,
                    maxWeight: maxWeight
                )
            }
        }
        
        // Ensure total score is valid (not NaN or Infinity)
        guard totalScore.isFinite else {
            return 0.0
        }
        
        return totalScore
    }
}

