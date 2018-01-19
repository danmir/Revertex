//
//  SubscriptionService.swift
//  revertex
//
//  Created by Danil Mironov on 07.12.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import Foundation
import StoreKit
import Parse

class SubscriptionService: NSObject {
    
    static let sessionIdSetNotification = Notification.Name("SubscriptionServiceSessionIdSetNotification")
    static let optionsLoadedNotification = Notification.Name("SubscriptionServiceOptionsLoadedNotification")
    static let restoreSuccessfulNotification = Notification.Name("SubscriptionServicePurchaseSuccessfulNotification")
    static let restoreFailedNotification = Notification.Name("SubscriptionServiceRestoreFailedNotification")
    static let purchaseSuccessfulNotification = Notification.Name("SubscriptionServicePurchaseSuccessfulNotification")
    static let purchaseFailedNotification = Notification.Name("SubscriptionServicePurchaseFailedNotification")
    static let purchaseDeferredNotification = Notification.Name("SubscriptionServicePurchaseDeferredNotification")
    
    static let shared = SubscriptionService()
    
    var hasReceiptData: Bool {
        return loadReceipt() != nil
    }
    
    var currentSessionId: String? {
        didSet {
            NotificationCenter.default.post(name: SubscriptionService.sessionIdSetNotification, object: currentSessionId)
        }
    }
    
    var currentSubscription: PaidSubscription? {
        didSet {
            guard let currentSubscription = currentSubscription, currentSubscription.isActive else {
                return
            }
            // If we got new paid subscription
            if !currentSubscription.isSync {
                // Save subscription data to parse
                saveSubscriptionServer() { _ in
                    self.saveSubscriptionToUserDefaults()
                }
            } else {
                saveSubscriptionToUserDefaults()
            }
        }
    }
    
    var options: [Subscription]? {
        didSet {
            NotificationCenter.default.post(name: SubscriptionService.optionsLoadedNotification, object: options)
        }
    }
    
    func saveSubscriptionToUserDefaults() {
        let jsonEncoder = JSONEncoder()
        let jsonCurrentSubscription = try! jsonEncoder.encode(currentSubscription)
        print("Saved subscription to localstorage", String(data: jsonCurrentSubscription, encoding: .utf8))
        let persistedCurrentSubscriptionKey = "CurrentSubscription"
        UserDefaults.standard.set(jsonCurrentSubscription, forKey: persistedCurrentSubscriptionKey)
    }
    
    func loadSubscriptionOptions() {
        let productIDPrefix = Bundle.main.bundleIdentifier! + ".sub."
        let allAccessMonthly = productIDPrefix + "allaccess.monthly"
        let allAccessWeekly = productIDPrefix + "allaccess.weekly"
        
        let productIDs = Set([allAccessMonthly, allAccessWeekly])
        
        print("productIDs \(productIDs)")
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    func purchase(subscription: Subscription) {
        let payment = SKPayment(product: subscription.product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func uploadReceipt(wasRestored: Bool = false, completion: ((_ success: Bool) -> Void)? = nil) {
        if let receiptData = loadReceipt() {
            VideoService.shared.upload(wasRestored: wasRestored, receipt: receiptData) { [weak self] (result) in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let result):
                    strongSelf.currentSessionId = result.sessionId
                    strongSelf.currentSubscription = result.currentSubscription
                    print(strongSelf.currentSessionId, strongSelf.currentSubscription)
                    completion?(true)
                case .failure(let error):
                    print("🚫 Receipt Upload Failed: \(error)")
                    completion?(false)
                }
            }
        }
    }
    
    // Restore saved in user defaults subscription if exists
    func restoreSubscriptionLocal() -> Bool {
        let persistedCurrentSubscriptionKey = "CurrentSubscription"
        if let persistedCurrentSubscription = UserDefaults.standard.object(forKey: persistedCurrentSubscriptionKey) as? Data {
            let jsonDecoder = JSONDecoder()
            var savedCurrentSubscription = try! jsonDecoder.decode(PaidSubscription.self, from: persistedCurrentSubscription)
            savedCurrentSubscription.isRestoredLocal = true
            currentSubscription = savedCurrentSubscription
            print("Subscription restored from user defaults and isActive == \(savedCurrentSubscription.isActive)")
            return true
        }
        return false
    }
    
    // Add new subscription record to parse
    func saveSubscriptionServer(completion: ((_ success: Bool) -> Void)? = nil) {
        guard var currentSubscription = currentSubscription, let currentUser = PFUser.current() else {
            return
        }
        
        let parseSubscription = PFObject(className:"Subscription")
        parseSubscription["purchaseDevice"] = "ios"
        parseSubscription["productId"] = currentSubscription.productId
        parseSubscription["subscriptionId"] = currentSubscription.transactionId
        parseSubscription["user"] = PFUser.current()
        parseSubscription["subscriptionFrom"] = currentSubscription.purchaseDate
        parseSubscription["subscriptionTill"] = currentSubscription.expiresDate
        parseSubscription.acl = PFACL(user: currentUser)
        
        parseSubscription.saveInBackground {
            (success: Bool, error: Error?) in
            if (success) {
                print("Subscription was saved to parse")
                SubscriptionService.shared.currentSubscription?.isSync = true
                completion?(true)
            } else {
                print(error)
                completion?(false)
            }
        }
    }
    
    // Try to find active subscription on parse and restore it
    func restoreSubscriptionServer(completion: ((_ paidSubscription: PaidSubscription?, _ error: String?) -> Void)? = nil) {
        guard let currentUser = PFUser.current() else {
            completion?(nil, "Нет текущего пользователя")
            return
        }
        
        let query = PFQuery(className:"Subscription")
        query.whereKey("user", equalTo:currentUser)
        query.whereKey("subscriptionTill", greaterThan:Date())
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            
            if error == nil {
                print("Successfully retrieved \(objects!.count) subscriptions")
                if let objects = objects {
                    let paidSubscriptions: [PaidSubscription] = objects.map { (elem) -> PaidSubscription in
                        let productId = elem["productId"] as? String ?? ""
                        let purchaseDate = elem["subscriptionFrom"] as? Date ?? Date()
                        let expiresDate = elem["subscriptionTill"] as? Date ?? Date()
                        let transactionId = elem["subscriptionId"] as? String ?? ""
                        
                        let paidSubscription = PaidSubscription(productId: productId, transactionId: transactionId, purchaseDate: purchaseDate, expiresDate: expiresDate)
                        return paidSubscription
                    }
                    
                    let activeSubscriptions = paidSubscriptions.filter { $0.isActive }
                    let sortedByMostRecentPurchase = activeSubscriptions.sorted { $0.purchaseDate > $1.purchaseDate }
                    
                    var currentSubscription = sortedByMostRecentPurchase.first
                    currentSubscription?.isRestoredServer = true
                    currentSubscription?.isSync = true
                    print("currentSubscription from parse \(currentSubscription)")
                    self.currentSubscription = currentSubscription
                    completion?(currentSubscription, nil)
                    if let _ = self.currentSubscription {
                        print("Subscription restored from parse")
                    }
                }
            } else {
                print("Error: \(error!)")
                completion?(nil, error?.localizedDescription)
            }
        }
    }
    
    // Common restoration scenario
    func restoreSubscriptionCommon() {
        print("Called restoreSubscriptionCommon")
        let localRestoreResult = restoreSubscriptionLocal()
        if localRestoreResult {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: SubscriptionService.restoreSuccessfulNotification, object: nil)
            }
            return
        }
        print("No local subscription found")
        restoreSubscriptionServer() { currentSubscription, error in
            guard let _ = currentSubscription else {
                return
            }
            print("Found subscription on parse")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: SubscriptionService.restoreSuccessfulNotification, object: nil)
            }
        }
    }
    
    // Find all subscriptions for user
    func serverSubscriptionsFor(user: PFUser? = PFUser.current(), completion: ((_ paidSubscriptions: [PaidSubscription]) -> Void)? = nil) {
        let subscriptions = [PaidSubscription]()
        
        guard let currentUser = user else {
            completion?(subscriptions)
            return
        }
        
        let subscriptionQuery = PFQuery(className:"Subscription")
        subscriptionQuery.whereKey("user", equalTo:currentUser)
        subscriptionQuery.findObjectsInBackground() {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                print("Successfully retrieved \(objects!.count) subscriptions")
                if let objects = objects {
                    let paidSubscriptions: [PaidSubscription] = objects.map { (elem) -> PaidSubscription in
                        let productId = elem["productId"] as? String ?? ""
                        let purchaseDate = elem["subscriptionFrom"] as? Date ?? Date()
                        let expiresDate = elem["subscriptionTill"] as? Date ?? Date()
                        let transactionId = elem["subscriptionId"] as? String ?? ""
                        
                        let paidSubscription = PaidSubscription(productId: productId, transactionId: transactionId, purchaseDate: purchaseDate, expiresDate: expiresDate)
                        return paidSubscription
                    }
                    
                    completion?(paidSubscriptions)
                    return
                }
            } else {
                print("Error: \(error!)")
            }
        }
        completion?(subscriptions)
    }
    
    private func loadReceipt() -> Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print("Error loading receipt data: \(error.localizedDescription)")
            return nil
        }
    }
}

extension SubscriptionService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Products \(response.products)")
        options = response.products.map {Subscription(product: $0)}
        print("Parsed products \(options!)")
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request is SKProductsRequest {
            print("Subscription Options Failed Loading: \(error.localizedDescription)")
        }
    }
}
