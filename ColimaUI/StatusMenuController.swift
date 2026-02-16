//
//  StatusMenuController.swift
//  ColimaUI
//
//  Created by Roberto Losanno on 16/02/2026.
//

import AppKit

/// Owns the menu bar status item, builds the menu from state, and coordinates refresh and start/stop.
final class StatusMenuController: NSObject {

    // MARK: - Properties

    private let statusItem: NSStatusItem
    private var timer: Timer?
    private var pendingOperation: String?  // "Starting" or "Stopping"
    private let containersWindowController = ContainersWindowController()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupInitialMenu()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func setupInitialMenu() {
        if let button = statusItem.button {
            button.title = "⚫️"
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Checking...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    // MARK: - Refresh & menu updates

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        ColimaService.fetchState { [weak self] state in
            self?.apply(state: state)
        }
    }

    private func apply(state: ColimaState) {
        if let op = pendingOperation {
            if op == "Stopping" && !state.isRunning {
                pendingOperation = nil
                updateMenu(state: state)
            } else if op == "Starting" && state.isRunning {
                pendingOperation = nil
                updateMenu(state: state)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.refresh()
                }
            }
        } else {
            updateMenu(state: state)
        }
    }

    private func updateMenu(state: ColimaState) {
        let isBusy = pendingOperation != nil
        if let button = statusItem.button {
            if isBusy {
                button.title = "🟡"
            } else {
                button.title = state.isRunning ? "🟢" : "🔴"
            }
        }

        let menu = NSMenu()

        let statusText: String
        if let op = pendingOperation {
            statusText = "Colima: \(op)..."
        } else {
            statusText = state.isRunning ? "Colima: Running" : "Colima: Stopped"
        }
        menu.addItem(NSMenuItem(title: statusText, action: nil, keyEquivalent: ""))

        if state.isRunning, !isBusy, let r = state.containerRunning, let t = state.containerTotal {
            let containersItem = NSMenuItem(title: "Containers: \(r) / \(t)", action: #selector(showContainersWindow), keyEquivalent: "")
            containersItem.target = self
            menu.addItem(containersItem)
        }

        menu.addItem(NSMenuItem.separator())

        if !isBusy {
            if state.isRunning {
                let stop = NSMenuItem(title: "Stop Colima", action: #selector(stopColima), keyEquivalent: "")
                stop.target = self
                menu.addItem(stop)
            } else {
                let start = NSMenuItem(title: "Start Colima", action: #selector(startColima), keyEquivalent: "")
                start.target = self
                menu.addItem(start)
            }
        }

        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func startColima() {
        pendingOperation = "Starting"
        updateMenu(state: ColimaState(isRunning: false, containerRunning: nil, containerTotal: nil))
        ColimaService.runColima(["start"]) { [weak self] in
            self?.refresh()
        }
    }

    @objc private func stopColima() {
        pendingOperation = "Stopping"
        updateMenu(state: ColimaState(isRunning: true, containerRunning: nil, containerTotal: nil))
        ColimaService.runColima(["stop"]) { [weak self] in
            self?.refresh()
        }
    }

    @objc private func showContainersWindow() {
        containersWindowController.show()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
