//
//  openredApp.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI

@main
class openredApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var userSessionManager: UserSessionManager
//    @State var community: CommunityOrUser = CommunityOrUser(community: Community("joerogan", iconName: nil, isMultiCommunity: false))
    @StateObject private var model: Model
    @StateObject var popupViewModel = PopupViewModel()
    @StateObject var messageOverlayModel = MessageOverlayModel()
    @StateObject var commentsModel: CommentsModel
    @StateObject var postCreateModel: PostCreateModel
    @StateObject var messageModel: MessageModel
    @StateObject var searchModel: SearchModel = SearchModel()
    @StateObject var settingsModel: SettingsModel
    @StateObject var messageCreateModel: MessageCreateModel
    
    required init() {
        userSessionManager = UserSessionManager()
        _model = StateObject(wrappedValue: Model(userSessionManager: self.userSessionManager))
        _commentsModel = StateObject(wrappedValue: CommentsModel(userSessionManager: self.userSessionManager))
        _postCreateModel = StateObject(wrappedValue: PostCreateModel(userSessionManager: self.userSessionManager))
        _messageModel = StateObject(wrappedValue: MessageModel(userSessionManager: self.userSessionManager))
        _settingsModel = StateObject(wrappedValue: SettingsModel(userSessionManager: self.userSessionManager))
        _messageCreateModel = StateObject(wrappedValue: MessageCreateModel(userSessionManager: self.userSessionManager))
        
//        _community = State(initialValue: userSessionManager.getHomePageCommunity())
    }
    
    var body: some Scene {
        WindowGroup {
//            ContentView(target: $community)
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
//                .task {
//                    self.community = self.userSessionManager.getHomePageCommunity()
//                }
        }
    }
}
