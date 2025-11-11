import SwiftUI

struct EditDecisionView: View {
    @ObservedObject var viewModel: DecisionDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var scoringScale: Int16
    
    init(viewModel: DecisionDetailViewModel) {
        self.viewModel = viewModel
        _title = State(initialValue: viewModel.decision.title ?? "")
        _description = State(initialValue: viewModel.decision.desc ?? "")
        _scoringScale = State(initialValue: viewModel.decision.scoringScale)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Decision Details") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Scoring") {
                    Stepper("Scale: \(scoringScale)", value: $scoringScale, in: 1...10)
                    
                    Text("Options will be rated from 1 to \(scoringScale)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDecision()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveDecision() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.updateDecision(
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            scoringScale: scoringScale
        )
        
        dismiss()
    }
}

#Preview {
    let decision = DataStore.preview.container.viewContext.registeredObjects.first { $0 is Decision } as! Decision
    EditDecisionView(viewModel: DecisionDetailViewModel(decision: decision))
}

