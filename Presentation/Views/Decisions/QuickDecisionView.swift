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
                // Header
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
                            .foregroundColor(.primaryText)
                        
                        Text("Describe what you're deciding on, and we'll set it up for you")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
                
                // Input Section
                VStack(spacing: 16) {
                    // Text Input
                    TextField("e.g., I'm planning on buying a putter. Can you give me some choices?", text: $queryText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .disabled(isGenerating || speechRecognizer.isListening)
                        .focused($isTextFieldFocused)
                    
                    // Voice Input Button
                    HStack {
                        Button(action: toggleVoiceInput) {
                            HStack(spacing: 8) {
                                Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                                    .font(.system(size: 18, weight: .semibold))
                                Text(speechRecognizer.isListening ? "Listening..." : "Use Voice")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(speechRecognizer.isListening ? Color.red.gradient : Color.secondaryGradient)
                            )
                            .shadow(color: (speechRecognizer.isListening ? Color.red : Color.secondaryGradientStart).opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .disabled(isGenerating)
                    }
                    
                    // Transcript display
                    if !speechRecognizer.transcript.isEmpty {
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
                    
                    // Error message
                    if let error = speechRecognizer.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                // Generate Button
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
                            .fill(canGenerate ? Color.primaryGradient : LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .shadow(color: canGenerate ? Color.primaryGradientStart.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .disabled(!canGenerate || isGenerating)
                .padding(.horizontal)
                
                // Preview Section
                if let setup = generatedSetup {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title: \(setup.title)")
                                .font(.subheadline)
                            
                            if let desc = setup.description {
                                Text("Description: \(desc)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Options: \(setup.options.count)")
                                .font(.caption)
                            
                            Text("Criteria: \(setup.criteria.count)")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Button(action: createDecision) {
                            Text("Create Decision")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
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
                    // Dismiss keyboard when transcript is set after voice input completes
                    isTextFieldFocused = false
                }
            }
        }
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

