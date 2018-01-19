//
//  PageViewController.swift
//  revertex
//
//  Created by Danil Mironov on 25.07.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import UIKit
import WebKit
import SwiftSpinner

class PageViewController: CommonViewController, WKUIDelegate, WKNavigationDelegate {

    var webView: WKWebView!
    
    var currentContentId = ""
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        restorationIdentifier = "PageViewController"
        restorationClass = PageViewController.self
        
        if (currentContentId != "") {
            loadPage()
        }
        
        SwiftSpinner.setTitleFont(UIFont(name: "SFUIDisplay-Regular", size: 16))
    }
    
    func loadPage() {
        let viewPort = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
        let html1 = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n\t<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"2\">\n\t\t<tbody><tr>\n\t\t\t\t\t<td width=\"100%\" valign=\"top\">\n\t\t\t\t\t\t\t</td>\n\t\t</tr>\n\t</tbody></table>\n\t\t\t\t\t\t\t\t<br>\n\t\t\t<br><iframe width=\"100%\" src=\"https://www.youtube.com/embed/ZTliB0O3gGU\" frameborder=\"0\" allowfullscreen></iframe><br>\n\t\t\t\t\t\t<br><a href=\"/courses/?SECTION_ID=177\"></a>\n\t"
        let baseURL = URL(string: "http://profit.revertex.ru")
        
        SwiftSpinner.show("Загрузка страницы")
        DataManager.shared.getContentBy(id: currentContentId) {html in
            if let html = html {
                self.webView.loadHTMLString(viewPort + html, baseURL: nil)
            } else {
                SwiftSpinner.hide()
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось загрузить материал. Попробуйте еще раз.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        SwiftSpinner.hide()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        SwiftSpinner.hide()
        showAlertWith(title: "Ошибка", text: "Не удалось загрузить материал. Попробуйте еще раз.")
        self.navigationController?.popViewController(animated: true)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        SwiftSpinner.hide()
        showAlertWith(title: "Ошибка", text: "Не удалось загрузить материал. Попробуйте еще раз.")
        self.navigationController?.popViewController(animated: true)
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

extension PageViewController: UIViewControllerRestoration {
    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        let vc = PageViewController()
        return vc
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        print("encodeRestorableState page")
        coder.encode(currentContentId, forKey: "currentContentId")
        
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        print("decodeRestorableState page")
        if let string = coder.decodeObject(forKey: "currentContentId") as? String {
            self.currentContentId = string
        }
        
        super.decodeRestorableState(with: coder)
    }
    
    override func applicationFinishedRestoringState() {
        loadPage()
    }
}
