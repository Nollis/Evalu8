import SwiftUI
import CoreData

struct DecisionDetailView: View {
    @StateObject private var viewModel: DecisionDetailViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    init(decision: Decision) {
        _viewModel = StateObject(wrappedValue: DecisionDetailViewModel(decision: decision))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Decision Info Section
                VStack(alignment: .leading, spacing: 12) {
                    if let desc = viewModel.decision.desc, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Scale: \(viewModel.decision.scoringScale)", systemImage: "star.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let dateCreated = viewModel.decision.dateCreated {
                            Text("Created \(dateCreated, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Options Section
                SectionHeader(
                    title: "Options",
                    count: viewModel.options.count,
                    action: { viewModel.showingAddOption = true }
                )
                
                if viewModel.options.isEmpty {
                    EmptySectionView(
                        message: "No options yet",
                        actionTitle: "Add Option",
                        action: { viewModel.showingAddOption = true }
                    )
                } else {
                    ForEach(viewModel.options) { option in
                        OptionRow(option: option) {
                            viewModel.deleteOption(option)
                        }
                    }
                }
                
                // Criteria Section
                SectionHeader(
                    title: "Criteria",
                    count: viewModel.criteria.count,
                    action: { viewModel.showingAddCriterion = true }
                )
                
                if viewModel.criteria.isEmpty {
                    EmptySectionView(
                        message: "No criteria yet",
                        actionTitle: "Add Criterion",
                        action: { viewModel.showingAddCriterion = true }
                    )
                } else {
                    ForEach(viewModel.criteria) { criterion in
                        CriterionRow(criterion: criterion) {
                            viewModel.deleteCriterion(criterion)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.decision.title ?? "Decision")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    viewModel.showingEditDecision = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddOption) {
            AddOptionView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddCriterion) {
            AddCriterionView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingEditDecision) {
            EditDecisionView(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let count: Int
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("(\(count))")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
    }
}

struct OptionRow: View {
    let option: Option
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(option.name ?? "Unnamed Option")
                .font(.body)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CriterionRow: View {
    let criterion: Criterion
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(criterion.name ?? "Unnamed Criterion")
                    .font(.body)
                
                Text("Weight: \(criterion.weight)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmptySectionView: View {
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: action) {
                Label(actionTitle, systemImage: "plus")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        DecisionDetailView(decision: DataStore.preview.container.viewContext.registeredObjects.first { $0 is Decision } as! Decision)
    }
    .environment(\.managedObjectContext, DataStore.preview.container.viewContext)
}

