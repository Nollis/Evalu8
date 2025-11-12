import Foundation
import CoreData
import SwiftUI

@MainActor
class DecisionDetailViewModel: ObservableObject {
    @Published var decision: Decision
    @Published var options: [Option] = []
    @Published var criteria: [Criterion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddOption = false
    @Published var showingAddCriterion = false
    @Published var showingEditDecision = false
    
    private let optionRepository: OptionRepositoryProtocol
    private let criterionRepository: CriterionRepositoryProtocol
    private let decisionRepository: DecisionRepositoryProtocol
    private let context: NSManagedObjectContext
    
    init(
        decision: Decision,
        optionRepository: OptionRepositoryProtocol = OptionRepository(),
        criterionRepository: CriterionRepositoryProtocol = CriterionRepository(),
        decisionRepository: DecisionRepositoryProtocol = DecisionRepository(),
        context: NSManagedObjectContext = DataStore.shared.container.viewContext
    ) {
        self.decision = decision
        self.optionRepository = optionRepository
        self.criterionRepository = criterionRepository
        self.decisionRepository = decisionRepository
        self.context = context
        loadData()
        observeChanges()
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        do {
            options = try optionRepository.fetchAll(for: decision)
            criteria = try criterionRepository.fetchAll(for: decision)
            isLoading = false
            Logger.shared.log("Loaded \(options.count) options and \(criteria.count) criteria", level: .info)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            Logger.shared.log("Error loading decision data: \(error.localizedDescription)", level: .error)
        }
    }
    
    func addOption(name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Option name cannot be empty"
            return
        }
        
        do {
            _ = try optionRepository.create(name: name, for: decision)
            loadData() // Reload to include the new option
            HapticManager.notification(type: .success)
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.log("Error adding option: \(error.localizedDescription)", level: .error)
        }
    }
    
    func deleteOption(_ option: Option) {
        do {
            try optionRepository.delete(option)
            loadData() // Reload to update the list
            HapticManager.impact(style: .medium)
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.log("Error deleting option: \(error.localizedDescription)", level: .error)
        }
    }
    
    func addCriterion(name: String, weight: Int16) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Criterion name cannot be empty"
            return
        }
        
        do {
            _ = try criterionRepository.create(name: name, weight: weight, for: decision)
            loadData() // Reload to include the new criterion
            HapticManager.notification(type: .success)
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.log("Error adding criterion: \(error.localizedDescription)", level: .error)
        }
    }
    
    func deleteCriterion(_ criterion: Criterion) {
        do {
            try criterionRepository.delete(criterion)
            loadData() // Reload to update the list
            HapticManager.impact(style: .medium)
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.log("Error deleting criterion: \(error.localizedDescription)", level: .error)
        }
    }
    
    func updateDecision(title: String, description: String?, scoringScale: Int16) {
        decision.title = title
        decision.desc = description
        decision.scoringScale = scoringScale
        
        do {
            try decisionRepository.update(decision)
            HapticManager.notification(type: .success)
        } catch {
            errorMessage = error.localizedDescription
            Logger.shared.log("Error updating decision: \(error.localizedDescription)", level: .error)
        }
    }
    
    private func observeChanges() {
        // Observe Core Data changes for this decision
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadData()
            }
        }
    }
}

