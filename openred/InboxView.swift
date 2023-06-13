//
//  InboxView.swift
//  openred
//
//  Created by Norbert Antal on 6/13/23.
//

import Foundation
import SwiftUI

struct InboxView: View {
    @EnvironmentObject var model: Model
    @State var loginPopupShowing: Bool = true
    
    var body: some View {
        if model.userName != nil {
            Text("Inbox")
        } else {
            ZStack {
                VStack {
                    Text("Log in to access your inbox.")
                    Button( action: {
                        loginPopupShowing.toggle()
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(Color(UIColor.systemBlue))
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            Text("Log In")
                                .font(.system(size: 18) .bold())
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 150, height: 40, alignment: .top)
                    .padding(EdgeInsets(top: 20, leading: 45, bottom: 0, trailing: 45))
                }
                if loginPopupShowing {
                    LoginPopup(loginPopupShowing: $loginPopupShowing)
                }
            }
        }
    }
}
