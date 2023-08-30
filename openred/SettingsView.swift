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
    @Binding var tabSelection: Int
    @Binding var showPosts: Bool
    @State private var lockApp = false
    
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
                        NavigationLink {
                            BuyPremiumView()
                        } label: {
                            HStack(spacing: 15) {
                                Image(systemName: "star.square")
                                    .foregroundColor(.white)
                                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                                    .background(Color(UIColor.systemRed))
                                    .cornerRadius(8)
                                    .font(.system(size: 26))
                                    Text("Upgrade to premium")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                
                            }
                            .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3))
                        }
                    }
                    NavigationLink {
                        GeneralSettingsView()
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                                .background(Color(red: 87 / 255, green: 95 / 255, blue: 115 / 255))
                                .cornerRadius(8)
                                .font(.system(size: 26))
                                Text("General")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3))
                    }
                    NavigationLink {
                        AppearenceSettingsView()
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "eye.square")
                                .foregroundColor(.white)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                                .background(Color(red: 55 / 255, green: 91 / 255, blue: 184 / 255))
                                .cornerRadius(8)
                                .font(.system(size: 26))
                                Text("Appearence")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3))
                    }
                    Section(header:
                        HStack {
                            Label("Privacy".uppercased(), systemImage: "faceid").font(.system(size: 16))
                            if !settingsModel.hasPremium {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                                Text("Premium".uppercased())
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                    .background(Color(UIColor.systemRed).opacity(0.8))
                                    .cornerRadius(5)
                            }
                        }, footer: Text("If Face ID, Touch ID or system passcode " +
                                        "is set, you will be requested to unlock the app when opening.")) {
                        Toggle("Application lock", isOn: $lockApp)
                            .onChange(of: lockApp) { _ in
                                settingsModel.setLockApp(lockApp)
                            }
                            .disabled(!settingsModel.hasPremium)
                    }
                    Section(header: Label("Accounts".uppercased(), systemImage: "person.2")) {
                        ForEach(settingsModel.userNames, id: \.self) { userName in
                            NavigationLink {
                                UserSettingsView(userName: userName, tabSelection: $tabSelection, showPosts: $showPosts)
                            } label: {
                                Text(userName)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .task {
                lockApp = settingsModel.lockApp
            }
        }
    }
}

struct BuyPremiumView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
//    @Environment(\.dismiss) var dismiss
    @State var isPurchasing = false
    
    var body: some View {
        VStack {
            List {
                PremiumFeatureView(iconName: "square.text.square",
                                   color: Color(UIColor.systemRed),
                                   title: "Ad-free Experience",
                                   dedscription: "Browse without interruptions from ads within the OpenRed app.")
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
                                   dedscription: "Choose one of our custom artwork designs to personalise" +
                                   " the app icon on your home screen.")
            }
            ZStack {
                VStack {
                    Divider()
                    Text(settingsModel.premiumProduct!.displayPrice + " / month")
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
                .frame(maxWidth: .infinity, maxHeight: 120, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: 120, alignment: .bottom)
        }
        .navigationTitle("OpenRed Premium")
    }
    
    func purchasePremium() {
        if settingsModel.premiumProduct != nil {
            Task { @MainActor in
                let result = await Apphud.purchase(settingsModel.premiumProduct!, isPurchasing: $isPurchasing)
                if result.success {
                    print("successful purchase.")
                    settingsModel.hasPremium = true
//                    dismiss()
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
    @Binding var tabSelection: Int
    @Binding var showPosts: Bool
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
                    Button(action: {
                        if settingsModel.hasPremium {
                            tabSelection = 1
                            showPosts = false
                            overlayModel.show(duration: 4, loading: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                model.switchAccountTo(userName: userName)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Text("Switch to this account")
                                .lineLimit(1)
                                .foregroundColor(settingsModel.hasPremium ? .primary : .secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if !settingsModel.hasPremium {
                                Text("Premium".uppercased())
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                    .background(Color(UIColor.systemRed).opacity(0.8))
                                    .cornerRadius(5)
                                    .frame(alignment: .trailing)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                })
                Section(content: {
                    Button(action: {
                        showingExitAlert = true
                    }) {
                        Text("Remove account")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(UIColor.red))
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

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @State private var upvoteOnSave = false
    @State private var reverseSwipeControls = false
    @State private var unmuteVideos = false
    
    var body: some View {
        List {
            Section(content: {
                Toggle("Upvote items on save", isOn: $upvoteOnSave)
                    .onChange(of: upvoteOnSave) { _ in
                        settingsModel.setUpvoteOnSave(upvoteOnSave)
                    }} , footer: {
                        Text("Automatically upvote posts and comments when saving them.")
                    })
            Section(content: {
                Toggle("Unmute videos", isOn: $unmuteVideos)
                    .onChange(of: unmuteVideos) { _ in
                        settingsModel.setUnmuteVideos(unmuteVideos)
                    }} , footer: {
                        Text("Play videos with the sound on by default.")
                    })
            Section(content: {
                Toggle("Invert swipe actions", isOn: $reverseSwipeControls)
                    .onChange(of: reverseSwipeControls) { _ in
                        settingsModel.setReverseSwipeControls(reverseSwipeControls)
                    }} , footer: {
                        Text("Invert left and right swipe actions when " +
                             "interacting with comments and posts.")
                    })
        }
        .listStyle(.insetGrouped)
        .navigationTitle("General")
        .task {
            upvoteOnSave = settingsModel.upvoteOnSave
            reverseSwipeControls = settingsModel.reverseSwipeControls
            unmuteVideos = settingsModel.unmuteVideos
        }
    }
}

struct AppearenceSettingsView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    var themes = ["automatic", "light", "dark"]
    @State private var selectedTheme = "automatic"
    @State private var selectedCommentTheme = "default"
    @State private var textSizeSliderValue : Float = 0.0
    
    var body: some View {
        List {
            Picker("Theme", selection: $selectedTheme) {
                ForEach(themes, id: \.self) {
                    Text($0.capitalized)
                }
            }.onChange(of: selectedTheme) { _ in
                settingsModel.setTheme(selectedTheme)
            }
            .pickerStyle(.inline)
            Section(header: Text("Text size")) {
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
                ForEach(Themes.themesArray) { theme in
                    HStack {
                        Text(theme.name)
                        Spacer()
                        HStack {
                            ForEach(theme.colors.indices) { i in
                                if i < 7 {
                                    Circle()
                                        .fill(theme.colors[i])
                                        .opacity(0.8)
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        .frame(alignment: .trailing)
                    }
                }
            }.onChange(of: selectedCommentTheme) { _ in
                settingsModel.setCommentTheme(selectedCommentTheme)
            }
            .pickerStyle(.inline)
            .disabled(!settingsModel.hasPremium)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appearence")
        .task {
            selectedTheme = settingsModel.theme
            textSizeSliderValue = Float(settingsModel.textSize)
            selectedCommentTheme = settingsModel.commentTheme
        }
    }
}

struct Themes {
    static let themesArray: [Theme] = [
        Theme(id: "default", name: "Default", colors: [
            Color(red: 192 / 255, green: 57 / 255, blue: 43 / 255),
            Color(red: 230 / 255, green: 126 / 255, blue: 34 / 255),
            Color(red: 241 / 255, green: 196 / 255, blue: 15 / 255),
            Color(red: 39 / 255, green: 174 / 255, blue: 96 / 255),
            Color(red: 52 / 255, green: 152 / 255, blue: 219 / 255),
            Color(red: 13 / 255, green: 71 / 255, blue: 161 / 255),
            Color(red: 142 / 255, green: 68 / 255, blue: 173 / 255)
        ]),
        Theme(id: "fields", name: "Fields", colors: [
            Color(red: 63 / 255, green: 153 / 255, blue: 252 / 255),
            Color(red: 0 / 255, green: 87 / 255, blue: 183 / 255),
            Color(red: 225 / 255, green: 221 / 255, blue: 0 / 255),
            Color(red: 240 / 255, green: 164 / 255, blue: 65 / 255),
            Color(red: 88 / 255, green: 135 / 255, blue: 43 / 255),
            Color(red: 0 / 255, green: 66 / 255, blue: 37 / 255),
            Color(red: 2 / 255, green: 60 / 255, blue: 110 / 255)
        ]),
        Theme(id: "vibrant", name: "Vibrant", colors: [
            Color(red: 1, green: 0, blue: 24 / 255),
            Color(red: 1, green: 165 / 255, blue: 44 / 255),
            Color(red: 1, green: 1, blue: 65 / 255),
            Color(red: 0, green: 128 / 255, blue: 24 / 255),
            Color(red: 0, green: 0, blue: 249 / 255),
            Color(red: 134 / 255, green: 0, blue: 125 / 255),
            Color(red: 91 / 255, green: 206 / 255, blue: 250 / 255),
            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255)
        ])
    ]
    
    static var themes: [String:Theme] {
        var themes: [String:Theme] = [:]
        for theme in themesArray {
            themes[theme.id] = theme
        }
        return themes
    }
    
    struct Theme: Identifiable, Hashable {
        var id: String
        var name: String
        var colors: [Color]
    }
}

//let vibrant2Theme = [
//    Color(red: 91 / 255, green: 206 / 255, blue: 250 / 255),
//    Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//    Color(red: 1, green: 1, blue: 1),
//    Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//    Color(red: 91 / 255, green: 206 / 255, blue: 250 / 255),
//    Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//    Color(red: 1, green: 1, blue: 1),
//    Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//]
//let amphibianTheme = [
//    Color(red: 116 / 255, green: 237 / 255, blue: 202 / 255),
//    Color(red: 79 / 255, green: 224 / 255, blue: 182 / 255),
//    Color(red: 61 / 255, green: 245 / 255, blue: 242 / 255),
//    Color(red: 21 / 255, green: 205 / 255, blue: 202 / 255),
//    Color(red: 79 / 255, green: 175 / 255, blue: 226 / 255),
//    Color(red: 79 / 255, green: 128 / 255, blue: 226 / 255),
//    Color(red: 62 / 255, green: 84 / 255, blue: 221 / 255)
//]
