import Foundation
import os.log

enum LogLevel: String {
    case debug
    case info
    case warning
    case error
}

class Logger {
    static let shared = Logger()
    private let logger: os.Logger
    
    private init() {
        let subsystem = Bundle.main.bundleIdentifier ?? "com.nollis.evalu8"
        logger = os.Logger(subsystem: subsystem, category: "general")
    }
    
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        let log = "[\(level.rawValue.uppercased())] [\(filename):\(line)] \(function) - \(message)"
        
        switch level {
        case .debug:
            logger.debug("\(log)")
        case .info:
            logger.info("\(log)")
        case .warning:
            logger.warning("\(log)")
        case .error:
            logger.error("\(log)")
        }
        #endif
    }
}

