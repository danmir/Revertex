//
//  VideoService.swift
//  revertex
//
//  Created by Danil Mironov on 07.12.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

private let itcAccountSecret = "4fa5dda717b448609074f7c2470812ec"

import Foundation

public enum Result<T> {
    case failure(VideoServiceError)
    case success(T)
}

public typealias LoadVideoCompletion = (_ videos: Result<Bool>) -> Void
public typealias UploadReceiptCompletion = (_ result: Result<(sessionId: String, currentSubscription: PaidSubscription?)>) -> Void

public typealias SessionId = String

public enum VideoServiceError: Error {
    case missingAccountSecret
    case invalidSession
    case noActiveSubscription
    case other(Error)
}

public class VideoService {
    
    public static let shared = VideoService()
    let simulatedStartDate: Date
    
    private var sessions = [SessionId: Session]()
    
    init() {
        let persistedDateKey = "RWSSimulatedStartDate"
        if let persistedDate = UserDefaults.standard.object(forKey: persistedDateKey) as? Date {
            simulatedStartDate = persistedDate
        } else {
            let date = Date().addingTimeInterval(-30) // 30 second difference to account for server/client drift.
            UserDefaults.standard.set(date, forKey: "RWSSimulatedStartDate")
            
            simulatedStartDate = date
        }
    }
    
    /// Trade receipt for session id
    func tryUpload(url: URL, receipt data: Data, completion: @escaping (Bool) -> Void) {
        let body = [
            "receipt-data": data.base64EncodedString(),
            "password": itcAccountSecret
        ]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        
        let task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
            if let error = error {
                print("error", error)
                completion(false)
            } else if let responseData = responseData {
                let json = try! JSONSerialization.jsonObject(with: responseData, options: []) as! Dictionary<String, Any>
                if let status = json["status"] as? Int {
                    if status == 0 {
                        completion(true)
                        return
                    }
                }
            }
            completion(false)
            return
        }
        
        task.resume()
    }
    
    public func upload(wasRestored: Bool = false, receipt data: Data, completion: @escaping UploadReceiptCompletion) {
        let body = [
            "receipt-data": data.base64EncodedString(),
            "password": itcAccountSecret
        ]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: [])
        
        let testUrl = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
        let prodUrl = URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
        var url: URL = prodUrl
        
        tryUpload(url: prodUrl, receipt: data) { correctUrl in
            if !correctUrl {
                print("Changing to test url")
                url = testUrl
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = bodyData
            
            let task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
                if let error = error {
                    print("error", error)
                    completion(.failure(.other(error)))
                } else if let responseData = responseData {
                    print("responseData", responseData)
                    let json = try! JSONSerialization.jsonObject(with: responseData, options: []) as! Dictionary<String, Any>
                    print("json", json)
                    var session = Session(receiptData: data, parsedReceipt: json)
                    
                    // Filter Apple subscription with DB
                    if wasRestored {
                        session.filterSubscriptionsByParse() { paidSubscriptions in
                            session.paidSubscriptions = paidSubscriptions
                            self.sessions[session.id] = session
                            let result = (sessionId: session.id, currentSubscription: session.currentSubscription)
                            completion(.success(result))
                        }
                    } else {
                        self.sessions[session.id] = session
                        let result = (sessionId: session.id, currentSubscription: session.currentSubscription)
                        completion(.success(result))
                    }
                }
            }
            
            task.resume()
        }
    }
    
    /// Use sessionId to get video permission
    public func videos(for sessionId: SessionId, completion: LoadVideoCompletion?) {
        guard itcAccountSecret != "YOUR_ACCOUNT_SECRET" else {
            completion?(.failure(.missingAccountSecret))
            return
        }
        
        guard let _ = sessions[sessionId] else {
            completion?(.failure(.invalidSession))
            return
        }
        
        let paidSubscriptions = paidSubcriptions(since: simulatedStartDate, for: sessionId)
        guard paidSubscriptions.count > 0 else {
            completion?(.failure(.noActiveSubscription))
            return
        }
        
        completion?(.success(true))
    }
    
    private func paidSubcriptions(since date: Date, for sessionId: SessionId) -> [PaidSubscription] {
        if let session = sessions[sessionId] {
            let subscriptions = session.paidSubscriptions.filter { $0.purchaseDate >= date }
            return subscriptions.sorted { $0.purchaseDate < $1.purchaseDate }
        } else {
            return []
        }
    }
}
