//
//  LoginViewController.swift
//  revertex
//
//  Created by Danil Mironov on 28.07.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import UIKit
import Parse
import SwiftSpinner

class LoginViewController: CommonViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    let showDetailSegueIdentifier = "loginSuccessful"
    
    // MARK: - IBOutlets
    @IBOutlet weak var txtUser: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnSignUp: UIButton!
    @IBOutlet weak var btnReset: UIButton!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setupNavigationBar()
        self.hideKeyboardWhenTappedAround()
        self.txtUser.delegate = self
        self.txtPassword.delegate = self
        
        if let user = PFUser.current(), user.isAuthenticated {
            SubscriptionService.shared.restoreSubscriptionCommon()
            performSegue(withIdentifier: showDetailSegueIdentifier, sender: self)
        }
        
        btnLogin.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        btnSignUp.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        btnReset.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        
        SwiftSpinner.setTitleFont(UIFont(name: "SFUIDisplay-Regular", size: 16))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        txtUser.text = ""
        txtPassword.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
            let alert = UIAlertController(title: "Неверный email", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return false
        }
        
        return true
    }
    
    func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = .white
    }
    
    // MARK: - IBActions
    @IBAction func btnLogInPressed(_ sender: UIButton) {
        guard validateUserEntry() else { return }
        
        view.endEditing(true)
        SwiftSpinner.show("Загрузка")
        
        PFUser.logInWithUsername(inBackground: txtUser.text!, password:txtPassword.text!) {
            [unowned self]  (user, error) in
            if user != nil {
                // Если у нас нет активной подписки, то проверяем, есть ли активная подписка на сервере
                guard let subscription = SubscriptionService.shared.currentSubscription, subscription.isActive else {
                    SwiftSpinner.hide()
                    SubscriptionService.shared.restoreSubscriptionServer {
                        (subscription, error) -> Void in
                        SwiftSpinner.hide()
                        if let error = error {
                            self.showAlertWith(title: "Произошла ошибка", text: error)
                            return
                        }
                        self.performSegue(withIdentifier: self.showDetailSegueIdentifier, sender: self)
                    };
                    return
                }
                
                SwiftSpinner.hide()
                self.performSegue(withIdentifier: self.showDetailSegueIdentifier, sender: self)
            } else {
                SwiftSpinner.hide()
                self.showAlertWith(title: "Произошла ошибка.", text: NSLocalizedString((error?.localizedDescription)!, comment: ""))
            }
        }
    }
}
