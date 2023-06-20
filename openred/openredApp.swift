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
    @StateObject var commentsModel: CommentsModel
    
    required init() {
        userSessionManager = UserSessionManager()
        _model = StateObject(wrappedValue: Model(userSessionManager: self.userSessionManager))
        _commentsModel = StateObject(wrappedValue: CommentsModel(userSessionManager: self.userSessionManager))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model)
                .environmentObject(popupViewModel)
                .environmentObject(commentsModel)
        }
    }
}
