//
//  LoginPopup.swift
//  openred
//
//  Created by Norbert Antal on 6/13/23.
//

import Foundation
import SwiftUI
import AppTrackingTransparency
import ApphudSDK

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
                Rectangle()
                    .fill(Color(UIColor.systemGray6))
                    .cornerRadius(15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Image(systemName: "xmark")
                    .font(.system(size: 25))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .opacity(0.6)
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 0))
                    .onTapGesture {
                        if !waitingLoginResponse {
                            loginPopupShowing = false
                        }
                    }
                VStack {
                    Text("Log in to reddit")
                        .font(.system(size: 34) .bold())
                        .opacity(0.9)
                        .padding(EdgeInsets(top: 55, leading: 30, bottom: 0, trailing: 30))
                        .frame(alignment: .top)
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFieldFocused)
                            .textFieldStyle(.roundedBorder)
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
                                .fill(Color.themeColor)
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
                    .disabled(waitingLoginResponse)
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
            TrackingConsentView(loginPopupShowing: $loginPopupShowing,
                                waitingLoginResponse: $waitingLoginResponse)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
    private func submitForm() {
        guard username.isEmpty == false && password.isEmpty == false else { return }
        isFieldFocused = false
        waitingLoginResponse = true
        model.login(username: username, password: password)
        settingsModel.loadProduct()
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
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var messageModel: MessageModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @Binding var loginPopupShowing: Bool
    @Binding var waitingLoginResponse: Bool
    @State var promotePremiumView: Bool = false
    @State private var showSubscriptionAlert = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                if promotePremiumView {
                    Spacer().frame(height: 60)
                    Text("""
        Try 1 month of Premium for free.
        """)
                    .font(.system(size: 42))
                    .fontWeight(.heavy)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    Text("Only \(settingsModel.premiumPrice)/month after. Cancel anytime.")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fontWeight(.semibold)
                    Text(.init("""
Make most of OpenRed with **ad-free** browsing and premium features, like seamless account switching and FaceID lock. Offer only available if you haven't tried Premium before.
"""))
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    VStack {
                        Text("Start Free Trial")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 10, leading: 70, bottom: 10, trailing: 70))
                            .foregroundColor(.white)
                            .background(Color.openRed)
                            .cornerRadius(8)
                            .padding()
                            .onTapGesture {
                                showSubscriptionAlert = true
                            }
                            .alert("OpenRed Premium", isPresented: $showSubscriptionAlert) {
                                Button("Cancel", role: .cancel) { showSubscriptionAlert = false }
                                Button("Subcribe") {
                                    showSubscriptionAlert = false
                                    purchasePremium()
                                }.keyboardShortcut(.defaultAction)
                            } message: {
                                Text("""
                                OpenRed Premium Subscription will automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period (and charged to your iTunes account). You can turn off auto-renew/manage subscriptions in your iTunes Account Settings after purchase. Price of subscription is \(settingsModel.premiumPrice) monthly.\nTerms of Use can be found at https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ and Privacy Policy can be found at https://www.openredinc.com/privacy-policy.html
                                """)
                            }
                        Text("Not now")
                            .foregroundColor(Color.themeColor)
                            .onTapGesture {
                                loginPopupShowing = false
                            }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                } else {
                    Spacer().frame(height: 60)
                    Text("""
Help us keep OpenRed free by allowing us to use your online activity and share it with partners.
""")
                    .font(.system(size: 30))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    Text(.init("""
On the next screen **Choose 'Allow'** to see ads that are more interesting and relevant to you. This does not affect the number of ads presented to you and helps us provide the app for free. App tracking data does not include information about your identity and your choices can be changed at any time in your system settings under the OpenRed tab.
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
                        .cornerRadius(8)
                        .padding()
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .onTapGesture {
                            ATTrackingManager.requestTrackingAuthorization { status in
                                switch status {
                                case .authorized:
                                    print("enable tracking")
                                case .denied:
                                    overlayModel.show("Tracking disabled")
                                    print("disable tracking")
                                default:
                                    overlayModel.show("Tracking disabled")
                                    print("disable tracking")
                                }
                                settingsModel.disableUserConsent()
                                waitingLoginResponse = false
                                messageModel.openInbox(filter: "inbox", forceLoad: true)
                                if settingsModel.premiumProduct != nil && settingsModel.eligibleForTrial {
                                    promotePremiumView = true
                                } else {
                                    loginPopupShowing = false
                                }
                            }
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
    
    func purchasePremium() {
        if settingsModel.premiumProduct != nil {
            Task { @MainActor in
                let result = await Apphud
                    .purchase(settingsModel.premiumProduct!)
                if result.success {
                    loginPopupShowing = false
                    settingsModel.hasPremium = true
                }
            }
        }
    }
}
