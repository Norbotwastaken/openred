//
//  LoginPopup.swift
//  openred
//
//  Created by Norbert Antal on 6/13/23.
//

import Foundation
import SwiftUI

struct LoginPopup: View {
    @EnvironmentObject var model: Model
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var waitingLoginResponse: Bool = false
    @State private var failedAttemptIndicatorShowing: Bool = false
    @Binding var loginPopupShowing: Bool
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .opacity(0.75)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            ZStack {
//                if waitingLoginResponse {
//                    ZStack {
//                        Rectangle()
//                            .fill(Color.white)
//                            .opacity(0.6)
//                            .cornerRadius(15)
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        ProgressView()
//                            .onAppear(perform: {
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//                                    if model.loginAttempt == .successful {
//                                        loginPopupShowing = false
//                                    } else if model.loginAttempt == .failed {
//                                        failedAttemptIndicatorShowing = true
//                                        waitingLoginResponse = false
//                                    }
//                                }
//                            })
//                    }
//                }
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
                        .font(.system(size: 34) .bold())
                        .opacity(0.9)
                        .padding(EdgeInsets(top: 55, leading: 30, bottom: 0, trailing: 30))
                        .frame(alignment: .top)
//                    Form {
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFieldFocused)
                            .textFieldStyle(.roundedBorder)
//                            .foregroundColor(.white)
                            .preferredColorScheme(.dark)
                            .colorInvert()
                            .border(failedAttemptIndicatorShowing ? Color.red : Color.black)
                            .frame(alignment: .top)
                            .padding(EdgeInsets(top: 10, leading: 45, bottom: 0, trailing: 45))
                            .onTapGesture {} // override other onTap
                            .onSubmit {
                                submitForm()
                            }
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFieldFocused)
                            .textFieldStyle(.roundedBorder)
                            .preferredColorScheme(.dark)
                            .colorInvert()
                            .border(failedAttemptIndicatorShowing ? Color.red : Color.black)
                            .frame(alignment: .top)
                            .padding(EdgeInsets(top: 10, leading: 45, bottom: 0, trailing: 45))
                            .onTapGesture {} // override other onTap
//                    }
                    .onSubmit {
                        submitForm()
                    }
                    Button( action: {
                        submitForm()
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(Color(UIColor.systemBlue))
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            if waitingLoginResponse {
                                ProgressView()
                            } else {
                                Text("Log In")
                                    .font(.system(size: 18) .bold())
                            }
                        }
                    }
                    .disabled(waitingLoginResponse)
                    .foregroundColor(.white)
                    .frame(width: 150, height: 40, alignment: .top)
                    .padding(EdgeInsets(top: 20, leading: 45, bottom: 0, trailing: 45))
                    Button("Cancel") {
                        loginPopupShowing = false
                    }
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
            }
            .onTapGesture {
                isFieldFocused = false
            }
            .frame(width: 340, height: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
    private func submitForm() {
        guard username.isEmpty == false && password.isEmpty == false else { return }
        waitingLoginResponse = true
        model.login(username: username, password: password)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if model.loginAttempt == .successful {
                loginPopupShowing = false
            } else if model.loginAttempt == .failed {
                failedAttemptIndicatorShowing = true
                waitingLoginResponse = false
            }
        }
    }
}
