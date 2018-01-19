//
//  PaidSubscription.swift
//  revertex
//
//  Created by Danil Mironov on 07.12.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import Foundation

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
    
    return formatter
}()

public struct PaidSubscription: Codable {
    
    public let productId: String
    public let purchaseDate: Date
    public let expiresDate: Date
    public let transactionId: String
    public var isRestoredLocal: Bool = false
    public var isRestoredServer: Bool = false
    public var isSync: Bool = false
    
    public var isActive: Bool {
        // is current date between purchaseDate and expiresDate?
        return (purchaseDate...expiresDate).contains(Date())
    }
    
    init?(json: [String: Any]) {
        guard
            let productId = json["product_id"] as? String,
            let transactionId = json["transaction_id"] as? String,
            let purchaseDateString = json["purchase_date"] as? String,
            let purchaseDate = dateFormatter.date(from: purchaseDateString),
            let expiresDateString = json["expires_date"] as? String,
            let expiresDate = dateFormatter.date(from: expiresDateString)
            else {
                return nil
        }
        
        self.productId = productId
        self.purchaseDate = purchaseDate
        self.expiresDate = expiresDate
        self.transactionId = transactionId
    }
    
    init(productId: String, transactionId: String, purchaseDate: Date, expiresDate: Date) {
        self.productId = productId
        self.purchaseDate = purchaseDate
        self.expiresDate = expiresDate
        self.transactionId = transactionId
    }
}

