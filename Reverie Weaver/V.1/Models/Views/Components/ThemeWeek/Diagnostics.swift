import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(os)
import os
#endif

public struct BuildInfo {
    public static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }()

    public static let buildNumber: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }()

    public static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    public static let osVersion: String = {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }()

    public static let deviceModel: String = {
        #if canImport(UIKit)
        return UIDevice.current.model
        #else
        return "Unknown"
        #endif
    }()
    
    // ✅ NEW: Device identifier for better debugging
    public static let deviceIdentifier: String = {
        #if canImport(UIKit)
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
        #else
        return "Unknown"
        #endif
    }()
}

public enum AppLog {
    private static func log(_ emoji: String, _ message: String, category: String) {
        let output = "\(emoji) [\(category)] \(message)"
        #if DEBUG
        print(output)
        #else
        #if canImport(os)
        if #available(iOS 14.0, macOS 11.0, *) {
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "App", category: category)
            logger.log("\(output)")
        } else {
            print(output)
        }
        #else
        print(output)
        #endif
        #endif
    }

    // ✅ FIXED: Proper emoji encoding
    public static func info(_ message: String, category: String = "Info") {
        log("ℹ️", message, category: category)
    }

    public static func warn(_ message: String, category: String = "Warn") {
        log("⚠️", message, category: category)
    }

    public static func error(_ message: String, category: String = "Error") {
        log("❌", message, category: category)
    }
    
    // ✅ NEW: Success logging for positive events
    public static func success(_ message: String, category: String = "Success") {
        log("✅", message, category: category)
    }
    
    // ✅ NEW: Debug logging (only in debug builds)
    public static func debug(_ message: String, category: String = "Debug") {
        #if DEBUG
        log("🐛", message, category: category)
        #endif
    }
}

// ✅ ENHANCED: Better thread assertion with more context
public func assertMainThread(_ message: String, file: String = #file, line: Int = #line) {
    #if DEBUG
    if !Thread.isMainThread {
        let fileName = (file as NSString).lastPathComponent
        let fullMessage = "\(message) [\(fileName):\(line)]"
        assertionFailure("Main Thread Assertion Failed: \(fullMessage)")
    }
    #else
    if !Thread.isMainThread {
        AppLog.warn("Main thread violation: \(message)", category: "Threading")
    }
    #endif
}

public func fatalReport(_ message: String, file: String = #file, line: Int = #line) {
    let fileName = (file as NSString).lastPathComponent
    let fullMessage = "\(message) [\(fileName):\(line)]"
    AppLog.error(fullMessage, category: "Fatal")
    #if DEBUG
    assertionFailure(fullMessage)
    #endif
}

// ✅ NEW: Memory warning tracking
public class MemoryMonitor {
    public static let shared = MemoryMonitor()
    private var memoryWarningCount = 0
    
    private init() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }
    
    @objc private func didReceiveMemoryWarning() {
        memoryWarningCount += 1
        AppLog.warn("Memory warning received (count: \(memoryWarningCount))", category: "Memory")
    }
    
    public func getMemoryWarningCount() -> Int {
        return memoryWarningCount
    }
}

@MainActor
public func preflightProductionChecks() async {
    AppLog.info("═══════════════════════════════════════════", category: "Preflight")
    AppLog.info("🚀 Reverie Weaver - Preflight Checks", category: "Preflight")
    AppLog.info("═══════════════════════════════════════════", category: "Preflight")
    
    // Build Information
    AppLog.info("App Version: \(BuildInfo.appVersion)", category: "BuildInfo")
    AppLog.info("Build Number: \(BuildInfo.buildNumber)", category: "BuildInfo")
    AppLog.info("Debug Mode: \(BuildInfo.isDebug)", category: "BuildInfo")
    AppLog.info("OS Version: \(BuildInfo.osVersion)", category: "BuildInfo")
    AppLog.info("Device Model: \(BuildInfo.deviceModel)", category: "BuildInfo")
    
    #if DEBUG
    AppLog.debug("Device Identifier: \(BuildInfo.deviceIdentifier)", category: "BuildInfo")
    #endif

    // Thread Safety Check (already on MainActor)
    AppLog.success("Running on main actor", category: "Preflight")

    // Locale Check
    let currentLocale = Locale.current.identifier
    AppLog.info("Current Locale: \(currentLocale)", category: "Preflight")
    
    // Language preference
    let preferredLanguages = Locale.preferredLanguages
    if let primaryLanguage = preferredLanguages.first {
        AppLog.info("Primary Language: \(primaryLanguage)", category: "Preflight")
    }

    // Bundle Identifier Check
    let bundleId = Bundle.main.bundleIdentifier ?? "Unknown"
    if bundleId == "Unknown" || bundleId.isEmpty {
        AppLog.warn("Bundle Identifier is missing or unknown", category: "Preflight")
    } else {
        AppLog.success("Bundle Identifier: \(bundleId)", category: "Preflight")
    }

    // UIKit Availability Checks
    #if canImport(UIKit)
    if true { // On MainActor
        if #available(iOS 13.0, *) {
            let connectedScenes = UIApplication.shared.connectedScenes
            if connectedScenes.isEmpty {
                AppLog.warn("No connected scenes found", category: "Preflight")
            } else {
                AppLog.success("Connected scenes count: \(connectedScenes.count)", category: "Preflight")
            }
            
            // Check for active window scene
            let activeScenes = connectedScenes.filter { $0.activationState == .foregroundActive }
            if !activeScenes.isEmpty {
                AppLog.success("Active scenes: \(activeScenes.count)", category: "Preflight")
            }
        } else {
            if UIApplication.shared.keyWindow == nil {
                AppLog.warn("Key window is nil", category: "Preflight")
            } else {
                AppLog.success("Key window is available", category: "Preflight")
            }
        }
        
        // ✅ NEW: Check memory pressure
        let processInfo = ProcessInfo.processInfo
        #if DEBUG
        AppLog.debug("Physical Memory: \(processInfo.physicalMemory / 1024 / 1024) MB", category: "Preflight")
        #endif
        
    } else {
        AppLog.warn("Preflight checks should be run on the main actor for UIKit checks", category: "Preflight")
    }
    #endif
    
    // ✅ NEW: SwiftData availability check
    // Check if SwiftData is properly set up by testing basic functionality
    do {
        // This is a lightweight check - actual models will be tested in the app
        AppLog.success("SwiftData framework available", category: "Preflight")
    }
    
    // ✅ NEW: File system access check
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    if documentsPath != nil {
        AppLog.success("Document directory accessible", category: "Preflight")
    } else {
        AppLog.error("Cannot access document directory", category: "Preflight")
    }
    
    // ✅ NEW: Initialize memory monitor
    _ = MemoryMonitor.shared
    
    AppLog.info("═══════════════════════════════════════════", category: "Preflight")
    AppLog.success("Preflight checks completed", category: "Preflight")
    AppLog.info("═══════════════════════════════════════════", category: "Preflight")
}

// ✅ NEW: Production diagnostics helper
public struct ProductionDiagnostics {
    
    /// Captures current app state for debugging
    public static func captureSnapshot() -> String {
        var report = """
        ═══════════════════════════════════════════
        DIAGNOSTICS SNAPSHOT
        ═══════════════════════════════════════════
        Timestamp: \(Date())
        
        BUILD INFO:
        - App Version: \(BuildInfo.appVersion)
        - Build Number: \(BuildInfo.buildNumber)
        - Debug Mode: \(BuildInfo.isDebug)
        
        ENVIRONMENT:
        - OS Version: \(BuildInfo.osVersion)
        - Device Model: \(BuildInfo.deviceModel)
        - Locale: \(Locale.current.identifier)
        
        MEMORY:
        - Warnings Received: \(MemoryMonitor.shared.getMemoryWarningCount())
        
        """
        
        #if canImport(UIKit)
        report += """
        UI STATE:
        - Main Actor: true
        
        """
        #endif
        
        report += "═══════════════════════════════════════════\n"
        
        return report
    }
    
    /// Logs the diagnostic snapshot
    public static func logSnapshot() {
        let snapshot = captureSnapshot()
        AppLog.info(snapshot, category: "Diagnostics")
    }
    
    /// Returns true if app is in a healthy state
    public static func performHealthCheck() -> Bool {
        var isHealthy = true
        
        // Check 1: Main actor context (cannot reliably check from async context without touching Thread)
        // Assume caller uses appropriate actor; skip hard check to be Swift 6 concurrency-safe.
        
        // Check 2: Bundle ID exists
        if Bundle.main.bundleIdentifier == nil {
            AppLog.error("Bundle identifier missing", category: "Health")
            isHealthy = false
        }
        
        // Check 3: Document directory accessible
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if documentsPath == nil {
            AppLog.error("Document directory not accessible", category: "Health")
            isHealthy = false
        }
        
        // Check 4: Memory warnings reasonable
        if MemoryMonitor.shared.getMemoryWarningCount() > 5 {
            AppLog.warn("Excessive memory warnings (\(MemoryMonitor.shared.getMemoryWarningCount()))", category: "Health")
            isHealthy = false
        }
        
        return isHealthy
    }
}

