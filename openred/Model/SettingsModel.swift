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
import Bugsnag

class SettingsModel: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var theme: String = "automatic"
    var products: [Product] = []
    @Published var premiumProduct: Product?
    @Published var hasPremium: Bool = false
    @Published var eligibleForTrial: Bool = false
    @Published var appVersion: String
    @Published var firstLoad: Bool = true
    @Published var launchCount: Int = 1
    var userSessionManager: UserSessionManager
    var askTrackingConsent: Bool = false
//    private var premiumPromotionAttempts: Int = 0
    
    init(userSessionManager: UserSessionManager) {
        self.userSessionManager = userSessionManager
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        loadDefaults()
        NotificationCenter.default.addObserver(self, selector: #selector(self.lock(notification:)),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.unlock(notification:)),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        if !sendCrashReports {
            Bugsnag.pauseSession()
        }
//        Task { @MainActor in
//            products = try await Apphud.fetchProducts()
//        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.loadProduct()
            if Apphud.hasActiveSubscription() {
                self.hasPremium = true
            } else {
                self.resetPremiumFeatures()
            }
        }
        if firstLoad && [2, 10, 20].contains(launchCount) {
            if let scene = UIApplication.shared.connectedScenes.first(where: {$0.activationState == .foregroundActive}) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
    
    func loadProduct() {
        Task { @MainActor in
//            products = try await Product.products(for: ["Premium"])
            products = try await Apphud.fetchProducts()
            let skProducts = await Apphud.fetchSKProducts()
            if !products.isEmpty {
                premiumProduct = products[0]
                if !skProducts.isEmpty {
                    Apphud.checkEligibilityForIntroductoryOffer(product: skProducts[0]) { isEligible in
                        self.eligibleForTrial = isEligible
//                        if isEligible {
//                            if (self.launchCount > 1 && self.premiumPromotionAttempts < 1) ||
//                                (self.launchCount > 10 && self.premiumPromotionAttempts < 2) ||
//                                (self.launchCount > 25 && self.premiumPromotionAttempts < 3) {
//                                userSessionManager.promotePremium = true
//                            }
//                        }
                    }
                }
            }
        }
    }
    
    func loadDefaults() {
        if let launchCounter = UserDefaults.standard.object(forKey: "launchCounter") as? Int {
            if launchCounter < 100 {
                launchCount = launchCounter + 1
                UserDefaults.standard.set(launchCounter + 1, forKey: "launchCounter")
            }
        } else {
            UserDefaults.standard.set(1, forKey: "launchCounter")
        }
        
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
        
        if let savedAppIcon = UserDefaults.standard.object(forKey: "appIcon") as? String {
            userSessionManager.appIcon = savedAppIcon
        } else {
            UserDefaults.standard.set(userSessionManager.appIcon, forKey: "appIcon")
        }
        
        if let savedSendCrashReports = UserDefaults.standard.object(forKey: "sendCrashReports") as? Bool {
            userSessionManager.sendCrashReports = savedSendCrashReports
        } else {
            UserDefaults.standard.set(userSessionManager.sendCrashReports, forKey: "sendCrashReports")
        }
        
        if let savedShowNSFW = UserDefaults.standard.object(forKey: "showNSFW") as? Bool {
            userSessionManager.showNSFW = savedShowNSFW
        } else {
            UserDefaults.standard.set(userSessionManager.showNSFW, forKey: "showNSFW")
        }
        
        if let savedAccentColor = UserDefaults.standard.object(forKey: "accentColor") as? String {
            userSessionManager.accentColor = savedAccentColor
        } else {
            UserDefaults.standard.set(userSessionManager.accentColor, forKey: "accentColor")
        }
        
        if let savedHomePage = UserDefaults.standard.object(forKey: "homePage") as? String {
            userSessionManager.homePage = savedHomePage
        } else {
            UserDefaults.standard.set(userSessionManager.homePage, forKey: "homePage")
        }
        
        if let savedCompactMode = UserDefaults.standard.object(forKey: "compactMode") as? Bool {
            userSessionManager.compactMode = savedCompactMode
        } else {
            UserDefaults.standard.set(userSessionManager.compactMode, forKey: "compactMode")
        }
        
        if let savedCompactModeReverse = UserDefaults.standard.object(forKey: "compactModeReverse") as? Bool {
            userSessionManager.compactModeReverse = savedCompactModeReverse
        } else {
            UserDefaults.standard.set(userSessionManager.compactModeReverse, forKey: "compactModeReverse")
        }
        
//        if let savedSwipeBack = UserDefaults.standard.object(forKey: "swipeBack") as? Bool {
//            userSessionManager.swipeBack = savedSwipeBack
//        } else {
//            UserDefaults.standard.set(userSessionManager.swipeBack, forKey: "swipeBack")
//        }
        
        if let askTrackingConsent = UserDefaults.standard.object(forKey: "askTrackingConsent") as? Bool {
            self.askTrackingConsent = askTrackingConsent
        } else {
            UserDefaults.standard.set(true, forKey: "askTrackingConsent")
            self.askTrackingConsent = true
        }
        
        /// Comment Swipe Actions
        if let savedCommentLeftPrimary = UserDefaults.standard.object(forKey: "commentLeftPrimary") as? String {
            userSessionManager.commentLeftPrimary = SwipeAction(rawValue: savedCommentLeftPrimary) ?? .upvote
        } else {
            UserDefaults.standard.set(userSessionManager.commentLeftPrimary.rawValue, forKey: "commentLeftPrimary")
        }
        
        if let savedCommentLeftSecondary = UserDefaults.standard.object(forKey: "commentLeftSecondary") as? String {
            userSessionManager.commentLeftSecondary = SwipeAction(rawValue: savedCommentLeftSecondary) ?? .downvote
        } else {
            UserDefaults.standard.set(userSessionManager.commentLeftSecondary.rawValue, forKey: "commentLeftSecondary")
        }
        
        if let savedCommentRightPrimary = UserDefaults.standard.object(forKey: "commentRightPrimary") as? String {
            userSessionManager.commentRightPrimary = SwipeAction(rawValue: savedCommentRightPrimary) ?? .collapse
        } else {
            UserDefaults.standard.set(userSessionManager.commentRightPrimary.rawValue, forKey: "commentRightPrimary")
        }
        
        if let savedCommentRightSecondary = UserDefaults.standard.object(forKey: "commentRightSecondary") as? String {
            userSessionManager.commentRightSecondary = SwipeAction(rawValue: savedCommentRightSecondary) ?? .reply
        } else {
            UserDefaults.standard.set(userSessionManager.commentRightSecondary.rawValue, forKey: "commentRightSecondary")
        }
        
        /// Post Swipe Actions
        if let savedPostLeftPrimary = UserDefaults.standard.object(forKey: "postLeftPrimary") as? String {
            userSessionManager.postLeftPrimary = SwipeAction(rawValue: savedPostLeftPrimary) ?? .upvote
        } else {
            UserDefaults.standard.set(userSessionManager.postLeftPrimary.rawValue, forKey: "postLeftPrimary")
        }
        
        if let savedPostLeftSecondary = UserDefaults.standard.object(forKey: "postLeftSecondary") as? String {
            userSessionManager.postLeftSecondary = SwipeAction(rawValue: savedPostLeftSecondary) ?? .downvote
        } else {
            UserDefaults.standard.set(userSessionManager.postLeftSecondary.rawValue, forKey: "postLeftSecondary")
        }
        
        if let savedPostRightPrimary = UserDefaults.standard.object(forKey: "postRightPrimary") as? String {
            userSessionManager.postRightPrimary = SwipeAction(rawValue: savedPostRightPrimary) ?? .noAction
        } else {
            UserDefaults.standard.set(userSessionManager.postRightPrimary.rawValue, forKey: "postRightPrimary")
        }
        
        if let savedPostRightSecondary = UserDefaults.standard.object(forKey: "postRightSecondary") as? String {
            userSessionManager.postRightSecondary = SwipeAction(rawValue: savedPostRightSecondary) ?? .noAction
        } else {
            UserDefaults.standard.set(userSessionManager.postRightSecondary.rawValue, forKey: "postRightSecondary")
        }
        
        if let savedAdLastPresented = UserDefaults.standard.object(forKey: "adLastPresented") as? [Date] {
            userSessionManager.adLastPresented = savedAdLastPresented
        } else {
            UserDefaults.standard.set(userSessionManager.adLastPresented, forKey: "adLastPresented")
        }
        
        if let savedBlockedCommunities = UserDefaults.standard.object(forKey: "blockedCommunities") as? [String] {
            userSessionManager.blockedCommunities = savedBlockedCommunities
        } else {
            UserDefaults.standard.set([String](), forKey: "blockedCommunities")
        }
        
//        if let premiumPromotionAttempts = UserDefaults.standard.object(forKey: "premiumPromotionAttempts") as? Int {
//            self.premiumPromotionAttempts = premiumPromotionAttempts
//        } else {
//            UserDefaults.standard.set(0, forKey: "premiumPromotionAttempts")
//        }
    }
    
    func setTheme(_ newTheme: String) {
        theme = newTheme
        UserDefaults.standard.set(newTheme, forKey: "theme")
    }
    
    func setUpvoteOnSave(_ newValue: Bool) {
        userSessionManager.upvoteOnSave = newValue
        UserDefaults.standard.set(newValue, forKey: "upvoteOnSave")
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
    
    func setSendCrashReports(_ newValue: Bool) {
        userSessionManager.sendCrashReports = newValue
        UserDefaults.standard.set(newValue, forKey: "sendCrashReports")
    }
    
    func setShowNSFW(_ newValue: Bool) {
        userSessionManager.showNSFW = newValue
        UserDefaults.standard.set(newValue, forKey: "showNSFW")
    }
    
    func setAppIcon(_ newAppIcon: AppIcons.AppIcon) {
        userSessionManager.appIcon = newAppIcon.id
        UserDefaults.standard.set(newAppIcon.id, forKey: "appIcon")
        UIApplication.shared.setAlternateIconName(newAppIcon.iconName)
    }
    
    func removeUser(_ userName: String) {
        userSessionManager.removeAccount(userName)
        objectWillChange.send()
    }
    
    func setAccentColor(_ newValue: String) {
        userSessionManager.accentColor = newValue
        UserDefaults.standard.set(newValue, forKey: "accentColor")
    }
    
    func setHomePage(_ newValue: String) {
        userSessionManager.homePage = newValue.hasPrefix("r/") ? newValue : "r/" + newValue
        UserDefaults.standard.set(userSessionManager.homePage, forKey: "homePage")
    }
    
    func setCompactMode(_ newValue: Bool) {
        userSessionManager.compactMode = newValue
        UserDefaults.standard.set(newValue, forKey: "compactMode")
    }
    
    func setCompactModeReverse(_ newValue: Bool) {
        userSessionManager.compactModeReverse = newValue
        UserDefaults.standard.set(newValue, forKey: "compactModeReverse")
    }
    
    func setSwipeBack(_ newValue: Bool) {
        userSessionManager.swipeBack = newValue
        UserDefaults.standard.set(newValue, forKey: "swipeBack")
    }
    
    /// Comment Swipe Actions
    func setCommentLeftPrimary(_ newValue: SwipeAction) {
        userSessionManager.commentLeftPrimary = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "commentLeftPrimary")
    }
    
    func setCommentLeftSecondary(_ newValue: SwipeAction) {
        userSessionManager.commentLeftSecondary = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "commentLeftSecondary")
    }
    
    func setCommentRightPrimary(_ newValue: SwipeAction) {
        userSessionManager.commentRightPrimary = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "commentRightPrimary")
    }
    
    func setCommentRightSecondary(_ newValue: SwipeAction) {
        userSessionManager.commentRightSecondary = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "commentRightSecondary")
    }
    
    /// Post Swipe Actions
    func setPostLeftPrimary(_ newValue: SwipeAction) {
        userSessionManager.postLeftPrimary = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "postLeftPrimary")
    }
    
    func setPostLeftSecondary(_ newValue: SwipeAction) {
        userSessionManager.postLeftSecondary = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "postLeftSecondary")
    }
    
    func setPostRightPrimary(_ newValue: SwipeAction) {
        userSessionManager.postRightPrimary = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "postRightPrimary")
    }
    
    func setPostRightSecondary(_ newValue: SwipeAction) {
        userSessionManager.postRightSecondary = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "postRightSecondary")
    }
    
    func disableUserConsent() {
        UserDefaults.standard.set(false, forKey: "askTrackingConsent")
        self.askTrackingConsent = false
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
        setAccentColor("red")
//        setAppIcon(AppIcons.appIcons["default"]!)
    }
    
    func clearCache() {
        let cacheURL =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileManager = FileManager.default
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default
                .contentsOfDirectory( at: cacheURL, includingPropertiesForKeys: nil, options: [])
            for file in directoryContents {
                do {
                    try fileManager.removeItem(at: file)
                }
                catch let error as NSError {
                    debugPrint("Ooops! Something went wrong: \(error)")
                }

            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func shouldPresentAd() -> Bool {
        if hasPremium || userSessionManager.hasRedditPremium || firstLoad || launchCount < 3 {
            return false
        }
        if userSessionManager.adLastPresented.count >= 2 {
            let lastTimes = userSessionManager.adLastPresented
                .sorted(by: { $0.compare($1) == .orderedDescending})
            
            return lastTimes[1] < Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
             && lastTimes[0] < Calendar.current.date(byAdding: .minute, value: -8, to: Date())!
        } else {
            return true
        }
    }
    
    var userNames: [String] {
        self.userSessionManager.userNames
    }
    
    var upvoteOnSave: Bool {
        self.userSessionManager.upvoteOnSave
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
    
    var appIcon: String {
        self.userSessionManager.appIcon
    }
    
    var sendCrashReports: Bool {
        self.userSessionManager.sendCrashReports
    }
    
    var showNSFW: Bool {
        self.userSessionManager.showNSFW
    }
    
    var accentColor: String {
        self.userSessionManager.accentColor
    }
    
    var homePage: String {
        var homePage = self.userSessionManager.homePage
        if homePage.hasPrefix("r/") {
            return String(homePage.dropFirst(2))
        }
        return homePage
    }
    
    var compactMode: Bool {
        self.userSessionManager.compactMode
    }
    
    var compactModeReverse: Bool {
        self.userSessionManager.compactModeReverse
    }
    
    var swipeBack: Bool {
        self.userSessionManager.swipeBack
    }
    
    var commentLeftPrimary: SwipeAction {
        self.userSessionManager.commentLeftPrimary
    }
    
    var commentLeftSecondary: SwipeAction {
        self.userSessionManager.commentLeftSecondary
    }
    
    var commentRightPrimary: SwipeAction {
        self.userSessionManager.commentRightPrimary
    }
    
    var commentRightSecondary: SwipeAction {
        self.userSessionManager.commentRightSecondary
    }
    
    var postLeftPrimary: SwipeAction {
        self.userSessionManager.postLeftPrimary
    }
    
    var postLeftSecondary: SwipeAction {
        self.userSessionManager.postLeftSecondary
    }
    
    var postRightPrimary: SwipeAction {
        self.userSessionManager.postRightPrimary
    }
    
    var postRightSecondary: SwipeAction {
        self.userSessionManager.postRightSecondary
    }
    
    var blockedCommunities: [String] {
        self.userSessionManager.blockedCommunities
    }
    
    var premiumPrice: String {
        self.premiumProduct?.displayPrice ?? "$1.99"
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Bugsnag.start()
        Apphud.start(apiKey: "app_NPZii7qKMuWaBpkuhtixcSqYNL4rND")
        if Apphud.hasActiveSubscription() {

        }
        else {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
        return true
    }
}
