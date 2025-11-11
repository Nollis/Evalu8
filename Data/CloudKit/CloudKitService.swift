import Foundation
import CloudKit
import CoreData

protocol CloudKitServiceProtocol {
    func checkAccountStatus() async throws -> CKAccountStatus
    func fetchUserRecordID() async throws -> CKRecord.ID?
    func fetchShareMetadata(for recordID: CKRecord.ID) async throws -> CKShare.Metadata?
}

class CloudKitService: CloudKitServiceProtocol {
    private let container: CKContainer
    
    init(containerIdentifier: String = AppConstants.cloudKitContainerIdentifier) {
        self.container = CKContainer(identifier: containerIdentifier)
    }
    
    func checkAccountStatus() async throws -> CKAccountStatus {
        if DevelopmentConfig.bypassCloudKit {
            Logger.shared.log("Bypassing CloudKit account check", level: .info)
            return .available
        }
        
        do {
            let status = try await container.accountStatus()
            Logger.shared.log("CloudKit account status: \(status)", level: .info)
            return status
        } catch {
            Logger.shared.log("Error checking CloudKit account status: \(error.localizedDescription)", level: .error)
            throw ShareError.notAuthenticated
        }
    }
    
    func fetchUserRecordID() async throws -> CKRecord.ID? {
        if DevelopmentConfig.bypassCloudKit {
            Logger.shared.log("Bypassing CloudKit user record fetch", level: .info)
            return nil
        }
        
        do {
            let userRecordID = try await container.userRecordID()
            Logger.shared.log("Fetched user record ID: \(userRecordID.recordName)", level: .info)
            return userRecordID
        } catch {
            Logger.shared.log("Error fetching user record ID: \(error.localizedDescription)", level: .error)
            throw ShareError.notAuthenticated
        }
    }
    
    func fetchShareMetadata(for recordID: CKRecord.ID) async throws -> CKShare.Metadata? {
        if DevelopmentConfig.bypassCloudKit {
            Logger.shared.log("Bypassing CloudKit share metadata fetch", level: .info)
            return nil
        }
        
        do {
            let shareMetadata = try await container.shareMetadata(for: recordID)
            Logger.shared.log("Fetched share metadata for record: \(recordID.recordName)", level: .info)
            return shareMetadata
        } catch {
            Logger.shared.log("Error fetching share metadata: \(error.localizedDescription)", level: .error)
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
}

