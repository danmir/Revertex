//
//  Settings.swift
//  revertex
//
//  Created by Danil Mironov on 17.01.18.
//  Copyright © 2018 Danil Mironov. All rights reserved.
//

import Foundation

public class Settings {
    static let shared = Settings()
    
    public let parseApplicationId: String
    public let parseClientKey: String
    public let parseServer: String
    
    public let testParseApplicationId: String
    public let testParseClientKey: String
    public let testParseServer: String
    
    public let dataUrlIndex: String
    public let dataUrlContent: String
    
    private init() {
        let path = Bundle.main.path(forResource: "Settings", ofType: "plist")!
        let settingsDict = NSDictionary(contentsOfFile: path) as! [String: AnyObject]
        
        parseApplicationId = settingsDict["parseApplicationId"] as! String
        parseClientKey = settingsDict["parseClientKey"] as! String
        parseServer = settingsDict["parseServer"] as! String
        
        testParseApplicationId = settingsDict["testParseApplicationId"] as! String
        testParseClientKey = settingsDict["testParseClientKey"] as! String
        testParseServer = settingsDict["testParseServer"] as! String
        
        dataUrlIndex = settingsDict["dataUrlIndex"] as! String
        dataUrlContent = settingsDict["dataUrlContent"] as! String
    }
}
