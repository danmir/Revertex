//
//  SubscriptionsViewController.swift
//  revertex
//
//  Created by Danil Mironov on 07.12.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import UIKit
import RealmSwift

class SubscriptionViewConteroller: CommonViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Instance Properties
    
    let CellIdentifier = "com.revertex.SubscriptionOptionTableViewCell"
    var options: [Subscription]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "SubscriptionOptionTableViewCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: CellIdentifier)
        tableView.estimatedRowHeight = 85
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.dataSource = self
        tableView.delegate = self
        
        title = "Доступные подписки"
        
        options = SubscriptionService.shared.options
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleOptionsLoaded(notification:)),
                                               name: SubscriptionService.optionsLoadedNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePurchaseSuccessfull(notification:)),
                                               name: SubscriptionService.purchaseSuccessfulNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePurchaseFailed(notification:)),
                                               name: SubscriptionService.purchaseFailedNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePurchaseSuccessfull(notification:)),
                                               name: SubscriptionService.purchaseDeferredNotification,
                                               object: nil)
        
//        self.tabBarItem = UITabBarItem(title: "Books", image: nil, tag: 1)
    }
    
    func handleOptionsLoaded(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.options = SubscriptionService.shared.options
            self?.tableView.reloadData()
        }
    }
    
    func handlePurchaseSuccessfull(notification: Notification) {
        self.stopAnimating()
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func handlePurchaseFailed(notification: Notification) {
        self.stopAnimating()
        let alert = UIAlertController(title: "Ошибка", message: "Покупка завершилась с ошибкой. Попробуйте позже.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension SubscriptionViewConteroller: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as! SubscriptionOptionTableViewCell
        guard let option = options?[indexPath.row] else { return cell }
        
        cell.nameLabel.text = option.product.localizedTitle
        cell.descriptionLabel.text = option.product.localizedDescription
        cell.priceLabel.text = option.formattedPrice
        
        if let currentSubscription = SubscriptionService.shared.currentSubscription {
            if option.product.productIdentifier == currentSubscription.productId && currentSubscription.isActive {
                cell.isCurrentPlan = true
            }
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SubscriptionViewConteroller: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let option = options?[indexPath.row] else { return }
        showLoaderWith(message: "Покупка в процессе")
        SubscriptionService.shared.purchase(subscription: option)
    }
}


