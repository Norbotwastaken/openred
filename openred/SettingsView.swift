//
//  SettingsView.swift
//  openred
//
//  Created by Norbert Antal on 8/14/23.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var popupViewModel: PopupViewModel
    var themes = ["automatic", "light", "dark"]
    @State private var selectedTheme = "automatic"
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
                        }
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
                .listStyle(.sidebar)
            }
            .task {
                selectedTheme = settingsModel.theme
                upvoteOnSave = settingsModel.upvoteOnSave
                reverseSwipeControls = settingsModel.reverseSwipeControls
                lockApp = settingsModel.lockApp
                textSizeSliderValue = Float(settingsModel.textSize)
            }
        }
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
