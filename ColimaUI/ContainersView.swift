//
//  ContainersView.swift
//  ColimaUI
//
//  Created by Roberto Losanno on 16/02/2026.
//

import SwiftUI

/// Docker Desktop–style list of containers in a native table with toolbar.
struct ContainersView: View {
    @StateObject private var viewModel = ContainersViewModel()

    /// Delay before first load so the window is fully presented before spawning `docker ps`.
    private static let initialLoadDelay: TimeInterval = 0.2

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.containers.isEmpty {
                ProgressView("Loading containers…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage, viewModel.containers.isEmpty {
                ContentUnavailableView {
                    Label("No Containers", systemImage: "cube.transparent")
                } description: {
                    Text(message)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.containers) {
                    TableColumn("Name") { container in
                        Text(container.displayName)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .width(min: 120, ideal: 200)
                    TableColumn("Image") { container in
                        Text(container.image)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .width(min: 120, ideal: 220)
                    TableColumn("Status") { container in
                        Text(container.status)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(statusColor(container.status))
                    }
                    .width(min: 100, ideal: 180)
                    TableColumn("") { container in
                        let busy = viewModel.busyContainerId == container.id
                        if container.isRunning {
                            Button { viewModel.stopContainer(id: container.id) } label: {
                                Image(systemName: "stop.fill")
                            }
                            .buttonStyle(.borderless)
                            .help("Stop container")
                            .disabled(busy)
                            .opacity(busy ? 0.4 : 1)
                        } else {
                            Button { viewModel.startContainer(id: container.id) } label: {
                                Image(systemName: "play.fill")
                            }
                            .buttonStyle(.borderless)
                            .help("Start container")
                            .disabled(busy)
                            .opacity(busy ? 0.4 : 1)
                        }
                    }
                    .width(min: 56, ideal: 56)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.load()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("Containers")
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.initialLoadDelay) {
                viewModel.load()
            }
        }
    }

    // MARK: - Helpers

    private func statusColor(_ status: String) -> Color {
        let lower = status.lowercased()
        if lower.hasPrefix("up ") || lower == "running" {
            return .green
        }
        if lower.hasPrefix("exited") || lower.contains("dead") {
            return .secondary
        }
        return .primary
    }
}

#Preview {
    ContainersView()
        .frame(width: 560, height: 320)
}
