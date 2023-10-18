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
    @Binding var loginPopupShowing: Bool
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
                        AppearanceSettingsView()
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "eye.square")
                                .foregroundColor(.white)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                                .background(Color(red: 20 / 255, green: 27 / 255, blue: 44 / 255))
                                .cornerRadius(8)
                                .font(.system(size: 26))
                                Text("Appearance")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3))
                    }
                    NavigationLink {
                        GesturesSettingsView()
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "hand.draw")
                                .foregroundColor(.white)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                                .background(Color(red: 25 / 255, green: 49 / 255, blue: 110 / 255))
                                .cornerRadius(8)
                                .font(.system(size: 26))
                                Text("Swipe Actions")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3))
                    }
                    NavigationLink {
                        BuyPremiumView()
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "star.square")
                                .foregroundColor(.white)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                                .background(Color.openRed)
                                .cornerRadius(8)
                                .font(.system(size: 26))
                            VStack {
                                Text("OpenRed Premium")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if settingsModel.eligibleForTrial {
                                    Text("Start Free Trial")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
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
                            .tint(Color.themeColor)
                            .onChange(of: lockApp) { _ in
                                settingsModel.setLockApp(lockApp)
                            }
                            .disabled(!settingsModel.hasPremium)
                    }
                    Section(header: Label("Accounts".uppercased(), systemImage: "person.2")) {
                        if settingsModel.userNames.isEmpty {
                            Section(content: {
                                Button(action: {
                                    loginPopupShowing = true
                                }) {
                                    Text("Log In")
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            })
                        }
                        ForEach(settingsModel.userNames, id: \.self) { userName in
                            NavigationLink {
                                UserSettingsView(userName: userName, tabSelection: $tabSelection, showPosts: $showPosts)
                            } label: {
                                Text(userName)
                            }
                        }
                    }
                    NavigationLink {
                        AboutSettingsView()
                    } label: {
                        Text("About")
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
    @State var isPurchasing = false
    @State private var showSubscriptionAlert = false
    
    var body: some View {
        VStack {
            List {
                PremiumFeatureView(iconName: "square.text.square",
                                   color: Color(red: 41 / 255, green: 41 / 255, blue: 41 / 255),
                                   title: "Ad-free Experience",
                                   description: "Browse without interruptions from ads within the OpenRed app.")
                PremiumFeatureView(iconName: "person.2",
                                   color: Color(red: 41 / 255, green: 41 / 255, blue: 41 / 255),
                                   title: "Multiple Accounts",
                                   description: "Add multiple accounts to browse and comment from.")
                PremiumFeatureView(iconName: "faceid",
                                   color: Color(red: 41 / 255, green: 41 / 255, blue: 41 / 255),
                                   title: "FaceID & Passcode",
                                   description: "For added security, require passcode or FaceID scan to unlock the app.")
                PremiumFeatureView(iconName: "app.gift",
                                   color: Color(red: 41 / 255, green: 41 / 255, blue: 41 / 255),
                                   title: "Custom App Icons",
                                   description: "Choose one of our custom artwork designs to personalise" +
                                   " the app icon on your home screen.")
                PremiumFeatureView(iconName: "paintbrush.fill",
                                   color: Color(red: 41 / 255, green: 41 / 255, blue: 41 / 255),
                                   title: "Color Themes",
                                   description: "Customize the colors of the comments section.")
            }
            if settingsModel.hasPremium {
                VStack {
                    Divider()
                    HStack {
                        Text(.init("**Renews on** " + Apphud.subscription()!.expiresDate
                            .formatted(date: .abbreviated, time: .omitted)))
                        .lineLimit(1)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                        if Apphud.subscription()!.canceledAt != nil {
                            Text("Cancelled")
                                .foregroundColor(.secondary)
                                .frame(alignment: .trailing)
                                .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .frame(maxWidth: .infinity, maxHeight: 80, alignment: .bottom)
            } else {
                VStack {
                    Divider()
                    Text(settingsModel.premiumPrice + "/month")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    Button {
                        showSubscriptionAlert = true
                    } label: {
                        Text(settingsModel.eligibleForTrial ? "Start Free Trial" : "Upgrade to Premium")
                            .padding(EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 30))
                            .background(Color.themeColor)
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
                    }
                    .alert("OpenRed Premium", isPresented: $showSubscriptionAlert) {
                        Button("Cancel", role: .cancel) { showSubscriptionAlert = false }
                        Button("Subscribe") {
                            showSubscriptionAlert = false
                            purchasePremium()
                        }.keyboardShortcut(.defaultAction)
                    } message: {
                        Text("""
                            OpenRed Premium Subscription will automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period (and charged to your iTunes account). You can turn off auto-renew/manage subscriptions in your iTunes Account Settings after purchase. Price of subscription is \(settingsModel.premiumPrice) monthly.\nTerms of Use can be found at https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ and Privacy Policy can be found at https://www.openredinc.com/privacy-policy.html
                            """)
                    }
                }
                .background(Color(UIColor.systemBackground))
                .frame(maxWidth: .infinity, maxHeight: 80, alignment: .bottom)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("OpenRed Premium")
                        .font(.headline)
                    if settingsModel.eligibleForTrial {
                        Text("Free for the first month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    func purchasePremium() {
        if settingsModel.premiumProduct != nil {
            Task { @MainActor in
                let result = await Apphud
                    .purchase(settingsModel.premiumProduct!, isPurchasing: $isPurchasing)
                if result.success {
                    settingsModel.hasPremium = true
                }
            }
        }
    }
}

struct PremiumFeatureView: View {
    var iconName: String
    var color: Color
    var title: String
    var description: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .foregroundColor(.white)
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .background(color)
                .cornerRadius(12)
                .font(.system(size: 40))
            VStack(spacing: 8) {
                Text(title)
                    .fontWeight(.bold)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(description)
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
//        VStack() {
//            Text(userName)
//                .font(.title)
//                .fontWeight(.semibold)
//                .padding()
//                .frame(maxWidth: .infinity, alignment: .leading)
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
            .navigationTitle(Text(userName))
//        }
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @State private var showHomePageAlert = false
    @State private var upvoteOnSave = false
    @State private var unmuteVideos = false
    @State private var showNSFW = false
    @State private var homePage = "*"
    @State private var customHomePage = ""
    @State var communityCollectionsShowing: Bool = false
    
    private var communities: [String:String] = [
        "r/all":"All",
        "":"Home",
        "r/popular":"Popular",
        "*":"Custom"
    ]
    
    var body: some View {
        List {
            Section(content: {
                Picker("Home Page", selection: $homePage) {
                    ForEach(communities.sorted(by: >), id: \.key) { key, value in
                        if key == "*" && customHomePage != "" {
                            Text(customHomePage)
                                .lineLimit(1)
                        } else if key == "*" {
                            Text(value)
                        } else {
                            Text(value)
                        }
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: homePage) { _ in
                    if homePage == "*" {
                        showHomePageAlert = true
                    } else {
                        settingsModel.setHomePage(homePage)
                        customHomePage = ""
                    }
                }
                .alert("Home Page", isPresented: $showHomePageAlert) {
                    TextField("Community name", text: $customHomePage)
                    Button("Done", action: {
                        settingsModel.setHomePage(customHomePage)
                        showHomePageAlert = false
                    })
                } message: {
                    Text("Enter the name of the subreddit to set as home page.")
                }
            }, footer: {
                Text("Select a community to load on app startup.")
            })
            if settingsModel.userSessionManager.userName != nil {
                Section(content: {
                    Text("Manage Community Collections")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            communityCollectionsShowing = true
                        }
                }, footer: {
                    Text("Create and manage collections of communities (or multireddits).")
                })
            }
            Section(content: {
                Toggle("Upvote items on save", isOn: $upvoteOnSave)
                    .tint(Color.themeColor)
                    .onChange(of: upvoteOnSave) { _ in
                        settingsModel.setUpvoteOnSave(upvoteOnSave)
                    }}, footer: {
                        Text("Automatically upvote posts and comments when saving them.")
                    })
            Section(content: {
                Toggle("Unmute videos", isOn: $unmuteVideos)
                    .tint(Color.themeColor)
                    .onChange(of: unmuteVideos) { _ in
                        settingsModel.setUnmuteVideos(unmuteVideos)
                    }}, footer: {
                        Text("Play videos with the sound on by default.")
                    })
            Section(content: {
                Toggle("Show NSFW content", isOn: $showNSFW)
                    .tint(Color.themeColor)
                    .onChange(of: showNSFW) { _ in
                        settingsModel.setShowNSFW(showNSFW)
                    }}, footer: {
                        Text("Display NSFW media without blur.")
                    })
        }
        .listStyle(.insetGrouped)
        .navigationTitle("General")
        .task {
            upvoteOnSave = settingsModel.upvoteOnSave
            unmuteVideos = settingsModel.unmuteVideos
            showNSFW = settingsModel.showNSFW
            if settingsModel.homePage == "" {
                homePage = ""
            } else if ["all", "popular"].contains(settingsModel.homePage.lowercased()) {
                homePage = "r/" + settingsModel.homePage.lowercased()
            } else {
                customHomePage = settingsModel.homePage
                homePage = "*"
            }
        }
        .popover(isPresented: $communityCollectionsShowing) {
            CommunityCollectionView(target: nil, communityCollectionsShowing: $communityCollectionsShowing)
        }
    }
}

struct AboutSettingsView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @State private var sendCrashLogs = false
    @State private var showPrivacyPolicyAlert = false
    @State private var showCacheClearAlert = false
    @State var showSafari: Bool = false
    
    var body: some View {
        VStack {
            List {
                Section(content: {
                    Text("Terms of Use")
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            showSafari = true
                        }
                    Text("Privacy Policy")
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            showPrivacyPolicyAlert = true
                        }
                        .alert("Privacy Policy", isPresented: $showPrivacyPolicyAlert) {
                            Button("Done") { showPrivacyPolicyAlert = false }
                                .keyboardShortcut(.defaultAction)
                        } message: {
                            Text("""
All personal data used by OpenRed is stored on your device only and is never synced to a cloud service or remote server. OpenRed does not store your passwords for any of your reddit accounts. The app may only collect data about your browsing activity with your explicit permission. Such data is anonymous and may be used for advertising purposes. To opt in or out of personalized advertising you can update your preferences in the Settings app on your device ('Allow Tracking' under OpenRed tab). Ads may be served using Google's advertising technologies, the details of which can be found at https://policies.google.com/technologies/ads. The app may send crash reports to help improve your user experience. Data in crash reports are anonymized and are only sent with your permission. OpenRed uses reddit.com to serve content. Policies and rules maintained by reddit also apply within the OpenRed app and are available at https://www.redditinc.com/policies/all.
""")
                        }
                }, footer: {
                    Text("With any questions or feature requests please contact contact@openredinc.com")
                })
                .fullScreenCover(isPresented: $showSafari) {
                    SFSafariViewWrapper(url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }
                Section(content: {
                    Toggle("Send crash logs", isOn: $sendCrashLogs)
                        .tint(Color.themeColor)
                        .onChange(of: sendCrashLogs) { _ in
                            settingsModel.setSendCrashReports(sendCrashLogs)
                        }} , footer: {
                            Text("Help improve OpenRed by sending anonymous error logs.")
                        })
                Section(content: {
                    Text("Clear Caches")
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            settingsModel.clearCache()
                            showCacheClearAlert = true
                        }
                        .alert("Cached data removed", isPresented: $showCacheClearAlert) {
                            Button("Done") { showCacheClearAlert = false }
                                .keyboardShortcut(.defaultAction)
                        }
                }, footer: {
                    Text("Remove cached data to reduce the on disk size of the app.")
                })
            }
            .listStyle(.insetGrouped)
            .navigationTitle("About")
            .task {
                sendCrashLogs = settingsModel.sendCrashReports
            }
            Text("OpenRed version \(settingsModel.appVersion)")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .padding()
        }
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    var themes = ["automatic", "light", "dark"]
    var accentColors = ["red", "blue"]
    @State private var selectedTheme = "automatic"
    @State private var selectedAccentColor = "red"
    @State private var selectedCommentTheme = "default"
    @State private var selectedAppIcon = "deafult"
    @State private var textSizeSliderValue : Float = 0.0
    @State private var initialized: Bool = false
    @State private var compactMode = false
    @State private var compactModeReverse = false
    
    var body: some View {
        List {
            Section(content: {
                Toggle("Compact mode", isOn: $compactMode)
                    .tint(Color.themeColor)
                    .onChange(of: compactMode) { _ in
                        settingsModel.setCompactMode(compactMode)
                    }
                if compactMode {
                    Toggle("Reverse layout", isOn: $compactModeReverse)
                        .tint(Color.themeColor)
                        .onChange(of: compactModeReverse) { _ in
                            settingsModel.setCompactModeReverse(compactModeReverse)
                        }
                }
            }, footer: {
                Text("View posts in your feed in a compact format.")
            })
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
            Picker("Accent color", selection: $selectedAccentColor) {
                ForEach(accentColors, id: \.self) {
                    Text($0.capitalized)
                }
            }.onChange(of: selectedAccentColor) { _ in
                settingsModel.setAccentColor(selectedAccentColor)
            }
            .pickerStyle(.inline)
            .disabled(!settingsModel.hasPremium)
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
            Picker("App icon", selection: $selectedAppIcon) {
                ForEach(AppIcons.appIconsArray) { appIcon in
                    HStack {
                        Image(uiImage: appIcon.icon)
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text(appIcon.id.capitalized)
                    }
                }
            }.onChange(of: selectedAppIcon) { _ in
                if initialized {
                    settingsModel.setAppIcon(AppIcons.appIcons[selectedAppIcon]!)
                }
            }
            .pickerStyle(.inline)
            .disabled(!settingsModel.hasPremium)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appearance")
        .task {
            selectedTheme = settingsModel.theme
            textSizeSliderValue = Float(settingsModel.textSize)
            selectedCommentTheme = settingsModel.commentTheme
            selectedAppIcon = settingsModel.appIcon
            selectedAccentColor = settingsModel.accentColor
            compactMode = settingsModel.compactMode
            compactModeReverse = settingsModel.compactModeReverse
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                initialized = true
            }
        }
    }
}

struct GesturesSettingsView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @State private var commentLeftPrimary = "upvote"
    @State private var commentLeftSecondary = "downvote"
    @State private var commentRightPrimary = "collapse"
    @State private var commentRightSecondary = "reply"
    @State private var postLeftPrimary = "upvote"
    @State private var postLeftSecondary = "downvote"
    @State private var postRightPrimary = "noAction"
    @State private var postRightSecondary = "noAction"
//    @State private var swipeBack: Bool = false
    
    var body: some View {
        List {
//            Section(content: {
//                Toggle("Swipe to navigate", isOn: $swipeBack)
//                    .tint(Color.themeColor)
//                    .onChange(of: swipeBack) { _ in
//                        settingsModel.setSwipeBack(swipeBack)
//                    }
//            }, footer: {
//                Text("Swipe from anywhere in the screen to navigate backwards. "
//                     + "This disables all other swipe actions.")
//            })
            Section(content: {
                Picker("Left Primary Action", selection: $commentLeftPrimary) {
                    ForEach(SwipeAction.commentActions, id: \.self) { item in
                        Text(item == "noAction" ? "Do Nothing" : item.capitalized)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: commentLeftPrimary) { _ in
                    settingsModel.setCommentLeftPrimary(SwipeAction(rawValue: commentLeftPrimary)
                                                        ?? SwipeAction.upvote)
                }
                Picker("Left Secondary Action", selection: $commentLeftSecondary) {
                    ForEach(SwipeAction.commentActions, id: \.self) { item in
                        Text(item == "noAction" ? "Do Nothing" : item.capitalized)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: commentLeftSecondary) { _ in
                    settingsModel.setCommentLeftSecondary(SwipeAction(rawValue: commentLeftSecondary)
                                                        ?? SwipeAction.downvote)
                }
                Picker("Right Primary Action", selection: $commentRightPrimary) {
                    ForEach(SwipeAction.commentActions, id: \.self) { item in
                        Text(item == "noAction" ? "Do Nothing" : item.capitalized)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: commentRightPrimary) { _ in
                    settingsModel.setCommentRightPrimary(SwipeAction(rawValue: commentRightPrimary)
                                                        ?? SwipeAction.collapse)
                }
                Picker("Right Secondary Action", selection: $commentRightSecondary) {
                    ForEach(SwipeAction.commentActions, id: \.self) { item in
                        Text(item == "noAction" ? "Do Nothing" : item.capitalized)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: commentRightSecondary) { _ in
                    settingsModel.setCommentRightSecondary(SwipeAction(rawValue: commentRightSecondary)
                                                        ?? SwipeAction.reply)
                }
            },
            header: {
                Text("Comment Swipe Actions")
            },
            footer: {
                Text("Actions to perform when swiping left or right on a comment.")
            })
//            .disabled(swipeBack)
            Section(content: {
                Picker("Left Primary Action", selection: $postLeftPrimary) {
                    ForEach(SwipeAction.postActions, id: \.self) { item in
                        Text(item == "noAction" ? "Do Nothing" : item.capitalized)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: postLeftPrimary) { _ in
                    settingsModel.setPostLeftPrimary(SwipeAction(rawValue: postLeftPrimary)
                                                        ?? SwipeAction.upvote)
                }
                Picker("Left Secondary Action", selection: $postLeftSecondary) {
                    ForEach(SwipeAction.postActions, id: \.self) { item in
                        Text(item == "noAction" ? "Do Nothing" : item.capitalized)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: postLeftSecondary) { _ in
                    settingsModel.setPostLeftSecondary(SwipeAction(rawValue: postLeftSecondary)
                                                        ?? SwipeAction.downvote)
                }
                Picker("Right Primary Action", selection: $postRightPrimary) {
                    ForEach(SwipeAction.postActions, id: \.self) { item in
                        Text(item == "noAction" ? "Do Nothing" : item.capitalized)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: postRightPrimary) { _ in
                    settingsModel.setPostRightPrimary(SwipeAction(rawValue: postRightPrimary)
                                                        ?? SwipeAction.noAction)
                }
                Picker("Right Secondary Action", selection: $postRightSecondary) {
                    ForEach(SwipeAction.postActions, id: \.self) { item in
                        Text(item == "noAction" ? "Do Nothing" : item.capitalized)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: postRightSecondary) { _ in
                    settingsModel.setPostRightSecondary(SwipeAction(rawValue: postRightSecondary)
                                                        ?? SwipeAction.noAction)
                }
            },
            header: {
                Text("Post Swipe Actions")
            },
            footer: {
                Text("Actions to perform when swiping left or right on a post.")
            })
//            .disabled(swipeBack)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Swipe Actions")
        .task {
            commentLeftPrimary = settingsModel.commentLeftPrimary.rawValue
            commentLeftSecondary = settingsModel.commentLeftSecondary.rawValue
            commentRightPrimary = settingsModel.commentRightPrimary.rawValue
            commentRightSecondary = settingsModel.commentRightSecondary.rawValue
            postLeftPrimary = settingsModel.postLeftPrimary.rawValue
            postLeftSecondary = settingsModel.postLeftSecondary.rawValue
            postRightPrimary = settingsModel.postRightPrimary.rawValue
            postRightSecondary = settingsModel.postRightSecondary.rawValue
//            swipeBack = settingsModel.swipeBack
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
            Color(red: 0 / 255, green: 87 / 255, blue: 183 / 255),
            Color(red: 225 / 255, green: 221 / 255, blue: 0 / 255),
            Color(red: 63 / 255, green: 153 / 255, blue: 252 / 255),
            Color(red: 240 / 255, green: 164 / 255, blue: 65 / 255),
            Color(red: 88 / 255, green: 135 / 255, blue: 43 / 255),
            Color(red: 0 / 255, green: 66 / 255, blue: 37 / 255),
            Color(red: 2 / 255, green: 60 / 255, blue: 110 / 255)
        ]),
        Theme(id: "sunset", name: "Sunset", colors: [
            Color(red: 160 / 255, green: 58 / 255, blue: 148 / 255),
            Color(red: 199 / 255, green: 78 / 255, blue: 134 / 255),
            Color(red: 202 / 255, green: 105 / 255, blue: 87 / 255),
            Color(red: 204 / 255, green: 149 / 255, blue: 84 / 255),
            Color(red: 204 / 255, green: 180 / 255, blue: 114 / 255),
            Color(red: 114 / 255, green: 148 / 255, blue: 204 / 255),
            Color(red: 53 / 255, green: 104 / 255, blue: 188 / 255)
        ]),
        Theme(id: "redvapor", name: "Red Vapor", colors: [
            Color(red: 191 / 255, green: 45 / 255, blue: 45 / 255),
            Color(red: 204 / 255, green: 83 / 255, blue: 83 / 255),
            Color(red: 204 / 255, green: 118 / 255, blue: 125 / 255),
            Color(red: 204 / 255, green: 90 / 255, blue: 138 / 255),
            Color(red: 186 / 255, green: 113 / 255, blue: 182 / 255),
            Color(red: 146 / 255, green: 71 / 255, blue: 186 / 255),
            Color(red: 64 / 255, green: 51 / 255, blue: 123 / 255)
        ]),
        Theme(id: "amphibian", name: "Amphibian", colors: [
            Color(red: 50 / 255, green: 67 / 255, blue: 169 / 255),
            Color(red: 63 / 255, green: 102 / 255, blue: 181 / 255),
            Color(red: 17 / 255, green: 164 / 255, blue: 162 / 255),
            Color(red: 63 / 255, green: 179 / 255, blue: 146 / 255),
            Color(red: 141 / 255, green: 186 / 255, blue: 138 / 255),
            Color(red: 101 / 255, green: 85 / 255, blue: 171 / 255)
        ]),
//        Theme(id: "vibrant", name: "Vibrant", colors: [
//            Color(red: 91 / 255, green: 206 / 255, blue: 250 / 255),
//            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//            Color(red: 1, green: 1, blue: 1),
//            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//            Color(red: 91 / 255, green: 206 / 255, blue: 250 / 255),
//            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//            Color(red: 1, green: 1, blue: 1),
//            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255)
//        ]),
        Theme(id: "coastal", name: "Coastal", colors: [
            Color(red: 17 / 255, green: 104 / 255, blue: 132 / 255),
            Color(red: 195 / 255, green: 107 / 255, blue: 12 / 255),
            Color(red: 181 / 255, green: 70 / 255, blue: 188 / 255),
            Color(red: 90 / 255, green: 63 / 255, blue: 202 / 255),
            Color(red: 8 / 255, green: 61 / 255, blue: 147 / 255),
            Color(red: 94 / 255, green: 170 / 255, blue: 192 / 255)
        ]),
        Theme(id: "orchard", name: "Orchard", colors: [
            Color(red: 204 / 255, green: 160 / 255, blue: 91 / 255),
            Color(red: 161 / 255, green: 70 / 255, blue: 150 / 255),
            Color(red: 94 / 255, green: 26 / 255, blue: 117 / 255),
            Color(red: 66 / 255, green: 57 / 255, blue: 154 / 255),
            Color(red: 0 / 255, green: 117 / 255, blue: 184 / 255),
            Color(red: 158 / 255, green: 184 / 255, blue: 122 / 255)
        ])
    ]
    
    static var themes: [String:Theme] {
        var themes: [String:Theme] = [:]
        for theme in themesArray {
            var colors = theme.colors
            colors.append(contentsOf: theme.colors)
            themes[theme.id] = Theme(id: theme.id, name: theme.name, colors: colors)
        }
        return themes
    }
    
    struct Theme: Identifiable, Hashable {
        var id: String
        var name: String
        var colors: [Color]
    }
}

struct AppIcons {
    static let appIconsArray: [AppIcon] = [
        AppIcon(id: "default", iconName: nil, displayImageName: "appicon-thumb"),
        AppIcon(id: "black", iconName: "AppIcon-Black", displayImageName: "appicon-black-thumb"),
        AppIcon(id: "floral", iconName: "AppIcon-Floral", displayImageName: "appicon-floral-thumb")
    ]
    
    static var appIcons: [String:AppIcon] {
        var icons: [String:AppIcon] = [:]
        for icon in appIconsArray {
            icons[icon.id] = AppIcon(id: icon.id, iconName: icon.iconName,
                                     displayImageName: icon.displayImageName)
        }
        return icons
    }
    
    struct AppIcon: Identifiable, Hashable {
        var id: String
        var iconName: String?
        var displayImageName: String?
        
        var icon: UIImage {
            return UIImage(named: displayImageName ?? iconName ?? "AppIcon") ?? UIImage()
        }
    }
}

enum SwipeAction: String, Identifiable {
    case upvote = "upvote"
    case downvote = "downvote"
    case save = "save"
    case reply = "reply"
    case collapse = "collapse"
    case hide = "hide"
    case noAction = "noAction"
    
    static let commentActions = ["upvote", "downvote", "save",
    "reply", "collapse", "noAction"]
    static let postActions = ["upvote", "downvote", "save", "hide", "noAction"]
    
    var id: String { return self.rawValue }
}
