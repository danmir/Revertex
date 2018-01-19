//
//  PageModel.swift
//  revertex
//
//  Created by Danil Mironov on 04.08.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import Foundation
import RealmSwift

class PageModel: Object {
    dynamic var id: String = ""
    dynamic var content: String = ""
    dynamic var name: String = ""
    
//    override static func indexedProperties() -> [String] {
//        return ["id"]
//    }
    override static func primaryKey() -> String? {
        return "id"
    }
}
