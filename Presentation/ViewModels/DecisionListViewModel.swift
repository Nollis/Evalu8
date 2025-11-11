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
        self.decisionRepository = decisionRepository
        self.context = context
        observeChanges()
    }
    
    func loadDecisions() {
        isLoading = true
        errorMessage = nil
        
        do {
            decisions = try decisionRepository.fetchAll()
            isLoading = false
            Logger.shared.log("Loaded \(decisions.count) decisions", level: .info)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            Logger.shared.log("Error loading decisions: \(error.localizedDescription)", level: .error)
        }
    }
    
    func deleteDecision(_ decision: Decision) {
        do {
            try decisionRepository.delete(decision)
            loadDecisions() // Reload to update the list
            HapticManager.shared.impact(.medium)
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.log("Error deleting decision: \(error.localizedDescription)", level: .error)
        }
    }
    
    func createDecision(title: String, description: String?, scoringScale: Int16) {
        do {
            let decision = try decisionRepository.create(
                title: title,
                description: description,
                scoringScale: scoringScale
            )
            loadDecisions() // Reload to include the new decision
            HapticManager.shared.notification(.success)
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
            HapticManager.shared.notification(.success)
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
            self?.loadDecisions()
        }
    }
}

