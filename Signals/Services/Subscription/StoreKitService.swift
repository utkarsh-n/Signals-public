//
//  StoreKitService.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import StoreKit

/// Manages StoreKit 2 product loading, purchases, and transactions
@MainActor
@Observable
final class StoreKitService {
    // MARK: - Singleton
    
    static let shared = StoreKitService()
    
    // MARK: - Product Identifiers
    
    enum ProductID {
        static let monthly = "signals_monthly"
        static let annual = "signals_annual"
        
        static var all: [String] { [monthly, annual] }
    }
    
    // MARK: - State
    
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var error: StoreError?
    
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthly }
    }
    
    var annualProduct: Product? {
        products.first { $0.id == ProductID.annual }
    }
    
    // MARK: - Transaction Updates
    
    private nonisolated(unsafe) var transactionListener: Task<Void, Error>?
    
    private init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        // Load products and check entitlements on init
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Load available products from the App Store
    func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            products = try await Product.products(for: ProductID.all)
            isLoading = false
        } catch {
            self.error = .failedToLoadProducts(error)
            isLoading = false
        }
    }
    
    // MARK: - Purchase
    
    /// Purchase a product
    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        error = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update purchased products
                await updatePurchasedProducts()
                
                // Finish the transaction
                await transaction.finish()
                
                isLoading = false
                Haptics.purchaseCompleted()
                
                return transaction
                
            case .userCancelled:
                isLoading = false
                return nil
                
            case .pending:
                isLoading = false
                error = .purchasePending
                return nil
                
            @unknown default:
                isLoading = false
                return nil
            }
        } catch {
            self.error = .purchaseFailed(error)
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        error = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false
        } catch {
            self.error = .restoreFailed(error)
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Entitlement Check
    
    /// Update the set of purchased product IDs
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            }
        }
        
        purchasedProductIDs = purchased
        
        // Update PaywallManager
        PaywallManager.shared.updateEntitlementStatus(purchasedIDs: purchased)
    }
    
    /// Check if user has active subscription
    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                await self.handleTransactionUpdate(result)
            }
        }
    }
    
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            
            // Update purchased products
            await updatePurchasedProducts()
            
            // Finish the transaction
            await transaction.finish()
        } catch {
            print("Transaction verification failed: \(error)")
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw StoreError.verificationFailed(error)
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Subscription Info
    
    /// Get subscription status for a product
    func subscriptionStatus(for productID: String) async -> Product.SubscriptionInfo.Status? {
        guard let product = products.first(where: { $0.id == productID }),
              let subscription = product.subscription else {
            return nil
        }
        
        do {
            let statuses = try await subscription.status
            return statuses.first
        } catch {
            return nil
        }
    }
    
    /// Get renewal info if subscribed
    func getRenewalInfo() async -> Product.SubscriptionInfo.RenewalInfo? {
        for productID in purchasedProductIDs {
            if let status = await subscriptionStatus(for: productID),
               case .verified(let renewalInfo) = status.renewalInfo {
                return renewalInfo
            }
        }
        return nil
    }
    
    /// Get expiration date
    func getExpirationDate() async -> Date? {
        for productID in purchasedProductIDs {
            if let status = await subscriptionStatus(for: productID),
               case .verified(let transaction) = status.transaction {
                return transaction.expirationDate
            }
        }
        return nil
    }
    
    // MARK: - Trial Eligibility
    
    /// Check if user is eligible for trial
    func isEligibleForTrial(product: Product) async -> Bool {
        guard let subscription = product.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
    }
}

// MARK: - Store Errors

enum StoreError: LocalizedError {
    case failedToLoadProducts(Error)
    case purchaseFailed(Error)
    case purchasePending
    case restoreFailed(Error)
    case verificationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadProducts(let error):
            return "Failed to load products: \(error.localizedDescription)"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .purchasePending:
            return "Purchase is pending approval"
        case .restoreFailed(let error):
            return "Restore failed: \(error.localizedDescription)"
        case .verificationFailed(let error):
            return "Verification failed: \(error.localizedDescription)"
        }
    }
}
