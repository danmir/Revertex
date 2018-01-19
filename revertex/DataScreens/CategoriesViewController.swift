//
//  TableViewController.swift
//  revertex
//
//  Created by Danil Mironov on 23.07.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import UIKit
import RealmSwift

class CategoriesViewController: CommonViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var rootView: UITableView!
    
    let CellIdentifier = "com.revertex.RootCategoryTableViewCell"
    
    let realm = try! Realm()
    var categoryName = "__root__"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        rootView.dataSource = self
        rootView.delegate = self
        
        self.title = "Profit revertex"
        
        if realm.isEmpty {
            showLoaderWith(message: "Загрузка")
            DataManager.shared.updateCache {
                self.stopAnimating()
                self.rootView.reloadData()
            }
        }
        
        self.tabBarItem = UITabBarItem(title: "Books", image: nil, tag: 1)
        
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
                                               selector: #selector(handlePurchaseStateChange(notification:)),
                                               name: SubscriptionService.restoreSuccessfulNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePurchaseStateChange(notification:)),
                                               name: SubscriptionService.restoreFailedNotification,
                                               object: nil)
    }
    
    func handlePurchaseStateChange(notification: Notification) {
        self.rootView.reloadData()
    }

    @IBAction func refreshDB(_ sender: Any) {
        showLoaderWith(message: "Загрузка")
        DataManager.shared.updateCache {
            self.stopAnimating()
            self.rootView.reloadData()
        }
    }
    
    func setupNavigationBar() {
        tabBarController?.tabBar.tintColor = UIColor(red: 250, green: 251, blue: 245, alpha: 1)
        navigationController?.navigationBar.tintColor = UIColor(red: 250, green: 251, blue: 245, alpha: 1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.rootView.reloadData()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let category = realm.objects(CategoryModel.self).filter("name = %@", categoryName).first
        return category?.subcategory.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        cell.textLabel?.textColor = UIColor.black
        
        let category = realm.objects(CategoryModel.self).filter("name = %@", categoryName).first
        cell.textLabel?.text = category?.subcategory[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        
        if (indexPath.row != 0) {
            guard let currentSubscription = SubscriptionService.shared.currentSubscription, currentSubscription.isActive else {
                cell.textLabel?.textColor = UIColor.gray
                return cell
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = realm.objects(CategoryModel.self).filter("name = %@", categoryName).first
        let nextCategoryId = category?.subcategory[indexPath.row].id
        
        rootView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let newVC = CategoryViewController()
        //        newVC.currentCategory = nextCategory
        newVC.currentCategoryId = nextCategoryId!
        
        if (indexPath.row != 0) {
            guard let currentSubscription = SubscriptionService.shared.currentSubscription, currentSubscription.isActive else {
                let alert = UIAlertController(title: "Ошибка", message: "Необходимо приобрести подписку либо восстановить имеющуюся в разделе Пользователь", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
        }

        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        print("encodeRestorableState root")
        coder.encode(categoryName, forKey: "categoryName")
        
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        print("decodeRestorableState root")
        if let string = coder.decodeObject(forKey: "categoryName") as? String {
            self.categoryName = string
        }
        
        super.decodeRestorableState(with: coder)
    }
    
//    override func applicationFinishedRestoringState() {
//        currentPet = MatchedPetsManager.sharedManager.petForId(petId)
//    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
