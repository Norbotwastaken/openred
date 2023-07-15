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
    var types: KeyValuePairs<String, String> {
        return ["inbox": "All",
//                "unread": "Unread",
                "messages": "Messages",
                "comments": "Comment Replies", "selfreply": "Post Replies", "mentions": "Mentions"]
    }
    @State private var type = "inbox"
    
    var body: some View {
        if messageModel.userSessionManager.userName != nil {
            NavigationStack() {
                ZStack {
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
                            MessageView(message: message, isEditorShowing: $isEditorShowing, replyToMessage: $replyToMessage)
                                .listRowInsets(EdgeInsets(top: 8, leading: message.new ? 3 : 15, bottom: 8, trailing: 15))
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
                    //            .navigationBarHidden(isEditorShowing)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack {
                                Button {
                                    // Perform an action
                                    print("Add Item Tapped")
                                } label: {
                                    Image(systemName: "ellipsis")
                                }
                            }
                        }
                    }
                    if isEditorShowing {
                        MessageEditor(isShowing: $isEditorShowing, replyToMessage: $replyToMessage)
                    }
                }
                .onAppear {
                    messageModel.openInbox(filter: type)
                    model.messageCount = 0
                }
            }
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

struct MessageView: View {
    @EnvironmentObject var messageModel: MessageModel
    @ObservedObject var message: Message
    @Binding var isEditorShowing: Bool
    @Binding var replyToMessage: Message?
    
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
                        MessageActions(message: message, isEditorShowing: $isEditorShowing, replyToMessage: $replyToMessage)
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
                Text(message.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: 14))
        }
    }
}

struct MessageActions: View {
    @EnvironmentObject var messageModel: MessageModel
    @ObservedObject var message: Message
//    @Binding var editorParentComment: Comment?
    @Binding var isEditorShowing: Bool
    @Binding var replyToMessage: Message?
    
    var body: some View {
        Group {
            Button(action: {
                replyToMessage = message
                isEditorShowing = true
            }) {
                Label("Reply", systemImage: "arrow.uturn.left")
            }
            Button(action: {  }) {
                Label("View Post", systemImage: "text.bubble")
            }
//            Button(action: {  }) {
//                Label("Spam", systemImage: "exclamationmark.octagon")
//            }
            Button(action: {  }) {
                Label("Block User", systemImage: "xmark")
            }
        }
    }
}

struct MessageEditor: View {
    @EnvironmentObject var messageModel: MessageModel
    @Binding var isShowing: Bool
    @Binding var replyToMessage: Message?
    @State private var content: String = ""
    @FocusState private var isFieldFocused: Bool
    @State private var loading: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { isFieldFocused = true }
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
                                messageModel.sendReply(message: replyToMessage!, content: content)
                                loading = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    isShowing = false
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                VStack {
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
