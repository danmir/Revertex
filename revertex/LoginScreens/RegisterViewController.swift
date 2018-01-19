//
//  RegisterViewController.swift
//  revertex
//
//  Created by Danil Mironov on 12.01.18.
//  Copyright © 2018 Danil Mironov. All rights reserved.
//

import UIKit
import Parse
import SwiftSpinner

class RegisterViewController: CommonViewController {
    
    // MARK: - Properties
    let showDetailSegueIdentifier = "signupSuccessful"
    
    @IBOutlet weak var txtUser: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnSignUp: UIButton!
    @IBOutlet weak var backButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        btnSignUp.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        
        SwiftSpinner.setTitleFont(UIFont(name: "SFUIDisplay-Regular", size: 16))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        txtUser.text = ""
        txtPassword.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func validateUserEntry() -> Bool {
        var valid = true
        var message = ""
        if txtUser.text == "" {
            valid = false
            message = "Введите email."
        } else if txtPassword.text == "" {
            valid = false
            message = "Введите пароль."
        }
        
        if !valid {
            showAlertWith(title: "Ошибка валидации", text: message)
            return false
        }
        
        return true
    }
    
    @IBAction func btnSignUpPressed(_ sender: UIButton) {
        guard validateUserEntry() else { return }
        
        let user = PFUser()
        user.username = txtUser.text
        user.email = txtUser.text
        user.password = txtPassword.text
        
        SwiftSpinner.show("Загрузка")
//        showLoaderWith(message: "Загрузка")
        
        user.signUpInBackground { [unowned self] (success, error) in
//            self.stopAnimating()
            SwiftSpinner.hide()
            if success {
                self.performSegue(withIdentifier: self.showDetailSegueIdentifier, sender: self)
            } else {
                self.showAlertWith(title: "Ошибка", text: NSLocalizedString((error?.localizedDescription)!, comment: ""))
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
