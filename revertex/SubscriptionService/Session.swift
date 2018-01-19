//
//  Session.swift
//  revertex
//
//  Created by Danil Mironov on 07.12.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import Foundation
import Parse

public struct Session {
    public let id: SessionId
    public var paidSubscriptions: [PaidSubscription]
    
    public var currentSubscription: PaidSubscription? {
//        let activeSubscriptions = paidSubscriptions.filter { $0.isActive && $0.purchaseDate >= VideoService.shared.simulatedStartDate }
        let activeSubscriptions = paidSubscriptions.filter { $0.isActive }
        let sortedByMostRecentPurchase = activeSubscriptions.sorted { $0.purchaseDate > $1.purchaseDate }
        
        return sortedByMostRecentPurchase.first
    }
    
    public var receiptData: Data
    public var parsedReceipt: [String: Any]
    
    init(wasRestored: Bool = false, receiptData: Data, parsedReceipt: [String: Any]) {
        id = UUID().uuidString
        self.receiptData = receiptData
        self.parsedReceipt = parsedReceipt
        
        if let receipt = parsedReceipt["receipt"] as? [String: Any], let purchases = receipt["in_app"] as? Array<[String: Any]> {
            var subscriptions = [PaidSubscription]()
            
            for purchase in purchases {
                if var paidSubscription = PaidSubscription(json: purchase) {
                    if wasRestored {
                        paidSubscription.isSync = true
                        paidSubscription.isRestoredServer = true
                    }
                    subscriptions.append(paidSubscription)
                }
            }
            
            paidSubscriptions = subscriptions
        } else {
            paidSubscriptions = []
        }
    }
    
    // Elliminates subscriptions that not on parse for current user
    func filterSubscriptionsByParse(completion: @escaping ((_ paidSubscriptions: [PaidSubscription]) -> Void)) {
        var subscriptions = [PaidSubscription]()
        
        // Get subscriptions for current user from parse
        SubscriptionService.shared.serverSubscriptionsFor(user: PFUser.current()) { paidSubscriptionsParse in
            for paidSubscriptionParse in paidSubscriptionsParse {
                // Compare with subscriptions that we already have
                for paidSubscription in self.paidSubscriptions {
                    if paidSubscriptionParse.transactionId == paidSubscription.transactionId {
                        subscriptions.append(paidSubscription)
                    }
                }
            }
            completion(subscriptions)
        }
    }
    
}

// MARK: - Equatable

extension Session: Equatable {
    public static func ==(lhs: Session, rhs: Session) -> Bool {
        return lhs.id == rhs.id
    }
}

