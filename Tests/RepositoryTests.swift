import XCTest
import CoreData
@testable import Evalu8

final class RepositoryTests: XCTestCase {
    var testContext: NSManagedObjectContext!
    var dataStore: DataStore!
    
    override func setUp() {
        super.setUp()
        // Use in-memory store for testing
        dataStore = DataStore(inMemory: true)
        testContext = dataStore.container.viewContext
    }
    
    override func tearDown() {
        testContext = nil
        dataStore = nil
        super.tearDown()
    }
    
    // MARK: - DecisionRepository Tests
    
    func testCreateDecision() throws {
        let repository = DecisionRepository(context: testContext)
        
        let decision = try repository.create(
            title: "Test Decision",
            description: "Test Description",
            scoringScale: 5
        )
        
        XCTAssertNotNil(decision)
        XCTAssertEqual(decision.title, "Test Decision")
        XCTAssertEqual(decision.desc, "Test Description")
        XCTAssertEqual(decision.scoringScale, 5)
        XCTAssertNotNil(decision.uuid)
        XCTAssertNotNil(decision.dateCreated)
    }
    
    func testFetchAllDecisions() throws {
        let repository = DecisionRepository(context: testContext)
        
        // Create test decisions
        _ = try repository.create(title: "Decision 1", description: nil, scoringScale: 5)
        _ = try repository.create(title: "Decision 2", description: nil, scoringScale: 5)
        
        let decisions = try repository.fetchAll()
        
        XCTAssertEqual(decisions.count, 2)
    }
    
    func testUpdateDecision() throws {
        let repository = DecisionRepository(context: testContext)
        
        let decision = try repository.create(
            title: "Original Title",
            description: nil,
            scoringScale: 5
        )
        
        decision.title = "Updated Title"
        try repository.update(decision)
        
        let fetched = try repository.fetch(byID: decision.objectID)
        XCTAssertEqual(fetched?.title, "Updated Title")
    }
    
    func testDeleteDecision() throws {
        let repository = DecisionRepository(context: testContext)
        
        let decision = try repository.create(
            title: "To Delete",
            description: nil,
            scoringScale: 5
        )
        
        try repository.delete(decision)
        
        let fetched = try repository.fetch(byID: decision.objectID)
        XCTAssertNil(fetched)
    }
    
    // MARK: - OptionRepository Tests
    
    func testCreateOption() throws {
        let decisionRepo = DecisionRepository(context: testContext)
        let optionRepo = OptionRepository(context: testContext)
        
        let decision = try decisionRepo.create(
            title: "Test Decision",
            description: nil,
            scoringScale: 5
        )
        
        let option = try optionRepo.create(name: "Test Option", for: decision)
        
        XCTAssertNotNil(option)
        XCTAssertEqual(option.name, "Test Option")
        XCTAssertEqual(option.decision, decision)
        XCTAssertNotNil(option.dateCreated)
    }
    
    func testFetchOptionsForDecision() throws {
        let decisionRepo = DecisionRepository(context: testContext)
        let optionRepo = OptionRepository(context: testContext)
        
        let decision = try decisionRepo.create(
            title: "Test Decision",
            description: nil,
            scoringScale: 5
        )
        
        _ = try optionRepo.create(name: "Option 1", for: decision)
        _ = try optionRepo.create(name: "Option 2", for: decision)
        
        let options = try optionRepo.fetchAll(for: decision)
        
        XCTAssertEqual(options.count, 2)
    }
    
    // MARK: - CriterionRepository Tests
    
    func testCreateCriterion() throws {
        let decisionRepo = DecisionRepository(context: testContext)
        let criterionRepo = CriterionRepository(context: testContext)
        
        let decision = try decisionRepo.create(
            title: "Test Decision",
            description: nil,
            scoringScale: 5
        )
        
        let criterion = try criterionRepo.create(
            name: "Test Criterion",
            weight: 3,
            for: decision
        )
        
        XCTAssertNotNil(criterion)
        XCTAssertEqual(criterion.name, "Test Criterion")
        XCTAssertEqual(criterion.weight, 3)
        XCTAssertEqual(criterion.decision, decision)
    }
    
    // MARK: - RatingRepository Tests
    
    func testCreateRating() throws {
        let decisionRepo = DecisionRepository(context: testContext)
        let optionRepo = OptionRepository(context: testContext)
        let criterionRepo = CriterionRepository(context: testContext)
        let ratingRepo = RatingRepository(context: testContext)
        
        let decision = try decisionRepo.create(
            title: "Test Decision",
            description: nil,
            scoringScale: 5
        )
        
        let option = try optionRepo.create(name: "Test Option", for: decision)
        let criterion = try criterionRepo.create(name: "Test Criterion", weight: 3, for: decision)
        
        let rating = try ratingRepo.createOrUpdate(
            option: option,
            criterion: criterion,
            ratingValue: 4,
            userID: "test-user",
            userDisplayName: "Test User"
        )
        
        XCTAssertNotNil(rating)
        XCTAssertEqual(rating.ratingValue, 4)
        XCTAssertEqual(rating.option, option)
        XCTAssertEqual(rating.criterion, criterion)
        XCTAssertEqual(rating.userRecordID, "test-user")
    }
    
    func testUpdateExistingRating() throws {
        let decisionRepo = DecisionRepository(context: testContext)
        let optionRepo = OptionRepository(context: testContext)
        let criterionRepo = CriterionRepository(context: testContext)
        let ratingRepo = RatingRepository(context: testContext)
        
        let decision = try decisionRepo.create(
            title: "Test Decision",
            description: nil,
            scoringScale: 5
        )
        
        let option = try optionRepo.create(name: "Test Option", for: decision)
        let criterion = try criterionRepo.create(name: "Test Criterion", weight: 3, for: decision)
        
        // Create initial rating
        _ = try ratingRepo.createOrUpdate(
            option: option,
            criterion: criterion,
            ratingValue: 3,
            userID: "test-user",
            userDisplayName: nil
        )
        
        // Update rating
        let updatedRating = try ratingRepo.createOrUpdate(
            option: option,
            criterion: criterion,
            ratingValue: 5,
            userID: "test-user",
            userDisplayName: nil
        )
        
        XCTAssertEqual(updatedRating.ratingValue, 5)
        
        // Verify only one rating exists
        let allRatings = try ratingRepo.fetchAll(for: option)
        XCTAssertEqual(allRatings.count, 1)
    }
}

