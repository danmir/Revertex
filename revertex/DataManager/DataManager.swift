//
//  DataManager.swift
//  revertex
//
//  Created by Danil Mironov on 24.07.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import Foundation
import Alamofire
import JSONHelper
import SwiftyJSON
import RealmSwift

private let _sharedManager = DataManager()

class Category: Deserializable {
    static let idKey = "_id"
    static let nameKey = "name"
    static let pageDescriptionsKey = "page_descriptions"
    static let pagesKey = "pages"
    static let subcategoryKey = "subcategory"
    
    private(set) var id: String?
    private(set) var name: String?
    private(set) var pageDescriptions: Array<String>?
    private(set) var pages: Array<String>?
    private(set) var subcategory: Array<String>?
    
    required init(dictionary: [String : Any]) {
        id <-- dictionary[Category.idKey]
        name <-- dictionary[Category.nameKey]
        pageDescriptions <-- dictionary[Category.pageDescriptionsKey]
        pages <-- dictionary[Category.pagesKey]
        subcategory <-- dictionary[Category.pagesKey]
    }
}

class DataManager {
    class var shared: DataManager {
        return _sharedManager
    }
    
    var categoriesCache: [String: Any] = [:]
    var pagesCache: [String: Any] = [:]
    var rootCategory: [String: Any] = [:]
    
    let realm = try! Realm()
    
    var isSubscribed = false
    
    init() {}
    
    func updateCache(complitionHandler: @escaping () -> ()) -> Void {
        Alamofire.request(Settings.shared.dataUrlIndex).responseJSON { response in
            if let json = response.result.value as? [String: Any] {
                
                // Refill DB
                try! self.realm.write {
                    self.realm.deleteAll()
                }
                
                let json = JSON(json)
                let payload = json["message"].dictionaryValue
                
                let categories = payload["categories"]?.arrayValue
                let pages = payload["pages"]?.arrayValue
                
                pages?.forEach{(page: JSON) in
                    let pageModel = PageModel()
                    pageModel.id = page["_id"].string!
                    pageModel.content = page["content"].string!
                    pageModel.name = page["name"].string!
                    
                    try! self.realm.write {
                        self.realm.add(pageModel)
                    }
                }
                
                categories?.forEach({(category: JSON) in
                    let categoryModel = CategoryModel()
                    categoryModel.id = category["_id"].string!
                    categoryModel.name = category["name"].string!
                    
                    var pageDescriptions: [String] = []
                    category["page_descriptions"].arrayValue.forEach {(pageDescription: JSON) in
                        pageDescriptions.append(pageDescription.stringValue)
                    }
                    categoryModel.pageDescriptions = pageDescriptions
                    
                    category["pages"].arrayValue.forEach {(pageId: JSON) in
                        let categoryPage = self.realm
                            .objects(PageModel.self)
                            .filter("id = %@", pageId.stringValue)
                        categoryModel.pages.append(objectsIn: categoryPage)
                    }
                    
                    try! self.realm.write {
                        self.realm.add(categoryModel)
                    }
                })
                
                // Update references to subcategories
                categories?.forEach({(category: JSON) in
                    let categoryModel = self.realm
                        .objects(CategoryModel.self)
                        .filter("id = %@", category["_id"].stringValue)
                        .first
                    
                    try! self.realm.write {
                        category["subcategory"].arrayValue.forEach {(categoryId: JSON) in
                            let categorySubcategory = self.realm
                                .objects(CategoryModel.self)
                                .filter("id = %@", categoryId.stringValue)
                            categoryModel?.subcategory.append(objectsIn: categorySubcategory)
                        }
                    }
                })

                print("Cache updated")
                complitionHandler()
            }
        }
    }

    
    func getContentBy(id: String, complitionHandler: @escaping (String?) -> ()) -> Void {
        Alamofire.request("\(Settings.shared.dataUrlContent)\(id)").responseJSON { response in
            if let json = response.result.value as? [String: Any] {
                
                let payload = json["message"] as! [String: Any]
                let chunks = payload["chunks"] as! [[String: Any]]
                
                let html = chunks[0]["data"] as! String
                
                complitionHandler(html)
                return
            }
            complitionHandler(nil)
            return
        }
    }
    
    func getCategoryBy(id: String) -> [String: Any] {
        let category = categoriesCache[id] as! [String: Any]
        return category
    }
    
    func getPageBy(id: String) -> [String: Any] {
        let page = pagesCache[id] as! [String: Any]
        return page
    }
    
    func getRootCategory() -> [String: Any] {
        return rootCategory
    }
    
    func getSubcategories(subcategory: [String: Any]) -> Array<String> {
        if let subCategories: Array<String> = subcategory["subcategory"] as? Array {
            return subCategories
        }
        return []
    }
    
    func getRootSubcategories() -> Array<String> {
        let rootCategory = getRootCategory()
        return getSubcategories(subcategory: rootCategory)
    }
    
    func getCategoryPages(category: [String: Any]) -> Array<String> {
        let pages: Array<String> = category["pages"] as! Array
        return pages
    }
}
