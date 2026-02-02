//
//  PhotoQuotaManager.swift
//  Reverie Weaver
//
//  Production Ready — 11/29/25
//  Manages monthly photo upload quota with freemium support.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PhotoQuotaManager: ObservableObject {
    static let shared = PhotoQuotaManager()
    
    // MARK: - Configuration
    
    private let FREE_LIMIT = 10
    private let PREMIUM_LIMIT = 45
    
    // keys
    private let kPhotosUsed = "photosUsedThisMonth"
    private let kLastResetDate = "lastPhotoResetDate"
    private let kIsPremium = "isPremiumUser"
    
    var dateProvider: () -> Date = { Date() }
    
    // MARK: - Published Properties
    
    @Published private(set) var photosUsedThisMonth: Int = 0
    
    @Published var isPremiumUser: Bool = false {
        didSet {
            UserDefaults.standard.set(isPremiumUser, forKey: kIsPremium)
            objectWillChange.send()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Current limit based on premium status
    var currentLimit: Int {
        isPremiumUser ? PREMIUM_LIMIT : FREE_LIMIT
    }
    
    /// Remaining photos this month
    var remainingPhotos: Int {
        max(0, currentLimit - photosUsedThisMonth)
    }
    
    /// Should show the counter? (Visible at 80% capacity or if Over Limit due to downgrade)
    var shouldShowCounter: Bool {
        let threshold = Int(Double(currentLimit) * 0.8)
        return photosUsedThisMonth >= threshold
    }
    
    /// Is at (or over) limit?
    var isAtLimit: Bool {
        photosUsedThisMonth >= currentLimit
    }
    
    /// Counter display text
    var counterText: String {
        "\(photosUsedThisMonth)/\(currentLimit)"
    }
    
    /// Progress for UI bars (0.0 to 1.0)
    var progress: Double {
        guard currentLimit > 0 else { return 1.0 }
        return min(1.0, Double(photosUsedThisMonth) / Double(currentLimit))
    }
    
    // MARK: - Initialization
    
    private init() {
        // 1. Load Premium Status
        self.isPremiumUser = UserDefaults.standard.bool(forKey: kIsPremium)
        
        // 2. Load Usage
        self.photosUsedThisMonth = UserDefaults.standard.integer(forKey: kPhotosUsed)
        
        // 3. Verify Date (Reset if new month)
        checkAndResetIfNeeded()
    }
    
    // MARK: - Public API
    
    /// Check if user can add a photo
    func canAddPhoto() -> Bool {
        checkAndResetIfNeeded()
        return photosUsedThisMonth < currentLimit
    }
    
    /// Call this AFTER a successful photo upload/save
    func recordPhotoAdded() {
        checkAndResetIfNeeded()
        photosUsedThisMonth += 1
        saveUsage()
    }
    
    /// Call this when a user deletes a photo
    /// Note: We simply credit a slot back. We do not track *which* month a specific photo belonged to.
    func recordPhotoRemoved() {
        // Prevent negative counts (e.g. user deletes a photo from last month immediately after a reset)
        guard photosUsedThisMonth > 0 else { return }
        
        photosUsedThisMonth -= 1
        saveUsage()
    }
    
    /// Helper to determine the alert message
    func getLimitMessage() -> String {
        if isPremiumUser {
            return "You've reached the limit of \(PREMIUM_LIMIT) photos for this month. Your quota will reset on the 1st of next month."
        } else {
            return "You've used all \(FREE_LIMIT) free photos this month.\n\nUpgrade to Premium for \(PREMIUM_LIMIT) photos/month, or wait until the 1st of next month."
        }
    }
    
    /// Debugging only
    func debugReset() {
        photosUsedThisMonth = 0
        UserDefaults.standard.removeObject(forKey: kLastResetDate)
        saveUsage()
        checkAndResetIfNeeded()
    }
    
    // MARK: - Internal Logic
    
    private func saveUsage() {
        UserDefaults.standard.set(photosUsedThisMonth, forKey: kPhotosUsed)
    }
    
    private func checkAndResetIfNeeded() {
        let now = dateProvider()
        let calendar = Calendar.current
        
        // If we have a saved date, check if it's the same month/year
        if let lastReset = UserDefaults.standard.object(forKey: kLastResetDate) as? Date {
            let lastComponents = calendar.dateComponents([.month, .year], from: lastReset)
            let currentComponents = calendar.dateComponents([.month, .year], from: now)
            
            if lastComponents.month != currentComponents.month || lastComponents.year != currentComponents.year {
                resetForNewMonth(date: now)
            }
        } else {
            // First run ever
            UserDefaults.standard.set(now, forKey: kLastResetDate)
        }
    }
    
    private func resetForNewMonth(date: Date) {
        photosUsedThisMonth = 0
        saveUsage()
        UserDefaults.standard.set(date, forKey: kLastResetDate)
        print("📅 ReverieWeaver: Photo quota reset for new month")
    }
}

// MARK: - UI Components

/// A pill-shaped badge showing usage.
/// Only appears when the user is nearing their limit.
struct PhotoQuotaBadge: View {
    @ObservedObject var quotaManager = PhotoQuotaManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if quotaManager.shouldShowCounter {
            HStack(spacing: 4) {
                if quotaManager.isAtLimit {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                }
                
                Text(quotaManager.counterText)
                    .font(.system(size: 11, weight: .medium))
                    .fontDesign(.serif)
            }
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.1))
                    .overlay(
                        Capsule()
                            .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .animation(.snappy, value: quotaManager.photosUsedThisMonth)
        }
    }
    
    private var statusColor: Color {
        if quotaManager.isAtLimit {
            return Color(hex: "D9A58A")
        } else {
            return Color.secondary
        }
    }
}

/// Modifier to handle the Alert logic cleanly
struct PhotoLimitAlertModifier: ViewModifier {
    @ObservedObject var quotaManager = PhotoQuotaManager.shared
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .alert("Photo Limit Reached", isPresented: $isPresented) {
                if !quotaManager.isPremiumUser {
                    Button("Unlock Premium") {
                        togglePremiumDebug()
                    }
                    Button("Not Now", role: .cancel) { }
                } else {
                    Button("OK", role: .cancel) { }
                }
            } message: {
                Text(quotaManager.getLimitMessage())
            }
    }
    
    private func togglePremiumDebug() {
        quotaManager.isPremiumUser.toggle()
    }
}

extension View {
    func photoLimitAlert(isPresented: Binding<Bool>) -> some View {
        modifier(PhotoLimitAlertModifier(isPresented: isPresented))
    }
}
