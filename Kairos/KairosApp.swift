//
//  KairosApp.swift
//  Kairos
//
//  Created by Alfarisi Azmir on 04/02/26.
//

import SwiftUI

@main
struct KairosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
