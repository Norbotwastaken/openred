//
//  WebHandler.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import Foundation
import Erik
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
//        view = webView
        
        let url = URL(string: "https://old.reddit.com/r/all")!
        webView.load(URLRequest(url: url))
        
//        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()",
//                                   completionHandler: { (html: Any?, error: Error?) in
//            print(html)
//        })
    }
}

class WebHandler {
//    var titles: [String] = []
//    lazy var titles: [String] = {
//        browse()
//    }()
    var doc: Document?
    var title: String
    
    init() {
        self.title = "default title value"
        browse()
//        self.doc
    }
}

extension WebHandler {
    func browse() {
        Erik.visit(url: URL(string: "https://old.reddit.com/r/all")! ) { object, error in
            if let document = object {
                self.title = document.title!
                self.doc = document
            }
        }
    }
}
