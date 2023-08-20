//
//  SettingsView.swift
//  openred
//
//  Created by Norbert Antal on 8/14/23.
//

import SwiftUI
import ApphudSDK

struct SettingsView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var popupViewModel: PopupViewModel
    var themes = ["automatic", "light", "dark"]
    var commentThemes = ["default", "fields"]
    @State private var selectedTheme = "automatic"
    @State private var selectedCommentTheme = "default"
    @State private var profileViewIsActive = false
    @State private var upvoteOnSave = false
    @State private var reverseSwipeControls = false
    @State private var lockApp = false
    @State private var textSizeSliderValue : Float = 0.0
    
    var body: some View {
        NavigationView {
            VStack() {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                List {
                    if !settingsModel.hasPremium {
                        Section() {
                            NavigationLink {
                                BuyPremiumView()
                            } label: {
                                Text("Upgrade to premium")
                            }
                        }
                    }
                    Section(header: Label("General".uppercased(), systemImage: "gear")
                        .font(.system(size: 16))) {
                            Toggle("Upvote items on save", isOn: $upvoteOnSave)
                                .onChange(of: upvoteOnSave) { _ in
                                    settingsModel.setUpvoteOnSave(upvoteOnSave)
                                }
                            Toggle("Invert swipe actions", isOn: $reverseSwipeControls)
                                .onChange(of: reverseSwipeControls) { _ in
                                    settingsModel.setReverseSwipeControls(reverseSwipeControls)
                                }
                        }
                    Section(header: Label("Appearence".uppercased(), systemImage: "eye")
                        .font(.system(size: 16))) {
                            Picker("Theme", selection: $selectedTheme) {
                                ForEach(themes, id: \.self) {
                                    Text($0.capitalized)
                                }
                            }.onChange(of: selectedTheme) { _ in
                                settingsModel.setTheme(selectedTheme)
                            }
                            .pickerStyle(.inline)
                            VStack {
                                Text("Text size")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Slider(value: $textSizeSliderValue, in: 1...5) {
                                    Text("Text size")
                                } minimumValueLabel: {
                                    Text("Small").fontWeight(.thin)
                                } maximumValueLabel: {
                                    Text("Large").fontWeight(.thin)
                                }
                                .onChange(of: textSizeSliderValue) { _ in
                                    settingsModel.setTextSize(textSizeSliderValue)
                                }
                            }
                            Picker("Comment color theme", selection: $selectedCommentTheme) {
                                ForEach(commentThemes, id: \.self) {
                                    Text($0.capitalized)
                                }
                            }.onChange(of: selectedCommentTheme) { _ in
                                settingsModel.setCommentTheme(selectedCommentTheme)
                            }
                            .pickerStyle(.inline)
                        }
                    if settingsModel.hasPremium {
                        Section(header: Label("Privacy".uppercased(), systemImage: "faceid").font(.system(size: 16)),
                                footer: Text("If Face ID, Touch ID or system passcode " +
                                             "is set, you will be requested to unlock the app when opening.")) {
                            Toggle("Application lock", isOn: $lockApp)
                                .onChange(of: lockApp) { _ in
                                    settingsModel.setLockApp(lockApp)
                                }
                        }
                        Section(header: Label("Accounts".uppercased(), systemImage: "person.2")
                            .font(.system(size: 16))) {
                                ForEach(settingsModel.userNames, id: \.self) { userName in
                                    NavigationLink {
                                        UserSettingsView(userName: userName)
                                    } label: {
                                        Text(userName)
                                    }
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
            }
            .task {
                selectedTheme = settingsModel.theme
                upvoteOnSave = settingsModel.upvoteOnSave
                reverseSwipeControls = settingsModel.reverseSwipeControls
                lockApp = settingsModel.lockApp
                textSizeSliderValue = Float(settingsModel.textSize)
                selectedCommentTheme = settingsModel.commentTheme
            }
        }
    }
}

struct BuyPremiumView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @Environment(\.dismiss) var dismiss
    @State var isPurchasing = false
    
    var body: some View {
        ZStack {
            List {
                PremiumFeatureView(iconName: "square.text.square",
                                   color: Color(UIColor.systemRed),
                                   title: "Ad-free Experience",
                                   dedscription: "Enjoy browsing without interruptions from advertisements.")
                PremiumFeatureView(iconName: "person",
                                   color: Color(UIColor.systemGreen),
                                   title: "Multiple Accounts",
                                   dedscription: "Add multiple accounts to browse and comment from.")
                PremiumFeatureView(iconName: "faceid",
                                   color: Color(UIColor.systemBlue),
                                   title: "FaceID & Passcode",
                                   dedscription: "For added security, require passcode or FaceID scan to unlock OpenRed.")
                PremiumFeatureView(iconName: "app.gift",
                                   color: Color(UIColor.systemGray2),
                                   title: "Custom App Icons",
                                   dedscription: "Choose one of our custom atrwork designs to personalise" +
                                   " the app icon on your home screen.")
            }
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color(UIColor.systemBackground))
                        .frame(maxWidth: .infinity, maxHeight: 150, alignment: .bottom)
                    VStack {
                        Divider()
                        Text(settingsModel.premiumProduct!.displayPrice + " / month")
//                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        Button {
                            purchasePremium()
                        } label: {
                            Text("Upgrade to premium")
                                .padding()
                                .background(Color(UIColor.systemBlue))
                                .cornerRadius(20)
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                        }
                    }
                    .background(Color(UIColor.systemBackground))
//                    .padding()
                    .frame(alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    func purchasePremium() {
        if settingsModel.premiumProduct != nil {
            Task { @MainActor in
                let result = await Apphud.purchase(settingsModel.premiumProduct!, isPurchasing: $isPurchasing)
                if result.success {
                    print("successful purchase.")
                    settingsModel.hasPremium = true
                    dismiss()
                }
            }
        }
    }
}

struct PremiumFeatureView: View {
    var iconName: String
    var color: Color
    var title: String
    var dedscription: String
    var fontSize: Int?
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: iconName)
                .foregroundColor(.white)
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .background(color)
                .cornerRadius(12)
                .font(.system(size: CGFloat(integerLiteral: fontSize ?? 40)))
            VStack(spacing: 8) {
                Text(title)
                    .fontWeight(.bold)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(dedscription)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 8, leading: 5, bottom: 8, trailing: 5))
    }
}

struct UserSettingsView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @Environment(\.dismiss) var dismiss
    var userName: String
    @State private var showingExitAlert = false
    
    var body: some View {
        VStack() {
            Text(userName)
                .font(.title)
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            List {
                Section(content: {
                    Text("Switch to this account")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            model.switchAccountTo(userName: userName)
                            overlayModel.show(duration: 3, loading: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                dismiss()
                            }
                        }
                })
                Section(content: {
                    Text("Remove account")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Color(UIColor.red))
                        .onTapGesture {
                            showingExitAlert = true
                        }
                        .alert("Remove account", isPresented: $showingExitAlert) {
                            Button("Cancel", role: .cancel) { showingExitAlert = false }
                            Button("Remove", role: .destructive) {
                                overlayModel.show(loading: true)
                                if model.userName != nil &&
                                    userName.lowercased() == model.userName!.lowercased() {
                                    model.logOut()
                                }
                                settingsModel.removeUser(userName)
                                showingExitAlert = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    dismiss()
                                }
                            }
                        } message: {
                            Text("Your account will be removed from OpenRed. " +
                                 "You can log in again using your credentials.")
                        }
                }, footer: {
                    Text("Remove your account from the OpenRed app. " +
                         "Your session with this account within the app will be " +
                         "erased and associated settings will be removed. " +
                         "This does not affect your session on other apps and devices. " +
                         "OpenRed does not store your login credentials.")
                })
            }
        }
    }
}
