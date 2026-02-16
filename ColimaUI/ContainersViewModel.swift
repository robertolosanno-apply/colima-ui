//
//  ContainersViewModel.swift
//  ColimaUI
//
//  Created by Roberto Losanno on 16/02/2026.
//

import Combine
import Foundation

@MainActor
final class ContainersViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var containers: [Container] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// ID of the container currently being started or stopped; used to disable that row's button.
    @Published private(set) var busyContainerId: String?

    // MARK: - Loading

    func load() {
        isLoading = true
        errorMessage = nil
        ColimaService.fetchContainers { [weak self] list in
            self?.containers = list
            self?.isLoading = false
            if list.isEmpty {
                self?.errorMessage = "No containers found. Is Docker running?"
            }
        }
    }

    // MARK: - Container actions

    func startContainer(id: String) {
        busyContainerId = id
        ColimaService.startContainer(id: id) { [weak self] success in
            self?.busyContainerId = nil
            if success { self?.load() }
        }
    }

    func stopContainer(id: String) {
        busyContainerId = id
        ColimaService.stopContainer(id: id) { [weak self] success in
            self?.busyContainerId = nil
            if success { self?.load() }
        }
    }
}
