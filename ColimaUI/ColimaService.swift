//
//  ColimaService.swift
//  ColimaUI
//
//  Created by Roberto Losanno on 16/02/2026.
//

import Foundation

/// Runs Colima and Docker commands via the user's login shell.
enum ColimaService {

    private static let shellPath = "/bin/zsh"
    private static let shellArgs = ["-l", "-c"]

    /// Parses "colima status" output; returns true if Colima reports running. Used by tests.
    static func isRunning(fromColimaStatusOutput output: String) -> Bool {
        output.lowercased().contains("colima is running")
    }

    /// Parses a line "running total" (e.g. from docker count command). Used by tests.
    static func parseContainerCountLine(_ line: String) -> (running: Int?, total: Int?) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 2, let r = Int(parts[0]), let t = Int(parts[1]) else { return (nil, nil) }
        return (r, t)
    }

    /// Fetches current Colima and container state. Completion is called on the main queue.
    static func fetchState(completion: @escaping (ColimaState) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let state: ColimaState
            switch runSync("colima status") {
            case .success(let output):
                let isRunning = isRunning(fromColimaStatusOutput: output)
                if isRunning {
                    let counts = fetchContainerCountsSync()
                    state = ColimaState(
                        isRunning: true,
                        containerRunning: counts.running,
                        containerTotal: counts.total
                    )
                } else {
                    state = .stopped
                }
            case .failure:
                state = .stopped
            }
            DispatchQueue.main.async { completion(state) }
        }
    }

    private static func runSync(_ command: String) -> Result<String, Error> {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: shellPath)
        task.arguments = shellArgs + [command]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return .success(String(data: data, encoding: .utf8) ?? "")
        } catch {
            return .failure(error)
        }
    }

    /// Returns (running, total) container counts. Call from a background context.
    private static func fetchContainerCountsSync() -> (running: Int?, total: Int?) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: shellPath)
        task.arguments = shellArgs + [
            "r=$(docker ps -q 2>/dev/null | wc -l | tr -d ' '); t=$(docker ps -a -q 2>/dev/null | wc -l | tr -d ' '); echo \"$r $t\""
        ]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        guard (try? task.run()) != nil else { return (nil, nil) }
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let line = String(data: data, encoding: .utf8) ?? ""
        return parseContainerCountLine(line)
    }

    private static let allowedColimaSubcommands = Set(["start", "stop"])

    /// Runs `colima` with the given arguments; completion is called on main after the process finishes.
    /// Only "start" and "stop" are allowed to avoid running arbitrary subcommands.
    static func runColima(_ args: [String], completion: (() -> Void)? = nil) {
        let safeArgs = args.filter { allowedColimaSubcommands.contains($0) }
        guard safeArgs.count == 1 else { return }
        let command = "colima " + safeArgs[0]
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: shellPath)
            task.arguments = shellArgs + [command]
            try? task.run()
            task.waitUntilExit()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completion?()
            }
        }
    }
}
