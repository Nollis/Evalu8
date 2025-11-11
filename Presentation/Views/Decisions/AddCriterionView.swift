import SwiftUI

struct AddCriterionView: View {
    @ObservedObject var viewModel: DecisionDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var weight: Int16 = 1
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Criterion Details") {
                    TextField("Criterion Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Stepper("Weight: \(weight)", value: $weight, in: 1...10)
                    
                    Text("Higher weight means this criterion is more important")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Criterion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCriterion()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addCriterion() {
        viewModel.addCriterion(name: name, weight: weight)
        dismiss()
    }
}

#Preview {
    let decision = DataStore.preview.container.viewContext.registeredObjects.first { $0 is Decision } as! Decision
    AddCriterionView(viewModel: DecisionDetailViewModel(decision: decision))
}

