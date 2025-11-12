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
                            .foregroundStyle(Color.primaryGradient)
                    }
                    
                    Button(action: {
                        viewModel.showingAddDecision = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.primaryGradient)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: decision.iconName ?? "folder")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(decision.title ?? "Untitled Decision")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    if let desc = decision.desc, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.brandPrimary)
                    Text("\(decision.options?.count ?? 0)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.brandPrimary)
                    Text("\(decision.criteria?.count ?? 0)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                if let dateCreated = decision.dateCreated {
                    Text(dateCreated, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cardBorder.opacity(0.3), lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.primaryGradientStart.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.primaryGradient)
                }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(actionTitle)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primaryGradient)
                )
                .shadow(color: Color.primaryGradientStart.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

#Preview {
    DecisionListView()
        .environment(\.managedObjectContext, DataStore.preview.container.viewContext)
}

