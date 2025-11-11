import SwiftUI

struct AddDecisionView: View {
    @ObservedObject var viewModel: DecisionListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var scoringScale: Int16 = 5
    
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
            .navigationTitle("New Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createDecision()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createDecision() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.createDecision(
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            scoringScale: scoringScale
        )
        
        dismiss()
    }
}

#Preview {
    AddDecisionView(viewModel: DecisionListViewModel())
}

