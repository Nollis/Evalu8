import SwiftUI
import Speech

struct QuickDecisionView: View {
    @ObservedObject var viewModel: DecisionListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var queryText = ""
    @State private var isGenerating = false
    @State private var generatedSetup: QuickDecisionSetup?
    @State private var showingPreview = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    inputSection
                    generateButton
                    if let setup = generatedSetup {
                        previewSection(setup: setup)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Quick Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        speechRecognizer.stopListening()
                        dismiss()
                    }
                }
            }
            .onChange(of: speechRecognizer.transcript) { _, newValue in
                if !newValue.isEmpty && !speechRecognizer.isListening {
                    queryText = newValue
                    isTextFieldFocused = false
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.primaryGradientStart.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.primaryGradient)
            }
            
            VStack(spacing: 6) {
                Text("Quick Decision")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primaryText)
                
                Text("Describe what you're deciding on, and we'll set it up for you")
                    .font(.subheadline)
                    .foregroundColor(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top)
    }
    
    private var inputSection: some View {
        VStack(spacing: 16) {
            TextField("e.g., I'm planning on buying a putter. Can you give me some choices?", text: $queryText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .disabled(isGenerating || speechRecognizer.isListening)
                .focused($isTextFieldFocused)
            
            voiceInputButton
            
            if !speechRecognizer.transcript.isEmpty {
                transcriptView
            }
            
            if let error = speechRecognizer.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var voiceInputButton: some View {
        if speechRecognizer.isListening {
            Button(action: toggleVoiceInput) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Listening...")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.gradient)
                )
                .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .disabled(isGenerating)
        } else {
            Button(action: toggleVoiceInput) {
                HStack(spacing: 8) {
                    Image(systemName: "mic")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Use Voice")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondaryGradient)
                )
                .shadow(color: Color.secondaryGradientStart.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .disabled(isGenerating)
        }
    }
    
    private var transcriptView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("You said:")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(speechRecognizer.transcript)
                .font(.body)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var generateButton: some View {
        if canGenerate {
            Button(action: generateDecision) {
                HStack(spacing: 10) {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(isGenerating ? "Generating..." : "Generate Decision")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primaryGradient)
                )
                .shadow(color: Color.primaryGradientStart.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .disabled(isGenerating)
            .padding(.horizontal)
        } else {
            Button(action: generateDecision) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Generate Decision")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            }
            .disabled(true)
            .padding(.horizontal)
        }
    }
    
    private func previewSection(setup: QuickDecisionSetup) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(Color.primaryText)
            
            // Decision Info
            VStack(alignment: .leading, spacing: 8) {
                Text(setup.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText)
                
                if let desc = setup.description {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(Color.secondaryText)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            
            // Options Preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Options (\(setup.options.count))")
                    .font(.headline)
                    .foregroundColor(Color.primaryText)
                
                ForEach(Array(setup.options.enumerated()), id: \.offset) { index, option in
                    optionPreviewCard(option: option)
                }
            }
            
            // Criteria Preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Criteria (\(setup.criteria.count))")
                    .font(.headline)
                    .foregroundColor(Color.primaryText)
                
                ForEach(Array(setup.criteria.enumerated()), id: \.offset) { index, criterion in
                    criterionPreviewCard(criterion: criterion)
                }
            }
            
            Button(action: createDecision) {
                Text("Create Decision")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryGradient)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .cornerRadius(12)
                    .shadow(color: Color.primaryGradientStart.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func optionPreviewCard(option: QuickDecisionSetup.OptionSetup) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Image
            if let imageURLString = option.imageURL,
               !imageURLString.isEmpty,
               imageURLString != "null",
               let url = URL(string: imageURLString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(let error):
                        VStack {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                            Text("Failed")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        .frame(width: 60, height: 60)
                        .onAppear {
                            Logger.shared.log("Failed to load image from \(imageURLString): \(error.localizedDescription)", level: .error)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(option.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText)
                    
                    Spacer()
                    
                    if let rating = option.internetRating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.primaryText)
                        }
                    }
                }
                
                if let description = option.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func criterionPreviewCard(criterion: QuickDecisionSetup.CriterionSetup) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(criterion.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText)
                
                Spacer()
                
                Text("Weight: \(criterion.weight)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryGradientStart.opacity(0.2))
                    .foregroundColor(Color.primaryText)
                    .cornerRadius(6)
            }
            
            if let description = criterion.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.secondaryText)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }
    
    private var canGenerate: Bool {
        !queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func toggleVoiceInput() {
        if speechRecognizer.isListening {
            speechRecognizer.stopListening()
            // Dismiss keyboard when stopping voice input
            isTextFieldFocused = false
            // Use the transcript as the query text
            if !speechRecognizer.transcript.isEmpty {
                queryText = speechRecognizer.transcript
            }
        } else {
            // Dismiss keyboard when starting voice input
            isTextFieldFocused = false
            speechRecognizer.startListening()
        }
    }
    
    private func generateDecision() {
        guard !queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Dismiss keyboard
        isTextFieldFocused = false
        
        isGenerating = true
        generatedSetup = nil
        
        Task {
            do {
                let setup = try await AIService.shared.generateQuickDecision(from: queryText)
                await MainActor.run {
                    generatedSetup = setup
                    isGenerating = false
                    HapticManager.notification(type: .success)
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    viewModel.errorMessage = "Failed to generate decision: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func createDecision() {
        guard let setup = generatedSetup else { return }
        
        viewModel.createQuickDecision(setup: setup)
        speechRecognizer.stopListening()
        dismiss()
    }
}

#Preview {
    QuickDecisionView(viewModel: DecisionListViewModel())
}

