//
//  TranslateMeApp.swift
//  TranslateMe
//
//  Created by Bender on 4/3/24.
//

import SwiftUI
import FirebaseCore // <-- Import Firebase

@main
struct TranslateMeApp: App {
    init() { // <-- Add an init
          FirebaseApp.configure() // <-- Configure Firebase app
      }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
