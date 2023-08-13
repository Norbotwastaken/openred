//
//  openredApp.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI

@main
class openredApp: App {
    var userSessionManager: UserSessionManager
    @StateObject private var model: Model
    @StateObject var popupViewModel = PopupViewModel()
    @StateObject var messageOverlayModel = MessageOverlayModel()
    @StateObject var commentsModel: CommentsModel
    @StateObject var postCreateModel: PostCreateModel
    @StateObject var messageModel: MessageModel
    @StateObject var searchModel: SearchModel = SearchModel()
    
    required init() {
        userSessionManager = UserSessionManager()
        _model = StateObject(wrappedValue: Model(userSessionManager: self.userSessionManager))
        _commentsModel = StateObject(wrappedValue: CommentsModel(userSessionManager: self.userSessionManager))
        _postCreateModel = StateObject(wrappedValue: PostCreateModel(userSessionManager: self.userSessionManager))
        _messageModel = StateObject(wrappedValue: MessageModel(userSessionManager: self.userSessionManager))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model)
                .environmentObject(popupViewModel)
                .environmentObject(messageOverlayModel)
                .environmentObject(commentsModel)
                .environmentObject(postCreateModel)
                .environmentObject(messageModel)
                .environmentObject(searchModel)
        }
    }
}
