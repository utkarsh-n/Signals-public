//
//  Haptics.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Centralized haptic feedback manager
enum Haptics {
    // MARK: - Impact Feedback
    
    /// Light impact for subtle interactions
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact for standard interactions
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact for significant actions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Soft impact for gentle feedback
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /// Rigid impact for firm feedback
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success feedback for completed actions
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning feedback for cautionary actions
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error feedback for failed actions
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback for picker/selection changes
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Patterns
    
    /// Double tap feedback
    static func doubleTap() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            light()
        }
    }
    
    /// Insight revealed feedback
    static func insightRevealed() {
        medium()
    }
    
    /// Reflection saved feedback
    static func reflectionSaved() {
        success()
    }
    
    /// Mood logged feedback
    static func moodLogged() {
        soft()
    }
    
    /// Tab changed feedback
    static func tabChanged() {
        selection()
    }
    
    /// Card expanded feedback
    static func cardExpanded() {
        light()
    }
    
    /// Action completed feedback
    static func actionCompleted() {
        success()
    }
    
    /// Toggle changed feedback
    static func toggleChanged() {
        light()
    }
    
    // MARK: - Navigation Feedback
    
    /// Page changed (onboarding, carousel)
    static func pageChanged() {
        selection()
    }
    
    /// Sheet presented
    static func sheetPresented() {
        light()
    }
    
    /// Sheet dismissed
    static func sheetDismissed() {
        soft()
    }
    
    /// Pull to refresh triggered
    static func pullToRefresh() {
        medium()
    }
    
    // MARK: - Data Feedback
    
    /// Data synced successfully
    static func dataSynced() {
        soft()
    }
    
    /// New insight arrived
    static func newInsight() {
        medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            light()
        }
    }
    
    /// Weekly report ready
    static func weeklyReportReady() {
        success()
    }
    
    /// Milestone achieved
    static func milestoneAchieved() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            light()
        }
    }
    
    // MARK: - Interaction Feedback
    
    /// Button pressed
    static func buttonPressed() {
        light()
    }
    
    /// Long press recognized
    static func longPress() {
        medium()
    }
    
    /// Swipe action triggered
    static func swipeAction() {
        light()
    }
    
    /// Delete action
    static func deleteAction() {
        warning()
    }
    
    /// Bookmark toggled
    static func bookmarkToggled() {
        light()
    }
    
    /// Rating submitted
    static func ratingSubmitted() {
        soft()
    }
    
    // MARK: - Calendar/Timeline Feedback
    
    /// Day selected on calendar
    static func daySelected() {
        selection()
    }
    
    /// Month changed
    static func monthChanged() {
        light()
    }
    
    // MARK: - Subscription Feedback
    
    /// Purchase initiated
    static func purchaseInitiated() {
        medium()
    }
    
    /// Purchase completed
    static func purchaseCompleted() {
        success()
    }
    
    /// Trial started
    static func trialStarted() {
        success()
    }
    
    // MARK: - Error Feedback
    
    /// Validation error
    static func validationError() {
        error()
    }
    
    /// Permission denied
    static func permissionDenied() {
        warning()
    }
    
    /// Network error
    static func networkError() {
        error()
    }
}
