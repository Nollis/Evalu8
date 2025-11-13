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
        // Load decisions immediately on init
        loadDecisions()
    }
    
    func loadDecisions() {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedDecisions = try decisionRepository.fetchAll()
            decisions = fetchedDecisions
            isLoading = false
            Logger.shared.log("Loaded \(decisions.count) decisions", level: .info)
            
            // Debug: Log decision details
            if decisions.isEmpty {
                Logger.shared.log("No decisions found in database", level: .warning)
            } else {
                for decision in decisions {
                    Logger.shared.log("Decision: \(decision.title ?? "Untitled") (UUID: \(decision.uuid ?? "none"))", level: .info)
                }
            }
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
            // Ensure we're using the same context for all operations
            let workingContext = context
            
            // Create the decision using a repository with the same context
            let decisionRepo = DecisionRepository(context: workingContext)
            let decision = try decisionRepo.create(
                title: setup.title,
                description: setup.description,
                scoringScale: setup.scoringScale
            )
            
            Logger.shared.log("Created decision: \(setup.title) with UUID: \(decision.uuid ?? "none")", level: .info)
            
            // Add options
            let optionRepository = OptionRepository(context: workingContext)
            for optionSetup in setup.options {
                _ = try optionRepository.create(
                    name: optionSetup.name,
                    description: optionSetup.description,
                    imageURL: optionSetup.imageURL,
                    internetRating: optionSetup.internetRating,
                    for: decision
                )
            }
            
            // Add criteria
            let criterionRepository = CriterionRepository(context: workingContext)
            for criterionSetup in setup.criteria {
                _ = try criterionRepository.create(
                    name: criterionSetup.name,
                    description: criterionSetup.description,
                    weight: criterionSetup.weight,
                    for: decision
                )
            }
            
            // Ensure context is saved
            try workingContext.save()
            Logger.shared.log("Saved context after creating quick decision. Context has changes: \(workingContext.hasChanges)", level: .info)
            
            // Reload immediately
            loadDecisions()
            
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

