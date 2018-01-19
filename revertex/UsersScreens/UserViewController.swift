//
//  UserViewController.swift
//  revertex
//
//  Created by Danil Mironov on 26.07.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import UIKit
import Parse

class UserViewController: CommonViewController {
    
    // MARK: - Properties
    let showLoginSegueIdentifier = "logoutSuccessful"

    @IBOutlet weak var subscriptionButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
//    @IBOutlet weak var transferButton: UIButton!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var subscriptionStatus: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Профиль"

        let currentUser = PFUser.current()
        if currentUser != nil {
            userEmail.text = currentUser?.username
        }
        
        subscriptionButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        restoreButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
//        transferButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        
        // Уведомления об изменении статуса подписки
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePurchaseStateChange(notification:)),
                                               name: SubscriptionService.purchaseSuccessfulNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePurchaseStateChange(notification:)),
                                               name: SubscriptionService.purchaseFailedNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: .UIApplicationWillEnterForeground,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePurchaseStateChange(notification:)),
                                               name: SubscriptionService.restoreSuccessfulNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePurchaseStateChange(notification:)),
                                               name: SubscriptionService.restoreFailedNotification,
                                               object: nil)
    }
    
    func checkCurrentSubscriptionState() {
        guard let subscription = SubscriptionService.shared.currentSubscription else {
            self.subscriptionStatus.text = "Не активна"
            return
        }
        if subscription.isActive {
            self.dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
            self.dateFormatter.timeZone = TimeZone.current
            self.subscriptionStatus.text = "До \(self.dateFormatter.string(from: subscription.expiresDate))"
        } else {
            self.subscriptionStatus.text = "Не активна"
        }
    }
    
    func willEnterForeground() {
        checkCurrentSubscriptionState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkCurrentSubscriptionState()
    }
    
    func handlePurchaseStateChange(notification: Notification) {
        stopAnimating()
        checkCurrentSubscriptionState()
    }
    
    // MARK: - IBActions
    @IBAction func btnLogOutPressed(_ sender: UIButton) {
        PFUser.logOut()
        
        // Remove current saved local subscription
        let persistedCurrentSubscriptionKey = "CurrentSubscription"
        UserDefaults.standard.removeObject(forKey:persistedCurrentSubscriptionKey)
        SubscriptionService.shared.currentSubscription = nil
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController")
        UIApplication.shared.keyWindow?.rootViewController = viewController
        
//        self.performSegue(withIdentifier: showLoginSegueIdentifier, sender: self)
    }
    
//    @IBAction func btnRestorePressed(_ sender: UIButton) {
//        showLoaderWith(message: "Восстановление покупок")
//        SubscriptionService.shared.restorePurchases()
//    }

    @IBAction func btnRestorePressed(_ sender: UIButton) {
        showLoaderWith(message: "Восстановление покупок")
        
        SubscriptionService.shared.restoreSubscriptionServer {
            (subscription, error) -> Void in
            self.stopAnimating()
            guard let subscription = subscription else {
                SubscriptionService.shared.restorePurchases()
                return
            }
            if subscription.isActive {
                self.dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
                self.dateFormatter.timeZone = TimeZone.current
                self.subscriptionStatus.text = "До \(self.dateFormatter.string(from: subscription.expiresDate))"
            } else {
                self.showAlertWith(title: "Восстановление", text: "У вас нет активных подписок")
            }
        };
    }
    
    @IBAction func btnTransferPressed(_ sender: UIButton) {
        showLoaderWith(message: "Загрузка")
        
        SubscriptionService.shared.restoreSubscriptionServer {
            (subscription, error) -> Void in
            self.stopAnimating()
            guard let subscription = subscription else {
                self.showAlertWith(title: "Восстановление", text: "У вас нет активных подписок")
                return
            }
            if subscription.isActive {
                self.dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
                self.dateFormatter.timeZone = TimeZone.current
                self.subscriptionStatus.text = "До \(self.dateFormatter.string(from: subscription.expiresDate))"
            } else {
                self.showAlertWith(title: "Восстановление", text: "У вас нет активных подписок")
            }
        };
    }

    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "subscriptionView" {
            if let subscription = SubscriptionService.shared.currentSubscription, subscription.isActive {
                let alert = UIAlertController(title: "Подписка", message: "У вас уже есть активная подписка до \(self.dateFormatter.string(from: subscription.expiresDate))", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: {_ in
                    self.performSegue(withIdentifier: identifier, sender: sender)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        return true
    }

//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//    }

}
