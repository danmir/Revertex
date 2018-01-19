//
//  PasswordResetViewController.swift
//  revertex
//
//  Created by Danil Mironov on 12.01.18.
//  Copyright © 2018 Danil Mironov. All rights reserved.
//

import UIKit
import Parse
import SwiftSpinner

class PasswordResetViewController: CommonViewController {
    
    @IBOutlet weak var txtUser: UITextField!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var backButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        restoreButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        
        SwiftSpinner.setTitleFont(UIFont(name: "SFUIDisplay-Regular", size: 16))
    }
    
    func validateUserResetEntry() -> Bool {
        var valid = true
        var message = ""
        if txtUser.text == "" {
            valid = false
            message = "Введите email."
        }
        
        if !valid {
            let alert = UIAlertController(title: "Введите email для восстановления", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return false
        }
        
        return true
    }
    
    @IBAction func btnResetPressed(_ sender: UIButton) {
        guard validateUserResetEntry() else { return }
        
        view.endEditing(true)
        
//        showLoaderWith(message: "Загрузка")
        SwiftSpinner.show("Загрузка")
        
        PFUser.requestPasswordResetForEmail(inBackground: txtUser.text!) {
            [unowned self]  (success, error) in
//            self.stopAnimating()
            SwiftSpinner.hide()
            if !success {
                self.showAlertWith(title: "Ошибка", text: (error?.localizedDescription)!)
            } else {
                let alert = UIAlertController(title: "Восстановление", message: "На ваш email было отправлено письмо для восстановления пароля", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func btnBackPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
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
