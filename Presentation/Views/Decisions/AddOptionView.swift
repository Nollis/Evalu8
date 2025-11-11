import SwiftUI

struct AddOptionView: View {
    @ObservedObject var viewModel: DecisionDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Option Details") {
                    TextField("Option Name", text: $name)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Add Option")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addOption()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addOption() {
        viewModel.addOption(name: name)
        dismiss()
    }
}

#Preview {
    let decision = DataStore.preview.container.viewContext.registeredObjects.first { $0 is Decision } as! Decision
    AddOptionView(viewModel: DecisionDetailViewModel(decision: decision))
}

