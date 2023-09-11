//
//  LoginPopup.swift
//  openred
//
//  Created by Norbert Antal on 6/13/23.
//

import Foundation
import SwiftUI
import AppTrackingTransparency

struct LoginPopup: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var messageModel: MessageModel
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var waitingLoginResponse: Bool = false
    @State private var failedAttemptIndicatorShowing: Bool = false
    @State private var privacyPromptShowing: Bool = false
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
//                            .preferredColorScheme(.dark)
//                            .colorInvert()
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
//                            .preferredColorScheme(.dark)
//                            .colorInvert()
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
        .fullScreenCover(isPresented: $privacyPromptShowing) {
            TrackingConsentView(loginPopupShowing: $loginPopupShowing, waitingLoginResponse: $waitingLoginResponse)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
    private func submitForm() {
        guard username.isEmpty == false && password.isEmpty == false else { return }
        isFieldFocused = false
        waitingLoginResponse = true
        model.login(username: username, password: password)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if model.loginAttempt == .successful {
                if settingsModel.askTrackingConsent {
                    privacyPromptShowing = true
                } else {
                    loginPopupShowing = false
                    waitingLoginResponse = false
                    messageModel.openInbox(filter: "inbox", forceLoad: true)
                }
            } else if model.loginAttempt == .failed {
                failedAttemptIndicatorShowing = true
                waitingLoginResponse = false
                isFieldFocused = true
            }
        }
    }
}

struct TrackingConsentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var messageModel: MessageModel
    @Binding var loginPopupShowing: Bool
    @Binding var waitingLoginResponse: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                Spacer().frame(height: 60)
                Text("""
Help us keep OpenRed free by allowing us to use your online activity and share it with partners.
""")
                .font(.system(size: 30) .bold())
                .frame(maxWidth: .infinity, alignment: .topLeading)
                Text(.init("""
**Choose 'Allow'** to see ads that are more interesting and relevant to you. This does not affect the number of ads presented to you and helps us provide the app for free. App tracking data does not include information about your identity and your choices can be changed at any time in your system settings.
"""))
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                Text("Continue")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .padding(EdgeInsets(top: 10, leading: 70, bottom: 10, trailing: 70))
                    .foregroundColor(.white)
                    .background(Color.openRed)
//                    .background(Color(UIColor.systemBlue))
                    .cornerRadius(8)
                    .padding()
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .onTapGesture {
                        ATTrackingManager.requestTrackingAuthorization { status in
                            switch status {
                            case .authorized:
                                print("enable tracking")
                            case .denied:
                                print("disable tracking")
                            default:
                                print("disable tracking")
                            }
                            settingsModel.disableUserConsent()
                            loginPopupShowing = false
                            waitingLoginResponse = false
                            dismiss()
                            messageModel.openInbox(filter: "inbox", forceLoad: true)
                        }
                    }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        .ignoresSafeArea()
        .frame(maxHeight: .infinity)
        .background(Color(UIColor.systemGray6))
    }
}
