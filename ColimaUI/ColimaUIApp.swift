//
//  ColimaUIApp.swift
//  ColimaUI
//
//  Created by Roberto Losanno on 16/02/2026.
//

import SwiftUI

@main
struct ColimaUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusMenuController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusMenuController = StatusMenuController()
    }
}
