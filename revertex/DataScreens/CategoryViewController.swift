//
//  CategoryViewController.swift
//  revertex
//
//  Created by Danil Mironov on 23.07.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import UIKit
import RealmSwift

class CategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var table: UITableView!
    
    let CellIdentifier = "com.revertex.CategoryTableViewCell"
    
    let realm = try! Realm()
    var currentDBCategory: CategoryModel?
    
    var currentCategory: [String: Any] = [:]
    var subcategoriesCount = 0
    var pagesCount = 0
    
    var currentCategoryId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "CategoryTableViewCell", bundle: nil)
        table.register(cellNib, forCellReuseIdentifier: CellIdentifier)
        table.dataSource = self
        table.delegate = self
        table.estimatedRowHeight = 50
        table.rowHeight = UITableViewAutomaticDimension
        
        self.reloadData()

        // State restoration
        restorationIdentifier = "CategoryViewController"
        restorationClass = CategoryViewController.self
        
        print("current category \(currentCategoryId)")
    }
    
    func reloadData() {
        currentDBCategory = realm
            .objects(CategoryModel.self)
            .filter("id = %@", currentCategoryId)
            .first
        
        subcategoriesCount = currentDBCategory?.subcategory.count ?? 0
        pagesCount = currentDBCategory?.pages.count ?? 0
        title = currentDBCategory?.name
        
        table.reloadData()
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (subcategoriesCount > 0 && pagesCount > 0) {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (subcategoriesCount > 0 && section == 0) {
            return currentDBCategory?.subcategory.count ?? 0
        }
        return currentDBCategory?.pages.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as! CategoryTableViewCell
        cell.accessoryType = .disclosureIndicator
        
        if (subcategoriesCount > 0 && indexPath.section == 0) {
            cell.title?.text = currentDBCategory?.subcategory[indexPath.row].name
            cell.titleDescription?.text = ""
            return cell
        }
        
        cell.title?.text = currentDBCategory?.pages[indexPath.row].name
        cell.titleDescription?.text = currentDBCategory?.pageDescriptions?[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        table.deselectRow(at: indexPath as IndexPath, animated: true)
        
        if (subcategoriesCount > 0 && indexPath.section == 0) {
            let newVC = CategoryViewController()
//            newVC.currentCategory = nextCategory
            newVC.currentCategoryId = (currentDBCategory?.subcategory[indexPath.row].id)!
            self.navigationController?.pushViewController(newVC, animated: true)
            return
        }
        
        let newVC = PageViewController()
        newVC.currentContentId = (currentDBCategory?.pages[indexPath.row].content)!
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (subcategoriesCount == 0 && pagesCount > 0) {
            return "Страницы"
        }
        if (subcategoriesCount > 0 && pagesCount == 0) {
            return "Категории"
        }
        
        if section == 0 {
            return "Категории"
        }
        return "Страницы"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CategoryViewController: UIViewControllerRestoration {
    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        let vc = CategoryViewController()
        return vc
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        print("encodeRestorableState category")
        coder.encode(currentCategoryId, forKey: "currentCategoryId")
        
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        print("decodeRestorableState category")
        if let string = coder.decodeObject(forKey: "currentCategoryId") as? String {
            self.currentCategoryId = string
        }
        
        super.decodeRestorableState(with: coder)
    }
    
    override func applicationFinishedRestoringState() {
        self.reloadData()
    }
}
