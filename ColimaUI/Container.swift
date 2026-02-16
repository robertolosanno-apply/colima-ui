//
//  Container.swift
//  ColimaUI
//
//  Created by Roberto Losanno on 16/02/2026.
//

import Foundation

/// A Docker container as reported by `docker ps`.
struct Container: Identifiable {
    let id: String
    let names: String
    let image: String
    let status: String

    /// Display name: first name from comma-separated list, or "—" if empty.
    var displayName: String {
        let trimmed = names.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "—" }
        return trimmed.split(separator: ",").first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? trimmed
    }

    /// True if status indicates the container is running (e.g. "Up 2 hours", "running").
    var isRunning: Bool {
        let lower = status.lowercased()
        return lower.hasPrefix("up ") || lower == "running"
    }
}
