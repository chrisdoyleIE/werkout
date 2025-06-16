import Foundation
import os

struct Logger {
    private static let subsystem = "com.chrisdoyle.werkowt"
    
    static let general = OSLog(subsystem: subsystem, category: "general")
    static let workout = OSLog(subsystem: subsystem, category: "workout")
    static let auth = OSLog(subsystem: subsystem, category: "auth")
    static let data = OSLog(subsystem: subsystem, category: "data")
    
    static func log(_ message: String, category: OSLog = general, type: OSLogType = .default) {
        os_log("%@", log: category, type: type, message)
    }
    
    static func error(_ message: String, category: OSLog = general) {
        os_log("%@", log: category, type: .error, message)
    }
    
    static func debug(_ message: String, category: OSLog = general) {
        #if DEBUG
        os_log("%@", log: category, type: .debug, message)
        #endif
    }
}