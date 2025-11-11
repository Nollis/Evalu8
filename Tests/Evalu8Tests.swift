import XCTest
@testable import Evalu8

final class Evalu8Tests: XCTestCase {
    
    func testScoreCalculator() {
        // Test normalized score calculation
        let score = ScoreCalculator.normalizedScore(
            ratingValue: 5,
            criterionWeight: 3,
            maxWeight: 10
        )
        
        XCTAssertEqual(score, 0.15, accuracy: 0.01)
    }
    
    func testScoreCalculatorWeightedScore() {
        let ratings = ["criterion1": Int16(5), "criterion2": Int16(3)]
        let weights = ["criterion1": Int16(3), "criterion2": Int16(2)]
        
        let totalScore = ScoreCalculator.weightedScore(
            ratings: ratings,
            criterionWeights: weights,
            maxWeight: 10
        )
        
        XCTAssertGreaterThan(totalScore, 0)
    }
    
    func testUserRolePermissions() {
        let owner = UserRole.owner
        let participant = UserRole.participant
        
        XCTAssertTrue(owner.canModifyStructure)
        XCTAssertFalse(participant.canModifyStructure)
        XCTAssertTrue(owner.canAddRatings)
        XCTAssertTrue(participant.canAddRatings)
    }
    
    func testActivityLogEquality() {
        let log1 = ActivityLog(
            userID: "user1",
            userName: "Test User",
            action: .addCriterion,
            timestamp: Date(),
            decisionID: "decision1",
            details: [:]
        )
        
        let log2 = ActivityLog(
            userID: "user1",
            userName: "Test User",
            action: .addCriterion,
            timestamp: log1.timestamp,
            decisionID: "decision1",
            details: [:]
        )
        
        XCTAssertEqual(log1, log2)
    }
}

