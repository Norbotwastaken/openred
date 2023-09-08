//
//  InboxView.swift
//  openred
//
//  Created by Norbert Antal on 6/13/23.
//

import Foundation
import SwiftUI

struct InboxView: View {
    @EnvironmentObject var messageModel: MessageModel
    @EnvironmentObject var model: Model
    @State var loginPopupShowing: Bool = true
    @State var isEditorShowing: Bool = false
    @State var replyToMessage: Message?
    @State var showingBlockAlert: Bool = false
    var types: KeyValuePairs<String, String> {
        return ["inbox": "All",
//                "unread": "Unread",
                "messages": "Messages",
                "comments": "Comment Replies", "selfreply": "Post Replies", "mentions": "Mentions"]
    }
    @State private var type = "inbox"
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationStack() {
            ZStack {
                if !isLoggedIn {
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
                if messageModel.userSessionManager.userName != nil {
                    List {
                        VStack {
                            Picker("Filter Messages", selection: $type) {
                                ForEach(types, id: \.key) { key, value in
                                    Text(value)
                                }
                            }.onChange(of: type) { _ in
                                messageModel.openInbox(filter: type)
                            }
                            .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        ForEach(messageModel.messages) { message in
                            MessageView(message: message, isEditorShowing: $isEditorShowing,
                                        replyToMessage: $replyToMessage, showingBlockAlert: $showingBlockAlert)
                            .listRowInsets(EdgeInsets(top: 8, leading: message.new ? 3 : 15, bottom: 8, trailing: 15))
                            .alert("Block user", isPresented: $showingBlockAlert) {
                                Button("Cancel", role: .cancel) {}
                                Button("Block", role: .destructive) { messageModel.blockUser(message: message) }
                            } message: {
                                Text("\(message.author) will be blocked")
                            }
                        }
                        HStack(spacing: 30) {
                            if messageModel.prevLink != nil {
                                Label("Previous", systemImage: "chevron.left")
                                    .labelStyle(.titleOnly)
                                    .onTapGesture {
                                        messageModel.openInbox(link: messageModel.prevLink)
                                    }
                                    .frame(maxWidth: 80)
                            }
                            if messageModel.nextLink != nil {
                                Label("Next", systemImage: "chevron.right")
                                    .labelStyle(.titleOnly)
                                    .onTapGesture {
                                        messageModel.openInbox(link: messageModel.nextLink)
                                    }
                                    .frame(maxWidth: 80)
                            }
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(EdgeInsets(top: 10, leading: 45, bottom: 10, trailing: 45))
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                    .navigationTitle("Inbox")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(isEditorShowing)
                    .refreshable {
                        messageModel.openInbox(filter: type, forceLoad: true)
                    }
                    if isEditorShowing {
                        MessageEditor(isShowing: $isEditorShowing, replyToMessage: $replyToMessage)
                    }
                }
            }
            .onAppear {
                messageModel.openInbox(filter: type)
                model.messageCount = 0
            }
        }.task {
            isLoggedIn = model.userName != nil
        }
    }
}

struct MessageView: View {
    @EnvironmentObject var messageModel: MessageModel
    @EnvironmentObject var popupViewModel: PopupViewModel
    @ObservedObject var message: Message
    @Binding var isEditorShowing: Bool
    @Binding var replyToMessage: Message?
    @Binding var showingBlockAlert: Bool
    
    @State var showSafari: Bool = false
    @State var safariLink: URL?
    @State var isInternalPresented: Bool = false
    @State var internalIsPost: Bool = false
    @State var internalRestoreScrollPlaceholder: Bool = true
    @State var internalCommunityTarget: CommunityOrUser = CommunityOrUser(community: Community(""))
    @State var internalLoadPosts: Bool = true
    @State var internalItemInView: String = ""
    
    var body: some View {
        HStack(spacing: 10) {
            if message.new {
                Rectangle()
                    .frame(maxWidth: 2, maxHeight: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .foregroundColor(Color(red: 192 / 255, green: 57 / 255, blue: 43 / 255))
                    .opacity(0.8)
            }
            VStack(spacing: 10) {
                HStack {
                    Text(message.subject)
                        .bold()
                    Spacer()
                    Menu {
                        MessageActions(message: message, isEditorShowing: $isEditorShowing,
                                       replyToMessage: $replyToMessage, showingBlockAlert: $showingBlockAlert,
                                       isInternalPostPresented: $isInternalPresented, safariLink: $safariLink,
                                       internalIsPost: $internalIsPost)
                    } label: {
                        ZStack {
                            Spacer()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 20, height: 15)
                    }
                    .frame(alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text(message.author)
                    if message.subreddit != nil {
                        Text("via " + message.subreddit!)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text(message.age)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    if showSafari {
                        Spacer()
                            .fullScreenCover(isPresented: $showSafari, content: {
                                SFSafariViewWrapper(url: safariLink!)
                            })
                    }
                    Text(message.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .environment(\.openURL, OpenURLAction { url in
                            if url.isImage {
                                popupViewModel.fullImageLink = String(htmlEncodedString: url.absoluteString)
                                popupViewModel.contentType = .image
                                popupViewModel.isShowing = true
                            } else if url.isGif {
                                popupViewModel.videoLink = String(htmlEncodedString: url.absoluteString)
                                popupViewModel.contentType = .gif
                                popupViewModel.isShowing = true
                            } else if url.isPost {
                                internalIsPost = true
                                safariLink = url
                                isInternalPresented = true
                            } else if url.isCommunity {
                                internalCommunityTarget = CommunityOrUser(explicitURL: url)
                                internalIsPost = false
                                isInternalPresented = true
                            } else {
                                safariLink = url
                                showSafari = true
                            }
                            return .handled
                        })
                        .navigationDestination(isPresented: $isInternalPresented) {
                            if !internalIsPost { // internal is community
                                PostsView(itemInView: $internalItemInView, restoreScroll: $internalRestoreScrollPlaceholder,
                                          target: $internalCommunityTarget, loadPosts: $internalLoadPosts)
                            } else {
                                CommentsView(restorePostsScroll: $internalRestoreScrollPlaceholder, link: safariLink!.path)
                            }
                        }
                }
            }
            .font(.system(size: 14 + CGFloat(messageModel.textSizeInrease)))
        }
        .contextMenu {
            MessageActions(message: message, isEditorShowing: $isEditorShowing,
                           replyToMessage: $replyToMessage, showingBlockAlert: $showingBlockAlert,
                           isInternalPostPresented: $isInternalPresented, safariLink: $safariLink,
                           internalIsPost: $internalIsPost)}
    }
}

struct MessageActions: View {
    @EnvironmentObject var messageModel: MessageModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @ObservedObject var message: Message
//    @Binding var editorParentComment: Comment?
    @Binding var isEditorShowing: Bool
    @Binding var replyToMessage: Message?
    @Binding var showingBlockAlert: Bool
    @Binding var isInternalPostPresented: Bool
    @Binding var safariLink: URL?
    @Binding var internalIsPost: Bool
    @State var restoreScrollPlaceholder: Bool = false
    
    var body: some View {
        Group {
            if !message.isAdminMessage {
                Button(action: {
                    replyToMessage = message
                    isEditorShowing = true
                }) {
                    Label("Reply", systemImage: "arrow.uturn.left")
                }
            }
            if message.context != "" {
//                NavigationLink(destination: CommentsView(restorePostsScroll: $restoreScrollPlaceholder, link: message.context!)) {
                    Button(action: {
//                        safariLink
                        var link: String = "http://old.reddit.com"
                        var pathComponents = message.context.components(separatedBy: "/")
                        for i in 1...4 {
                            link = link + "/" + pathComponents[i]
                        }
                        safariLink = URL(string: link)!
                        internalIsPost = true
                        isInternalPostPresented = true
                    }) {
                        Label("View Post", systemImage: "text.bubble")
                    }
//                }
            }
//            Button(action: {  }) {
//                Label("Spam", systemImage: "exclamationmark.octagon")
//            }
            
            Button(action: {
                messageModel.blockUser(message: message)
                overlayModel.show("User blocked")
            }) {
                Label("Block user", systemImage: "xmark")
            }
        }
    }
}

struct MessageEditor: View {
    @EnvironmentObject var messageModel: MessageModel
    @EnvironmentObject var messageCreateModel: MessageCreateModel
    @Binding var isShowing: Bool
    @Binding var replyToMessage: Message?
    var userName: String?
    @State private var subject: String = ""
    @State private var content: String = ""
    @State private var showingUnsupportedAlert = false
    @FocusState private var isFieldFocused: Bool
    @State private var loading: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    isFieldFocused = true
                    if userName != nil {
                        messageCreateModel.openComposePage(userName: userName!)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            if messageCreateModel.requiresCaptcha {
                                showingUnsupportedAlert = true
                            }
                        }
                    }
                }
                .alert("Not supported", isPresented: $showingUnsupportedAlert) {
                    Button("OK") {
                        showingUnsupportedAlert = false
                        isShowing = false
                    }.keyboardShortcut(.defaultAction)
                } message: {
                    Text("This action is not supported on your account in OpenRed.")
                }
            VStack(spacing: 30) {
                HStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 25))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(EdgeInsets(top: 5, leading: 15, bottom: 0, trailing: 0))
                        .onTapGesture {
                            isShowing = false
                        }
                    Text("Reply")
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .top)
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color(UIColor.systemBlue))
                        .font(.system(size: 25))
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 15))
                        .onTapGesture {
                            if content != "" {
                                if userName != nil {
                                    messageCreateModel.sendMessage(subject: subject, message: content)
                                } else {
                                    messageModel.sendReply(message: replyToMessage!, content: content)
                                }
                                loading = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    isShowing = false
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                VStack {
                    if replyToMessage != nil {
                        ScrollView {
                            Group {
                                Text(replyToMessage!.author).bold() +
                                Text("\n" + replyToMessage!.body)
                            }
                            .font(.system(size: 15))
                            .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                            .foregroundStyle(.opacity(0.8))
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 200, alignment: .topLeading)
                    } else {
                        TextField("Subject", text: $subject)
                            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                            .frame(alignment: .topLeading)
                    }
                    TextField("Reply", text: $content, axis: .vertical)
                        .focused($isFieldFocused)
                        .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            if loading {
                Rectangle()
                    .fill(.black)
                    .opacity(0.6)
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
