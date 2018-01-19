//
//  CategoryModel.swift
//  revertex
//
//  Created by Danil Mironov on 04.08.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import Foundation
import RealmSwift

class RealmString: Object {
    dynamic var stringValue = ""
}

class CategoryModel: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""
    let pages = List<PageModel>()
    let subcategory = List<CategoryModel>()
    
    var pageDescriptions: [String]? {
        get {
            return _backingPageDescriptions.map { $0.stringValue }
        }
        set {
            if newValue?.count != 0 {
                _backingPageDescriptions.removeAll()
                newValue?.forEach { (s: String) in
                    let rs = RealmString()
                    rs.stringValue = s
                    _backingPageDescriptions.append(rs)
                }
                //_backingPageDescriptions.append(newValue.map { RealmString(value: [$0]) }!)
            }
        }
    }
    let _backingPageDescriptions = List<RealmString>()
    
    override static func ignoredProperties() -> [String] {
        return ["pageDescriptions"]
    }
    
//    override static func indexedProperties() -> [String] {
//        return ["id"]
//    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
