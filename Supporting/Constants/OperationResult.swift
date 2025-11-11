import Foundation

enum OperationResult<T> {
    case success(T)
    case failure(AppError)
}

// Extension to handle void results
extension OperationResult where T == Void {
    static var success: OperationResult<Void> {
        .success(())
    }
}

