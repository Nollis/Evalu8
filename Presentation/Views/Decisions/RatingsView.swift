import SwiftUI
import CoreData

struct RatingsView: View {
    @ObservedObject var viewModel: DecisionDetailViewModel
    @State private var selectedOption: Option?
    @State private var showingRatingSheet = false
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate each option")
                        .font(.headline)
                    Text("Tap an option to rate it against all criteria")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Options List
                if !viewModel.options.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(viewModel.options) { option in
                            Button(action: {
                                selectedOption = option
                                showingRatingSheet = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.name ?? "Unknown Option")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        // Show average rating if available
                                        if let avgRating = getAverageRating(for: option) {
                                            HStack(spacing: 4) {
                                                StarRatingView(
                                                    rating: Int16(avgRating.rounded()),
                                                    maxRating: viewModel.decision.scoringScale,
                                                    interactive: false
                                                )
                                                Text(String(format: "%.1f", avgRating))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        } else {
                                            Text("Tap to rate")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Add options to start rating")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                // Summary Section
                if !viewModel.options.isEmpty && !viewModel.criteria.isEmpty {
                    ScoresSummaryView(
                        options: viewModel.options,
                        criteria: viewModel.criteria,
                        decision: viewModel.decision
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Ratings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingRatingSheet) {
            if let option = selectedOption {
                RatingSheetView(
                    option: option,
                    criteria: viewModel.criteria,
                    decision: viewModel.decision,
                    viewModel: viewModel
                )
            } else {
                NavigationStack {
                    VStack(spacing: 16) {
                        Text("No option selected")
                            .font(.headline)
                        Text("Please select an option to rate")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Close") {
                            showingRatingSheet = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .navigationTitle("Error")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showingRatingSheet = false
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: showingRatingSheet) { _, isShowing in
            if !isShowing {
                // Clear selection when sheet is dismissed
                selectedOption = nil
                // Reload data to refresh ratings display
                viewModel.loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            // Reload when Core Data saves to update ratings
            viewModel.loadData()
        }
    }
    
    private func getAverageRating(for option: Option) -> Double? {
        guard !viewModel.criteria.isEmpty else { return nil }
        
        let ratingRepository = RatingRepository()
        var totalRating: Double = 0
        var count: Int = 0
        
        for criterion in viewModel.criteria {
            do {
                if let rating = try ratingRepository.fetch(for: option, criterion: criterion, userID: nil),
                   rating.ratingValue > 0 {
                    totalRating += Double(rating.ratingValue)
                    count += 1
                }
            } catch {
                // Ignore errors
            }
        }
        
        return count > 0 ? totalRating / Double(count) : nil
    }
}


struct RatingSheetView: View {
    let option: Option
    let criteria: [Criterion]
    let decision: Decision
    @ObservedObject var viewModel: DecisionDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var ratings: [String: Int16] = [:]
    @State private var isLoading = true
    
    private var scoringScale: Int16 {
        max(decision.scoringScale, 5) // Default to 5 if 0 or invalid
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if criteria.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("No criteria available")
                            .font(.headline)
                        Text("Add criteria to this decision before rating")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    Form {
                        Section {
                            Text(option.name ?? "Unknown Option")
                                .font(.headline)
                        }
                        
                        Section("Rate against criteria") {
                            ForEach(criteria, id: \.objectID) { criterion in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(criterion.name ?? "Unknown")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Text("Weight: \(criterion.weight)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        StarRatingView(
                                            rating: ratings[criterion.objectID.uriRepresentation().absoluteString] ?? 0,
                                            maxRating: scoringScale,
                                            interactive: true
                                        ) { newRating in
                                            ratings[criterion.objectID.uriRepresentation().absoluteString] = newRating
                                            // Auto-save on change
                                            saveRating(for: criterion, value: newRating)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rate Option")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingRatings()
            }
        }
    }
    
    private func loadExistingRatings() {
        guard !criteria.isEmpty else {
            isLoading = false
            return
        }
        
        // Use the environment context
        let context = viewContext
        let ratingRepository = RatingRepository(context: context)
        
        // Use the option directly - it should be in the same context
        for criterion in criteria {
            do {
                if let rating = try ratingRepository.fetch(for: option, criterion: criterion, userID: nil) {
                    ratings[criterion.objectID.uriRepresentation().absoluteString] = rating.ratingValue
                } else {
                    ratings[criterion.objectID.uriRepresentation().absoluteString] = 0
                }
            } catch {
                Logger.shared.log("Error loading rating: \(error.localizedDescription)", level: .error)
                ratings[criterion.objectID.uriRepresentation().absoluteString] = 0
            }
        }
        
        isLoading = false
    }
    
    private func saveRating(for criterion: Criterion, value: Int16) {
        let context = viewContext
        let ratingRepository = RatingRepository(context: context)
        
        do {
            _ = try ratingRepository.createOrUpdate(
                option: option,
                criterion: criterion,
                ratingValue: value,
                userID: nil,
                userDisplayName: nil
            )
            HapticManager.selection()
            
            // Notify that data has changed to update other views
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
        } catch {
            Logger.shared.log("Error saving rating: \(error.localizedDescription)", level: .error)
            viewModel.errorMessage = "Failed to save rating: \(error.localizedDescription)"
        }
    }
}

struct ScoresSummaryView: View {
    let options: [Option]
    let criteria: [Criterion]
    let decision: Decision
    
    @State private var optionScores: [String: Double] = [:]
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weighted Scores")
                .font(.headline)
            
            if optionScores.isEmpty {
                Text("Rate options to see scores")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(options.sorted(by: { (optionScores[$0.objectID.uriRepresentation().absoluteString] ?? 0) > (optionScores[$1.objectID.uriRepresentation().absoluteString] ?? 0) }), id: \.objectID) { option in
                    if let score = optionScores[option.objectID.uriRepresentation().absoluteString] {
                        HStack {
                            Text(option.name ?? "Unknown")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(String(format: "%.2f", score))
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onAppear {
            calculateScores()
        }
        .onChange(of: options.count) { _, _ in
            calculateScores()
        }
        .onChange(of: criteria.count) { _, _ in
            calculateScores()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            // Recalculate scores when ratings change
            calculateScores()
        }
    }
    
    private func calculateScores() {
        let ratingRepository = RatingRepository()
        let maxWeight = max(criteria.map { $0.weight }.max() ?? 1, 1)
        
        var scores: [String: Double] = [:]
        
        for option in options {
            var ratingsDict: [String: Int16] = [:]
            var weightsDict: [String: Int16] = [:]
            
            for criterion in criteria {
                weightsDict[criterion.objectID.uriRepresentation().absoluteString] = criterion.weight
                
                do {
                    if let rating = try ratingRepository.fetch(for: option, criterion: criterion, userID: nil) {
                        ratingsDict[criterion.objectID.uriRepresentation().absoluteString] = rating.ratingValue
                    }
                } catch {
                    // Ignore errors
                }
            }
            
            let score = ScoreCalculator.weightedScore(
                ratings: ratingsDict,
                criterionWeights: weightsDict,
                maxWeight: maxWeight
            )
            
            scores[option.objectID.uriRepresentation().absoluteString] = score
        }
        
        optionScores = scores
    }
}

#Preview {
    NavigationStack {
        RatingsView(viewModel: DecisionDetailViewModel(decision: Decision(context: DataStore.preview.container.viewContext)))
    }
}

