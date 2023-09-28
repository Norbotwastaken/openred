//
//  openredApp.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI

@main
class openredApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private var userSessionManager: UserSessionManager = UserSessionManager()
    @StateObject private var model: Model
    @StateObject private var popupViewModel = PopupViewModel()
    @StateObject private var messageOverlayModel = MessageOverlayModel()
    @StateObject private var commentsModel: CommentsModel
    @StateObject private var postCreateModel: PostCreateModel
    @StateObject private var messageModel: MessageModel
    @StateObject private var searchModel: SearchModel = SearchModel()
    @StateObject private var settingsModel: SettingsModel
    @StateObject private var messageCreateModel: MessageCreateModel
    
    required init() {
        _model = StateObject(wrappedValue: Model(userSessionManager: self.userSessionManager))
        _commentsModel = StateObject(wrappedValue: CommentsModel(userSessionManager: self.userSessionManager))
        _postCreateModel = StateObject(wrappedValue: PostCreateModel(userSessionManager: self.userSessionManager))
        _messageModel = StateObject(wrappedValue: MessageModel(userSessionManager: self.userSessionManager))
        _settingsModel = StateObject(wrappedValue: SettingsModel(userSessionManager: self.userSessionManager))
        _messageCreateModel = StateObject(wrappedValue: MessageCreateModel(userSessionManager: self.userSessionManager))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(userSessionManager: userSessionManager)
                .environmentObject(model)
                .environmentObject(popupViewModel)
                .environmentObject(messageOverlayModel)
                .environmentObject(commentsModel)
                .environmentObject(postCreateModel)
                .environmentObject(messageModel)
                .environmentObject(searchModel)
                .environmentObject(settingsModel)
                .environmentObject(messageCreateModel)
                .tint(settingsModel.accentColor == "blue" ? Color(UIColor.systemBlue) : Color.openRed)
        }
    }
}
