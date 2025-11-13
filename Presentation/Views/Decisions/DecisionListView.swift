import SwiftUI
import CoreData

struct DecisionListView: View {
    @StateObject private var viewModel = DecisionListViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationStack {
            ZStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading decisions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.decisions.isEmpty {
                    VStack(spacing: 20) {
                        EmptyStateView(
                            primaryAction: { viewModel.showingQuickDecision = true },
                            secondaryAction: { viewModel.showingAddDecision = true }
                        )
                        
                        // Debug: Show reload button
                        Button(action: {
                            viewModel.loadDecisions()
                        }) {
                            Text("Reload Decisions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                        List {
                            ForEach(viewModel.decisions) { decision in
                                NavigationLink {
                                    DecisionDetailView(decision: decision)
                                } label: {
                                    DecisionRow(decision: decision)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteDecisions)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            viewModel.loadDecisions()
                        }
                    }
                }
                
                // Floating Action Button for Quick Decision (only show when there are decisions)
                if !viewModel.decisions.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                viewModel.showingQuickDecision = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Quick Decision")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.primaryGradient)
                                        .shadow(color: Color.primaryGradientStart.opacity(0.4), radius: 12, x: 0, y: 6)
                                )
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .allowsHitTesting(true) // Ensure button is tappable
                }
            }
            .navigationTitle("Decisions")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Menu for secondary actions
                    Menu {
                        Button(action: {
                            viewModel.showingAddDecision = true
                        }) {
                            Label("Create Manually", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
            .task {
                // Also load on task to ensure it happens
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
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Hero icon
            ZStack {
                Circle()
                    .fill(Color.primaryGradientStart.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.primaryGradient)
            }
            
            VStack(spacing: 12) {
                Text("Create Your First Decision")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Describe what you're deciding on, and AI will set it up for you with options, criteria, and ratings")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            
            VStack(spacing: 16) {
                // Primary CTA - Quick Decision
                Button(action: primaryAction) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Create with AI")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primaryGradient)
                    )
                    .shadow(color: Color.primaryGradientStart.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                
                // Secondary CTA - Manual creation
                Button(action: secondaryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                        Text("Create Manually")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.cardBorder, lineWidth: 1.5)
                            )
                    )
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    DecisionListView()
        .environment(\.managedObjectContext, DataStore.preview.container.viewContext)
}

