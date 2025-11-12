import Foundation
import CoreData
import SwiftUI

@MainActor
class DecisionListViewModel: ObservableObject {
    @Published var decisions: [Decision] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddDecision = false
    @Published var showingQuickDecision = false
    
    private let decisionRepository: DecisionRepositoryProtocol
    private let context: NSManagedObjectContext
    
    init(
        decisionRepository: DecisionRepositoryProtocol = DecisionRepository(),
        context: NSManagedObjectContext = DataStore.shared.container.viewContext
    ) {
        Logger.shared.log("DecisionListViewModel: Initializing", level: .info)
        self.decisionRepository = decisionRepository
        self.context = context
        Logger.shared.log("DecisionListViewModel: Context set, calling observeChanges", level: .info)
        observeChanges()
        Logger.shared.log("DecisionListViewModel: Calling loadDecisions", level: .info)
        // Load decisions immediately on init
        loadDecisions()
        Logger.shared.log("DecisionListViewModel: Initialization complete", level: .info)
    }
    
    func loadDecisions() {
        Logger.shared.log("DecisionListViewModel: loadDecisions() called", level: .info)
        isLoading = true
        errorMessage = nil
        
        do {
            decisions = try decisionRepository.fetchAll()
            isLoading = false
            Logger.shared.log("DecisionListViewModel: Loaded \(decisions.count) decisions", level: .info)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            Logger.shared.log("DecisionListViewModel: Error loading decisions: \(error.localizedDescription)", level: .error)
            Logger.shared.log("DecisionListViewModel: Error details: \(error)", level: .error)
        }
    }
    
    func deleteDecision(_ decision: Decision) {
        do {
            try decisionRepository.delete(decision)
            loadDecisions() // Reload to update the list
            HapticManager.impact(style: .medium)
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.log("Error deleting decision: \(error.localizedDescription)", level: .error)
        }
    }
    
    func createDecision(title: String, description: String?, scoringScale: Int16) {
        do {
            _ = try decisionRepository.create(
                title: title,
                description: description,
                scoringScale: scoringScale
            )
            loadDecisions() // Reload to include the new decision
            HapticManager.notification(type: .success)
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.log("Error creating decision: \(error.localizedDescription)", level: .error)
        }
    }
    
    func createQuickDecision(setup: QuickDecisionSetup) {
        do {
            // Create the decision
            let decision = try decisionRepository.create(
                title: setup.title,
                description: setup.description,
                scoringScale: setup.scoringScale
            )
            
            // Add options
            let optionRepository = OptionRepository(context: context)
            for optionName in setup.options {
                _ = try optionRepository.create(name: optionName, for: decision)
            }
            
            // Add criteria
            let criterionRepository = CriterionRepository(context: context)
            for criterionSetup in setup.criteria {
                _ = try criterionRepository.create(
                    name: criterionSetup.name,
                    weight: criterionSetup.weight,
                    for: decision
                )
            }
            
            loadDecisions() // Reload to include the new decision
            HapticManager.notification(type: .success)
            Logger.shared.log("Created quick decision: \(setup.title) with \(setup.options.count) options and \(setup.criteria.count) criteria", level: .info)
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.log("Error creating quick decision: \(error.localizedDescription)", level: .error)
        }
    }
    
    private func observeChanges() {
        // Observe Core Data changes
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadDecisions()
            }
        }
    }
}

