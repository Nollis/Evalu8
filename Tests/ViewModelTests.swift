import XCTest
import CoreData
@testable import Evalu8

@MainActor
final class ViewModelTests: XCTestCase {
    var testContext: NSManagedObjectContext!
    var dataStore: DataStore!
    
    override func setUp() {
        super.setUp()
        dataStore = DataStore(inMemory: true)
        testContext = dataStore.container.viewContext
    }
    
    override func tearDown() {
        testContext = nil
        dataStore = nil
        super.tearDown()
    }
    
    // MARK: - DecisionListViewModel Tests
    
    func testLoadDecisions() throws {
        let repository = DecisionRepository(context: testContext)
        _ = try repository.create(title: "Decision 1", description: nil, scoringScale: 5)
        _ = try repository.create(title: "Decision 2", description: nil, scoringScale: 5)
        
        let viewModel = DecisionListViewModel(
            decisionRepository: DecisionRepository(context: testContext),
            context: testContext
        )
        
        // Wait a bit for async operations
        let expectation = expectation(description: "Decisions loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertGreaterThanOrEqual(viewModel.decisions.count, 2)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCreateDecision() throws {
        let viewModel = DecisionListViewModel(
            decisionRepository: DecisionRepository(context: testContext),
            context: testContext
        )
        
        viewModel.createDecision(
            title: "New Decision",
            description: "Test Description",
            scoringScale: 5
        )
        
        let expectation = expectation(description: "Decision created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(viewModel.decisions.contains { $0.title == "New Decision" })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - DecisionDetailViewModel Tests
    
    func testLoadDecisionData() throws {
        let decisionRepo = DecisionRepository(context: testContext)
        let optionRepo = OptionRepository(context: testContext)
        let criterionRepo = CriterionRepository(context: testContext)
        
        let decision = try decisionRepo.create(
            title: "Test Decision",
            description: "Test Description",
            scoringScale: 5
        )
        
        _ = try optionRepo.create(name: "Option 1", for: decision)
        _ = try criterionRepo.create(name: "Criterion 1", weight: 3, for: decision)
        
        let viewModel = DecisionDetailViewModel(
            decision: decision,
            optionRepository: OptionRepository(context: testContext),
            criterionRepository: CriterionRepository(context: testContext),
            decisionRepository: DecisionRepository(context: testContext),
            context: testContext
        )
        
        let expectation = expectation(description: "Data loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.options.count, 1)
            XCTAssertEqual(viewModel.criteria.count, 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddOption() throws {
        let decisionRepo = DecisionRepository(context: testContext)
        let decision = try decisionRepo.create(
            title: "Test Decision",
            description: nil,
            scoringScale: 5
        )
        
        let viewModel = DecisionDetailViewModel(
            decision: decision,
            context: testContext
        )
        
        viewModel.addOption(name: "New Option")
        
        let expectation = expectation(description: "Option added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(viewModel.options.contains { $0.name == "New Option" })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddCriterion() throws {
        let decisionRepo = DecisionRepository(context: testContext)
        let decision = try decisionRepo.create(
            title: "Test Decision",
            description: nil,
            scoringScale: 5
        )
        
        let viewModel = DecisionDetailViewModel(
            decision: decision,
            context: testContext
        )
        
        viewModel.addCriterion(name: "New Criterion", weight: 5)
        
        let expectation = expectation(description: "Criterion added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(viewModel.criteria.contains { $0.name == "New Criterion" && $0.weight == 5 })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

