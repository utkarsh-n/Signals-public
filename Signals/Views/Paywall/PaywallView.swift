//
//  PaywallView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import StoreKit

/// Main paywall screen with calm, premium feel
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isEligibleForTrial = true
    
    private let storeService = StoreKitService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero section
                    heroSection
                    
                    // Value propositions
                    valuePropsSection
                    
                    // Plan selection
                    planSelectionSection
                    
                    // Trial info
                    trialInfoSection
                    
                    // Subscribe button
                    subscribeButton
                    
                    // Restore & legal
                    footerSection
                }
                .padding()
            }
            .background(ColorPalette.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(ColorPalette.primaryGradient)
            }
            
            VStack(spacing: 8) {
                Text("Unlock Signals")
                    .font(Typography.largeTitle)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text("Your personal pattern mirror")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
        }
        .padding(.top, 24)
    }
    
    // MARK: - Value Props Section
    
    private var valuePropsSection: some View {
        VStack(spacing: 16) {
            ValuePropRow(
                icon: "lightbulb.fill",
                iconColor: .yellow,
                title: "Unlimited Insights",
                description: "Get all your weekly insights without limits"
            )
            
            ValuePropRow(
                icon: "calendar",
                iconColor: .blue,
                title: "Full Timeline Access",
                description: "Explore your complete history and patterns"
            )
            
            ValuePropRow(
                icon: "square.and.arrow.up",
                iconColor: .green,
                title: "Data Export",
                description: "Export your data anytime as JSON"
            )
        }
        .padding()
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Plan Selection
    
    private var planSelectionSection: some View {
        VStack(spacing: 12) {
            Text("Choose Your Plan")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            VStack(spacing: 12) {
                PlanOptionCard(
                    plan: .yearly,
                    isSelected: selectedPlan == .yearly,
                    isBestValue: true
                ) {
                    selectedPlan = .yearly
                    Haptics.selection()
                }
                
                PlanOptionCard(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    isBestValue: false
                ) {
                    selectedPlan = .monthly
                    Haptics.selection()
                }
            }
        }
    }
    
    // MARK: - Trial Info
    
    private var trialInfoSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                
                Text("Start with 1 week free")
                    .font(Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorPalette.primaryText)
            }
            
            Text("Try all features free for 7 days. Cancel anytime.")
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Subscribe Button
    
    private var subscribeButton: some View {
        Button(action: subscribe) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Free Trial")
                        .fontWeight(.semibold)
                }
            }
            .font(Typography.body)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isPurchasing)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            Button("Restore Purchases") {
                restorePurchases()
            }
            .font(Typography.caption)
            .foregroundStyle(ColorPalette.accent)
            
            VStack(spacing: 4) {
                Text("Payment will be charged to your Apple ID account at confirmation of purchase.")
                    .font(.caption2)
                    .foregroundStyle(ColorPalette.tertiaryText)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Link("Terms", destination: URL(string: "https://signals.app/terms")!)
                    Link("Privacy", destination: URL(string: "https://signals.app/privacy")!)
                }
                .font(.caption2)
                .foregroundStyle(ColorPalette.secondaryText)
            }
        }
    }
    
    // MARK: - Actions
    
    private func subscribe() {
        isPurchasing = true
        Haptics.purchaseInitiated()
        
        Task {
            do {
                // Get the appropriate product
                let product: Product?
                switch selectedPlan {
                case .monthly:
                    product = storeService.monthlyProduct
                case .yearly:
                    product = storeService.annualProduct
                }
                
                guard let product = product else {
                    await MainActor.run {
                        errorMessage = "Product not available. Please try again later."
                        showingError = true
                        isPurchasing = false
                    }
                    return
                }
                
                // Attempt purchase
                let transaction = try await storeService.purchase(product)
                
                await MainActor.run {
                    isPurchasing = false
                    
                    if transaction != nil {
                        // Purchase successful
                        Haptics.purchaseCompleted()
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isPurchasing = false
                    Haptics.error()
                }
            }
        }
    }
    
    private func restorePurchases() {
        Haptics.light()
        isPurchasing = true
        
        Task {
            do {
                try await storeService.restorePurchases()
                
                await MainActor.run {
                    isPurchasing = false
                    
                    if storeService.hasActiveSubscription {
                        Haptics.success()
                        dismiss()
                    } else {
                        errorMessage = "No previous purchases found."
                        showingError = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isPurchasing = false
                }
            }
        }
    }
    
    private func checkTrialEligibility() async {
        if let product = storeService.annualProduct {
            isEligibleForTrial = await storeService.isEligibleForTrial(product: product)
        }
    }
}

// MARK: - Subscription Plan

enum SubscriptionPlan: String, CaseIterable {
    case monthly
    case yearly
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "$3.99"
        case .yearly: return "$39.99"
        }
    }
    
    var pricePerMonth: String {
        switch self {
        case .monthly: return "$3.99/mo"
        case .yearly: return "$3.33/mo"
        }
    }
    
    var billingPeriod: String {
        switch self {
        case .monthly: return "per month"
        case .yearly: return "per year"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Save 17%"
        }
    }
}

// MARK: - Value Prop Row

struct ValuePropRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text(description)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Plan Option Card

struct PlanOptionCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? ColorPalette.accent : ColorPalette.tertiaryText, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(ColorPalette.accent)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Plan details
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(plan.displayName)
                            .font(Typography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(ColorPalette.primaryText)
                        
                        if isBestValue {
                            Text("Best Value")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(ColorPalette.accent)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(plan.pricePerMonth)
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(Typography.headline)
                        .foregroundStyle(ColorPalette.primaryText)
                    
                    Text(plan.billingPeriod)
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
            }
            .padding()
            .background(isSelected ? ColorPalette.accent.opacity(0.1) : ColorPalette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? ColorPalette.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environment(AppState())
}
