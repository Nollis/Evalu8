import Foundation
import CloudKit
import CoreData

protocol ShareServiceProtocol {
    func shareDecision(_ decision: Decision) async throws -> CKShare
    func acceptShare(metadata: CKShare.Metadata) async throws
    func removeShare(for decision: Decision) async throws
    func fetchShares(for decision: Decision) async throws -> [DecisionShare]
}

class ShareService: ShareServiceProtocol {
    private let cloudKitService: CloudKitServiceProtocol
    private let dataStore: DataStore
    
    init(
        cloudKitService: CloudKitServiceProtocol = CloudKitService(),
        dataStore: DataStore = DataStore.shared
    ) {
        self.cloudKitService = cloudKitService
        self.dataStore = dataStore
    }
    
    func shareDecision(_ decision: Decision) async throws -> CKShare {
        // Check CloudKit account status
        let accountStatus = try await cloudKitService.checkAccountStatus()
        guard accountStatus == .available else {
            throw ShareError.noICloudAccount
        }
        
        // Get the CloudKit record for this decision
        guard let recordIDString = decision.rootRecordID,
              let recordID = CKRecord.ID(recordName: recordIDString) else {
            // If no record ID exists, we need to create one
            // This would typically be handled by Core Data + CloudKit sync
            throw ShareError.notShared
        }
        
        // Fetch the record
        let container = CKContainer(identifier: AppConstants.cloudKitContainerIdentifier)
        let database = container.privateCloudDatabase
        
        do {
            let record = try await database.record(for: recordID)
            
            // Create or fetch existing share
            let share: CKShare
            if let existingShareRecordID = decision.shareRecordID,
               let shareID = CKRecord.ID(recordName: existingShareRecordID) {
                // Try to fetch existing share
                share = try await database.record(for: shareID) as? CKShare ?? CKShare(rootRecord: record)
            } else {
                // Create new share
                share = CKShare(rootRecord: record)
                share[CKShare.SystemFieldKey.title] = decision.title ?? "Decision"
            }
            
            // Save the share
            let operation = CKModifyRecordsOperation(recordsToSave: [share], recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated
            
            return try await withCheckedThrowingContinuation { continuation in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        // Update decision with share record ID
                        decision.shareRecordID = share.recordID.recordName
                        do {
                            try self.dataStore.saveContext()
                            continuation.resume(returning: share)
                        } catch {
                            continuation.resume(throwing: ShareError.sharingFailed(error))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: ShareError.sharingFailed(error))
                    }
                }
                
                database.add(operation)
            }
        } catch {
            Logger.shared.log("Error sharing decision: \(error.localizedDescription)", level: .error)
            if let ckError = error as? CKError {
                switch ckError.code {
                case .notAuthenticated:
                    throw ShareError.notAuthenticated
                case .networkUnavailable, .networkFailure:
                    throw ShareError.networkError
                default:
                    throw ShareError.sharingFailed(error)
                }
            }
            throw ShareError.sharingFailed(error)
        }
    }
    
    func acceptShare(metadata: CKShare.Metadata) async throws {
        let container = CKContainer(identifier: AppConstants.cloudKitContainerIdentifier)
        let acceptOperation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        
        return try await withCheckedThrowingContinuation { continuation in
            acceptOperation.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    Logger.shared.log("Successfully accepted share", level: .info)
                    continuation.resume()
                case .failure(let error):
                    Logger.shared.log("Error accepting share: \(error.localizedDescription)", level: .error)
                    continuation.resume(throwing: ShareError.sharingFailed(error))
                }
            }
            
            container.add(acceptOperation)
        }
    }
    
    func removeShare(for decision: Decision) async throws {
        guard let shareRecordIDString = decision.shareRecordID,
              let shareRecordID = CKRecord.ID(recordName: shareRecordIDString) else {
            throw ShareError.notShared
        }
        
        let container = CKContainer(identifier: AppConstants.cloudKitContainerIdentifier)
        let database = container.privateCloudDatabase
        
        do {
            try await database.deleteRecord(withID: shareRecordID)
            decision.shareRecordID = nil
            try dataStore.saveContext()
            Logger.shared.log("Successfully removed share for decision: \(decision.title ?? "Unknown")", level: .info)
        } catch {
            Logger.shared.log("Error removing share: \(error.localizedDescription)", level: .error)
            throw ShareError.sharingFailed(error)
        }
    }
    
    func fetchShares(for decision: Decision) async throws -> [DecisionShare] {
        guard let shares = decision.shares as? Set<DecisionShare> else {
            return []
        }
        return Array(shares)
    }
}

