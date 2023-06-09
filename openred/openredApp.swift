//
//  openredApp.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI

@main
struct openredApp: App {
    @StateObject private var model = Model()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model)
        }
    }
}
