//
//  LoginPopup.swift
//  openred
//
//  Created by Norbert Antal on 6/13/23.
//

import Foundation
import SwiftUI

struct LoginPopup: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @Binding var loginPopupShowing: Bool
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .opacity(0.75)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray6))
                    .cornerRadius(15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .frame(width: 340, height: 550)
                Image(systemName: "xmark")
                    .font(.system(size: 25))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .opacity(0.6)
//                    .foregroundColor(Color.white)
//                    .colorInvert()
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 0))
                    .onTapGesture {
                        loginPopupShowing = false
                    }
                VStack {
                    Text("Log in to reddit")
                        .font(.system(size: 36) .bold())
                        .opacity(0.9)
                        .padding(EdgeInsets(top: 50, leading: 30, bottom: 0, trailing: 30))
                        .frame(alignment: .top)
                    TextField("Username", text: $username)
                        .focused($isFieldFocused)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.white)
                        .frame(alignment: .top)
                        .padding(EdgeInsets(top: 15, leading: 45, bottom: 0, trailing: 45))
                        .onTapGesture {} // override other onTap
                    SecureField("Password", text: $password)
                        .focused($isFieldFocused)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.white)
                        .frame(alignment: .top)
                        .padding(EdgeInsets(top: 10, leading: 45, bottom: 0, trailing: 45))
                        .onTapGesture {} // override other onTap
                    Button( action: {
                        loginPopupShowing = false
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
            }
            .onTapGesture {
                isFieldFocused = false
            }
            .frame(width: 340, height: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
