import SwiftUI
import CoreData

struct RatingsView: View {
    @ObservedObject var viewModel: DecisionDetailViewModel
    @State private var selectedOption: Option?
    @State private var showingRatingSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate each option against all criteria")
                        .font(.headline)
                    Text("Tap on any cell to rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Ratings Matrix
                if !viewModel.options.isEmpty && !viewModel.criteria.isEmpty {
                    VStack(spacing: 12) {
                        // Header row with criteria
                        HStack(spacing: 0) {
                            Text("Option")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(width: 100, alignment: .leading)
                                .padding(.horizontal, 8)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.criteria) { criterion in
                                        Text(criterion.name ?? "Unknown")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .frame(width: 80)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        
                        // Option rows
                        ForEach(viewModel.options) { option in
                            RatingRowView(
                                option: option,
                                criteria: viewModel.criteria,
                                decision: viewModel.decision,
                                onRatingTap: { tappedOption, criterion in
                                    selectedOption = tappedOption
                                    showingRatingSheet = true
                                }
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Add options and criteria to start rating")
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
        .sheet(isPresented: $showingRatingSheet) {
            if let option = selectedOption {
                RatingSheetView(
                    option: option,
                    criteria: viewModel.criteria,
                    decision: viewModel.decision,
                    viewModel: viewModel
                )
            }
        }
    }
}

struct RatingRowView: View {
    let option: Option
    let criteria: [Criterion]
    let decision: Decision
    let onRatingTap: (Option, Criterion) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Option name
            Text(option.name ?? "Unknown")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)
                .padding(.horizontal, 8)
            
            // Ratings for each criterion
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(criteria) { criterion in
                        RatingCellView(
                            option: option,
                            criterion: criterion
                        ) {
                            onRatingTap(option, criterion)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct RatingCellView: View {
    let option: Option
    let criterion: Criterion
    let onTap: () -> Void
    
    @State private var currentRating: Int16 = 0
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                StarRatingView(
                    rating: currentRating,
                    maxRating: option.decision?.scoringScale ?? 5,
                    interactive: false
                )
                Text(currentRating == 0 ? "-" : "\(currentRating)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onAppear {
            loadRating()
        }
        .onChange(of: option.objectID) { _, _ in
            loadRating()
        }
        .onChange(of: criterion.objectID) { _, _ in
            loadRating()
        }
    }
    
    private func loadRating() {
        let ratingRepository = RatingRepository()
        do {
            if let rating = try ratingRepository.fetch(for: option, criterion: criterion, userID: nil) {
                currentRating = rating.ratingValue
            } else {
                currentRating = 0
            }
        } catch {
            currentRating = 0
        }
    }
}

struct RatingSheetView: View {
    let option: Option
    let criteria: [Criterion]
    let decision: Decision
    @ObservedObject var viewModel: DecisionDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var ratings: [String: Int16] = [:]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(option.name ?? "Unknown Option")
                        .font(.headline)
                }
                
                Section("Rate against criteria") {
                    ForEach(criteria) { criterion in
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
                                    maxRating: decision.scoringScale,
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
        let ratingRepository = RatingRepository()
        for criterion in criteria {
            do {
                if let rating = try ratingRepository.fetch(for: option, criterion: criterion, userID: nil) {
                    ratings[criterion.objectID.uriRepresentation().absoluteString] = rating.ratingValue
                } else {
                    ratings[criterion.objectID.uriRepresentation().absoluteString] = 0
                }
            } catch {
                ratings[criterion.objectID.uriRepresentation().absoluteString] = 0
            }
        }
    }
    
    private func saveRating(for criterion: Criterion, value: Int16) {
        let ratingRepository = RatingRepository()
        do {
            _ = try ratingRepository.createOrUpdate(
                option: option,
                criterion: criterion,
                ratingValue: value,
                userID: nil,
                userDisplayName: nil
            )
            HapticManager.selection()
        } catch {
            viewModel.errorMessage = "Failed to save rating: \(error.localizedDescription)"
        }
    }
}

struct ScoresSummaryView: View {
    let options: [Option]
    let criteria: [Criterion]
    let decision: Decision
    
    @State private var optionScores: [String: Double] = [:]
    
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
    }
    
    private func calculateScores() {
        let ratingRepository = RatingRepository()
        let maxWeight = criteria.map { $0.weight }.max() ?? 1
        
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

