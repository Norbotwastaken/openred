//
//  SettingsModel.swift
//  openred
//
//  Created by Norbert Antal on 8/14/23.
//

import Foundation
import LocalAuthentication
import NotificationCenter
import ApphudSDK
import GoogleMobileAds
import StoreKit

class SettingsModel: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var theme: String = "automatic"
    var products: [Product] = []
    @Published var premiumProduct: Product?
    @Published var hasPremium: Bool = false
    private var userSessionManager: UserSessionManager
    
    init(userSessionManager: UserSessionManager) {
        self.userSessionManager = userSessionManager
        loadDefaults()
        NotificationCenter.default.addObserver(self, selector: #selector(self.lock(notification:)),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.unlock(notification:)),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        Task { @MainActor in
//            products = try await Apphud.fetchProducts()
            products = try await Product.products(for: ["premium"])
            if !products.isEmpty {
                premiumProduct = products[0]
            }
        }
        if Apphud.hasActiveSubscription() {
            hasPremium = true
        } else {
            resetPremiumFeatures()
        }
    }
    
    func loadDefaults() {
        if let savedTheme = UserDefaults.standard.object(forKey: "theme") as? String {
            theme = savedTheme
        } else {
            UserDefaults.standard.set(theme, forKey: "theme")
        }
        
        if let savedUpvoteOnSave = UserDefaults.standard.object(forKey: "upvoteOnSave") as? Bool {
            userSessionManager.upvoteOnSave = savedUpvoteOnSave
        } else {
            UserDefaults.standard.set(userSessionManager.upvoteOnSave, forKey: "upvoteOnSave")
        }
        
        if let savedReverseSwipeControls = UserDefaults.standard.object(forKey: "reverseSwipeControls") as? Bool {
            userSessionManager.reverseSwipeControls = savedReverseSwipeControls
        } else {
            UserDefaults.standard.set(userSessionManager.reverseSwipeControls, forKey: "reverseSwipeControls")
        }
        
        if let savedTextSize = UserDefaults.standard.object(forKey: "textSize") as? Int {
            userSessionManager.textSize = savedTextSize
        } else {
            UserDefaults.standard.set(userSessionManager.textSize, forKey: "textSize")
        }
        
        if let savedLockApp = UserDefaults.standard.object(forKey: "lockApp") as? Bool {
            userSessionManager.lockApp = savedLockApp
        } else {
            UserDefaults.standard.set(userSessionManager.lockApp, forKey: "lockApp")
        }
        
        if let savedCommentTheme = UserDefaults.standard.object(forKey: "commentTheme") as? String {
            userSessionManager.commentTheme = savedCommentTheme
        } else {
            UserDefaults.standard.set(userSessionManager.commentTheme, forKey: "commentTheme")
        }
        
        if let savedUnmuteVideos = UserDefaults.standard.object(forKey: "unmuteVideos") as? Bool {
            userSessionManager.unmuteVideos = savedUnmuteVideos
        } else {
            UserDefaults.standard.set(userSessionManager.unmuteVideos, forKey: "unmuteVideos")
        }
    }
    
    func setTheme(_ newTheme: String) {
        theme = newTheme
        UserDefaults.standard.set(newTheme, forKey: "theme")
    }
    
    func setUpvoteOnSave(_ newValue: Bool) {
        userSessionManager.upvoteOnSave = newValue
        UserDefaults.standard.set(newValue, forKey: "upvoteOnSave")
    }
    
    func setReverseSwipeControls(_ newValue: Bool) {
        userSessionManager.reverseSwipeControls = newValue
        UserDefaults.standard.set(newValue, forKey: "reverseSwipeControls")
    }
    
    func setTextSize(_ newValue: Float) {
        userSessionManager.textSize = Int(newValue) - 1
        UserDefaults.standard.set(Int(newValue) - 1, forKey: "textSize")
    }
    
    func setLockApp(_ newValue: Bool) {
        userSessionManager.lockApp = newValue
        UserDefaults.standard.set(newValue, forKey: "lockApp")
    }
    
    func setCommentTheme(_ newValue: String) {
        userSessionManager.commentTheme = newValue
        UserDefaults.standard.set(newValue, forKey: "commentTheme")
    }
    
    func setUnmuteVideos(_ newValue: Bool) {
        userSessionManager.unmuteVideos = newValue
        UserDefaults.standard.set(newValue, forKey: "unmuteVideos")
    }
    
    func removeUser(_ userName: String) {
        userSessionManager.removeAccount(userName)
        objectWillChange.send()
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to unlock the app."

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in

                if success {
                    Task { @MainActor in
                        self.isUnlocked = true
                    }
                } else {
                    // error
                }
            }
        } else {
            // no unlock
        }
    }
    
    @objc private func lock(notification: Notification) {
        if lockApp {
            self.isUnlocked = false
            objectWillChange.send()
        }
    }
    
    @objc private func unlock(notification: Notification) {
        if lockApp {
            authenticate()
        }
    }
    
    func resetPremiumFeatures() {
        setLockApp(false)
        setCommentTheme("default")
    }
    
    var userNames: [String] {
        self.userSessionManager.userNames
    }
    
    var upvoteOnSave: Bool {
        self.userSessionManager.upvoteOnSave
    }
    
    var reverseSwipeControls: Bool {
        self.userSessionManager.reverseSwipeControls
    }
    
    var textSize: Int {
        self.userSessionManager.textSize + 1
    }
    
    var lockApp: Bool {
        self.userSessionManager.lockApp
    }
    
    var commentTheme: String {
        self.userSessionManager.commentTheme
    }
    
    var unmuteVideos: Bool {
        self.userSessionManager.unmuteVideos
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Apphud.start(apiKey: "app_NPZii7qKMuWaBpkuhtixcSqYNL4rND")
        if Apphud.hasActiveSubscription() {
            
        }
        else {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
            // ca-app-pub-3940256099942544/3986624511
        }
        return true
    }
}
