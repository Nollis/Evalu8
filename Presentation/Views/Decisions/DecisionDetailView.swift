import SwiftUI
import CoreData

struct DecisionDetailView: View {
    @StateObject private var viewModel: DecisionDetailViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    init(decision: Decision) {
        _viewModel = StateObject(wrappedValue: DecisionDetailViewModel(decision: decision))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Decision Info Section
                VStack(alignment: .leading, spacing: 12) {
                    if let desc = viewModel.decision.desc, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Scale: \(viewModel.decision.scoringScale)", systemImage: "star.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let dateCreated = viewModel.decision.dateCreated {
                            Text("Created \(dateCreated, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Options Section
                SectionHeader(
                    title: "Options",
                    count: viewModel.options.count,
                    action: { viewModel.showingAddOption = true }
                )
                
                if viewModel.options.isEmpty {
                    EmptySectionView(
                        message: "No options yet",
                        actionTitle: "Add Option",
                        action: { viewModel.showingAddOption = true }
                    )
                } else {
                    ForEach(viewModel.options) { option in
                        OptionRow(
                            option: option,
                            onTap: { viewModel.selectedOption = option },
                            onDelete: { viewModel.deleteOption(option) }
                        )
                    }
                }
                
                // Criteria Section
                SectionHeader(
                    title: "Criteria",
                    count: viewModel.criteria.count,
                    action: { viewModel.showingAddCriterion = true }
                )
                
                if viewModel.criteria.isEmpty {
                    EmptySectionView(
                        message: "No criteria yet",
                        actionTitle: "Add Criterion",
                        action: { viewModel.showingAddCriterion = true }
                    )
                } else {
                    ForEach(viewModel.criteria) { criterion in
                        CriterionRow(
                            criterion: criterion,
                            onTap: { viewModel.selectedCriterion = criterion },
                            onDelete: { viewModel.deleteCriterion(criterion) }
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.decision.title ?? "Decision")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showingShare = true
                } label: {
                    Image(systemName: "person.2")
                }
                
                if !viewModel.options.isEmpty && !viewModel.criteria.isEmpty {
                    Button {
                        viewModel.showingCharts = true
                    } label: {
                        Image(systemName: "chart.bar")
                    }
                    
                    Button {
                        viewModel.showingRatings = true
                    } label: {
                        Image(systemName: "star")
                    }
                }
                
                Button("Edit") {
                    viewModel.showingEditDecision = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddOption) {
            AddOptionView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddCriterion) {
            AddCriterionView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingEditDecision) {
            EditDecisionView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingRatings) {
            NavigationStack {
                RatingsView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showingCharts) {
            NavigationStack {
                DecisionChartsView(decision: viewModel.decision)
            }
        }
        .sheet(isPresented: $viewModel.showingShare) {
            ShareDecisionView(viewModel: viewModel)
        }
        .sheet(item: $viewModel.selectedOption) { option in
            OptionDetailView(option: option)
        }
        .sheet(item: $viewModel.selectedCriterion) { criterion in
            CriterionDetailView(criterion: criterion)
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
    }
}

struct SectionHeader: View {
    let title: String
    let count: Int
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primaryText)
                
                Text("\(count) \(count == 1 ? "item" : "items")")
                    .font(.subheadline)
                    .foregroundColor(Color.secondaryText)
            }
            
            Spacer()
            
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.primaryGradientStart.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
    }
}

struct OptionRow: View {
    let option: Option
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Image or icon
            if let imageURLString = option.imageURL,
               !imageURLString.isEmpty,
               imageURLString != "null",
               let url = URL(string: imageURLString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(let error):
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                            .onAppear {
                                Logger.shared.log("Failed to load image from \(imageURLString): \(error.localizedDescription)", level: .error)
                            }
                    @unknown default:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.primaryGradientStart)
                    .frame(width: 50, height: 50)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(option.name ?? "Unnamed Option")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText)
                    
                    Spacer()
                    
                    if option.internetRating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", option.internetRating))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.primaryText)
                        }
                    }
                }
                
                if let description = option.desc, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                        .lineLimit(2)
                }
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.7))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardBorder.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct CriterionRow: View {
    let criterion: Criterion
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primaryGradientStart.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Text("\(criterion.weight)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.primaryGradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(criterion.name ?? "Unnamed Criterion")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText)
                
                if let description = criterion.desc, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                        .lineLimit(2)
                } else {
                    Text("Weight: \(criterion.weight)")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.7))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardBorder.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct EmptySectionView: View {
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 40))
                .foregroundStyle(Color.secondaryGradientStart.opacity(0.6))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.secondaryText)
            
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text(actionTitle)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.primaryGradient)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primaryGradientStart.opacity(0.1))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(Color.cardBorder.opacity(0.3))
                )
        )
    }
}

struct OptionDetailView: View {
    let option: Option
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    if let imageURLString = option.imageURL,
                       !imageURLString.isEmpty,
                       imageURLString != "null",
                       let url = URL(string: imageURLString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                            case .failure(let error):
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    Text("Failed to load image")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .onAppear {
                                    Logger.shared.log("Failed to load image from \(imageURLString): \(error.localizedDescription)", level: .error)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cardBorder.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Name and Rating
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(option.name ?? "Unnamed Option")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.primaryText)
                            
                            Spacer()
                            
                            if option.internetRating > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.title3)
                                    Text(String(format: "%.1f", option.internetRating))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.primaryText)
                                }
                            }
                        }
                        
                        // Description
                        if let description = option.desc, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(Color.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cardBorder.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding()
            }
            .navigationTitle("Option Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CriterionDetailView: View {
    let criterion: Criterion
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Weight Badge
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primaryGradientStart.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            VStack(spacing: 4) {
                                Text("\(criterion.weight)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Color.primaryGradient)
                                Text("Weight")
                                    .font(.caption)
                                    .foregroundColor(Color.secondaryText)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Name and Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text(criterion.name ?? "Unnamed Criterion")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.primaryText)
                        
                        // Description
                        if let description = criterion.desc, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(Color.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("No description available")
                                .font(.body)
                                .foregroundColor(Color.secondaryText.opacity(0.6))
                                .italic()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cardBorder.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding()
            }
            .navigationTitle("Criterion Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DecisionDetailView(decision: DataStore.preview.container.viewContext.registeredObjects.first { $0 is Decision } as! Decision)
    }
    .environment(\.managedObjectContext, DataStore.preview.container.viewContext)
}

