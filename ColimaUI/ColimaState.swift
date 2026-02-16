//
//  ColimaState.swift
//  ColimaUI
//
//  Created by Roberto Losanno on 16/02/2026.
//

import Foundation

/// Current Colima and container state, as observed from the system.
struct ColimaState {
    let isRunning: Bool
    let containerRunning: Int?
    let containerTotal: Int?

    static let stopped = ColimaState(isRunning: false, containerRunning: nil, containerTotal: nil)
}
