import SwiftUI
import CloudKit

struct ShareDecisionView: View {
    @ObservedObject var viewModel: DecisionDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = false
    @State private var shareRecordID: String?
    @State private var participants: [DecisionShare] = []
    @State private var errorMessage: String?
    @State private var showingCloudSharingController = false
    @State private var cloudSharingController: UICloudSharingController?
    
    private let shareService: ShareServiceProtocol
    
    init(viewModel: DecisionDetailViewModel, shareService: ShareServiceProtocol = ShareService()) {
        self.viewModel = viewModel
        self.shareService = shareService
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.decision.title ?? "Decision")
                            .font(.headline)
                        if let desc = viewModel.decision.desc, !desc.isEmpty {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Decision")
                }
                
                Section {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Setting up sharing...")
                                .foregroundColor(.secondary)
                        }
                    } else if shareRecordID != nil {
                        Button(action: {
                            showCloudSharingController()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share with Others")
                            }
                        }
                        
                        if !participants.isEmpty {
                            ForEach(participants, id: \.objectID) { participant in
                                ParticipantRow(participant: participant)
                            }
                        }
                    } else {
                        Button(action: createShare) {
                            HStack {
                                Image(systemName: "person.2.badge.plus")
                                Text("Start Sharing")
                            }
                        }
                    }
                } header: {
                    Text("Sharing")
                } footer: {
                    if shareRecordID == nil {
                        Text("Share this decision with others so they can add ratings and collaborate.")
                    } else {
                        Text("Tap 'Share with Others' to invite more people or manage participants.")
                    }
                }
                
                if shareRecordID != nil {
                    Section {
                        Button(role: .destructive, action: removeShare) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Stop Sharing")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Share Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCloudSharingController) {
                if let controller = cloudSharingController {
                    CloudSharingViewControllerRepresentable(controller: controller)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                loadShareInfo()
            }
        }
    }
    
    private func createShare() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let share = try await shareService.shareDecision(viewModel.decision)
                
                await MainActor.run {
                    shareRecordID = share.recordID.recordName
                    isLoading = false
                    loadShareInfo()
                    HapticManager.notification(type: .success)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create share: \(error.localizedDescription)"
                    Logger.shared.log("Error creating share: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }
    
    private func removeShare() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await shareService.removeShare(for: viewModel.decision)
                await MainActor.run {
                    shareRecordID = nil
                    participants = []
                    isLoading = false
                    HapticManager.notification(type: .success)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to remove share: \(error.localizedDescription)"
                    Logger.shared.log("Error removing share: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }
    
    private func loadShareInfo() {
        if let shareID = viewModel.decision.shareRecordID {
            shareRecordID = shareID
            Task {
                do {
                    let shares = try await shareService.fetchShares(for: viewModel.decision)
                    await MainActor.run {
                        participants = shares
                    }
                } catch {
                    Logger.shared.log("Error loading share info: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }
    
    private func showCloudSharingController() {
        guard let shareRecordID = shareRecordID else {
            errorMessage = "Share record not available"
            return
        }
        
        let recordID = CKRecord.ID(recordName: shareRecordID)
        let container = CKContainer(identifier: AppConstants.cloudKitContainerIdentifier)
        let database = container.privateCloudDatabase
        
        Task {
            do {
                let share = try await database.record(for: recordID) as? CKShare
                
                await MainActor.run {
                    if let share = share {
                        let controller = UICloudSharingController { controller, completionHandler in
                            // Prepare share for sharing - completion handler expects container, not database
                            completionHandler(share, container, nil)
                        }
                        
                        controller.delegate = CloudSharingDelegate()
                        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
                        cloudSharingController = controller
                        showingCloudSharingController = true
                    } else {
                        errorMessage = "Could not load share"
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load share: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ParticipantRow: View {
    let participant: DecisionShare
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.email ?? participant.userRecordID ?? "Unknown")
                    .font(.subheadline)
                
                if let status = participant.status {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(statusColor(for: status))
                }
            }
            
            Spacer()
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "accepted":
            return .green
        case "pending":
            return .orange
        case "declined":
            return .red
        default:
            return .secondary
        }
    }
}

struct CloudSharingViewControllerRepresentable: UIViewControllerRepresentable {
    let controller: UICloudSharingController
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
}

class CloudSharingDelegate: NSObject, UICloudSharingControllerDelegate {
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        Logger.shared.log("Failed to save share: \(error.localizedDescription)", level: .error)
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return nil
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return "Decision"
    }
    
    func itemType(for csc: UICloudSharingController) -> String? {
        return "Decision"
    }
}

#Preview {
    ShareDecisionView(viewModel: DecisionDetailViewModel(decision: Decision(context: DataStore.preview.container.viewContext)))
}

