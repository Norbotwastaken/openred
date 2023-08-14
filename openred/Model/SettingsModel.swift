//
//  SettingsModel.swift
//  openred
//
//  Created by Norbert Antal on 8/14/23.
//

import Foundation

class SettingsModel: ObservableObject {
    @Published var theme: String = "automatic"
    private var userSessionManager: UserSessionManager
    
    init(userSessionManager: UserSessionManager) {
        self.userSessionManager = userSessionManager
        loadDefaults()
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
    
    func removeUser(_ userName: String) {
        userSessionManager.removeAccount(userName)
        objectWillChange.send()
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
}
