//
//  CommonView.swift
//  revertex
//
//  Created by Danil Mironov on 19.01.18.
//  Copyright © 2018 Danil Mironov. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class CommonViewController: UIViewController, NVActivityIndicatorViewable {
    func showAlertWith(title: String, text: String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func showLoaderWith(message: String) {
        startAnimating(CGSize(width: 50, height: 50), message: message, messageFont: UIFont(name: "SFUIDisplay-Regular", size: 16), type: NVActivityIndicatorType.ballClipRotate, textColor: UIColor(red: 0.985148*255, green: 0.689696*255, blue: 0.233962*255, alpha: 1))
    }
}
