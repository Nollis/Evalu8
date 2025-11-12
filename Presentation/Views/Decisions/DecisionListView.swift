import SwiftUI
import CoreData

struct DecisionListView: View {
    @StateObject private var viewModel = DecisionListViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading decisions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.decisions.isEmpty {
                    EmptyStateView(
                        title: "No Decisions Yet",
                        message: "Create your first decision to get started",
                        actionTitle: "Add Decision",
                        action: { viewModel.showingAddDecision = true }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.decisions) { decision in
                            NavigationLink {
                                DecisionDetailView(decision: decision)
                            } label: {
                                DecisionRow(decision: decision)
                            }
                        }
                        .onDelete(perform: deleteDecisions)
                    }
                    .refreshable {
                        viewModel.loadDecisions()
                    }
                }
            }
            .navigationTitle("Decisions")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showingQuickDecision = true
                    }) {
                        Image(systemName: "sparkles")
                    }
                    
                    Button(action: {
                        viewModel.showingAddDecision = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddDecision) {
                AddDecisionView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingQuickDecision) {
                QuickDecisionView(viewModel: viewModel)
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
            .onAppear {
                viewModel.loadDecisions()
            }
        }
    }
    
    private func deleteDecisions(offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteDecision(viewModel.decisions[index])
        }
    }
}

struct DecisionRow: View {
    let decision: Decision
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: decision.iconName ?? "folder")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(decision.title ?? "Untitled Decision")
                        .font(.headline)
                    
                    if let desc = decision.desc, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            
            HStack {
                Label("\(decision.options?.count ?? 0)", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(decision.criteria?.count ?? 0)", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let dateCreated = decision.dateCreated {
                    Text(dateCreated, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: action) {
                Label(actionTitle, systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

#Preview {
    DecisionListView()
        .environment(\.managedObjectContext, DataStore.preview.container.viewContext)
}

