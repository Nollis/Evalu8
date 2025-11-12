import SwiftUI
import Charts

struct DecisionChartsView: View {
    let decision: Decision
    @State private var chartData: [ChartDataPoint] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    ProgressView("Loading chart data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if chartData.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Rate options to see charts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    // Overall Scores Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overall Scores")
                            .font(.headline)
                        
                        Chart(chartData) { dataPoint in
                            BarMark(
                                x: .value("Option", dataPoint.optionName),
                                y: .value("Score", dataPoint.score)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                        .frame(height: 300)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel {
                                    if let stringValue = value.as(String.self) {
                                        Text(stringValue)
                                            .rotationEffect(.degrees(-45))
                                            .frame(width: 80, alignment: .leading)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Scores by Criterion Chart
                    if let options = decision.options?.allObjects as? [Option],
                       let criteria = decision.criteria?.allObjects as? [Criterion],
                       !options.isEmpty && !criteria.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scores by Criterion")
                                .font(.headline)
                            
                            Chart {
                                ForEach(criteria, id: \.objectID) { criterion in
                                    ForEach(options, id: \.objectID) { option in
                                        if let score = getScore(for: option, criterion: criterion) {
                                            BarMark(
                                                x: .value("Criterion", criterion.name ?? "Unknown"),
                                                y: .value("Score", score),
                                                stacking: .normalized
                                            )
                                            .foregroundStyle(by: .value("Option", option.name ?? "Unknown"))
                                        }
                                    }
                                }
                            }
                            .frame(height: 300)
                            .chartXAxis {
                                AxisMarks(values: .automatic) { value in
                                    AxisValueLabel {
                                        if let stringValue = value.as(String.self) {
                                            Text(stringValue)
                                                .rotationEffect(.degrees(-45))
                                                .frame(width: 80, alignment: .leading)
                                        }
                                    }
                                }
                            }
                            .chartLegend(position: .bottom)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadChartData()
        }
    }
    
    private func loadChartData() {
        isLoading = true
        
        guard let options = decision.options?.allObjects as? [Option],
              let criteria = decision.criteria?.allObjects as? [Criterion] else {
            isLoading = false
            return
        }
        
        let ratingRepository = RatingRepository()
        let maxWeight = max(criteria.map { $0.weight }.max() ?? 1, 1)
        
        var dataPoints: [ChartDataPoint] = []
        
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
            
            // Only add valid scores (not NaN or Infinity)
            guard score.isFinite else {
                continue
            }
            
            dataPoints.append(ChartDataPoint(
                optionName: option.name ?? "Unknown",
                score: score
            ))
        }
        
        chartData = dataPoints.sorted { $0.score > $1.score }
        isLoading = false
    }
    
    private func getScore(for option: Option, criterion: Criterion) -> Double? {
        let ratingRepository = RatingRepository()
        do {
            if let rating = try ratingRepository.fetch(for: option, criterion: criterion, userID: nil) {
                let maxWeight = max((decision.criteria?.allObjects as? [Criterion])?.map { $0.weight }.max() ?? 1, 1)
                let score = ScoreCalculator.normalizedScore(
                    ratingValue: rating.ratingValue,
                    criterionWeight: criterion.weight,
                    maxWeight: maxWeight
                )
                // Only return valid scores (not NaN or Infinity)
                guard score.isFinite else {
                    return nil
                }
                return score
            }
        } catch {
            // Ignore errors
        }
        return nil
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let optionName: String
    let score: Double
}

#Preview {
    NavigationStack {
        DecisionChartsView(decision: Decision(context: DataStore.preview.container.viewContext))
    }
}

