//
//  ColimaService.swift
//  ColimaUI
//
//  Created by Roberto Losanno on 16/02/2026.
//

import Foundation

/// Runs Colima and Docker commands via the user's login shell.
enum ColimaService {

    // MARK: - Configuration

    private static let shellPath = "/bin/zsh"
    private static let shellArgs = ["-l", "-c"]
    private static let allowedColimaSubcommands = Set(["start", "stop"])

    // MARK: - Colima state

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

    // MARK: - Containers

    /// Fetches the list of containers (running and stopped). Completion is called on the main queue.
    static func fetchContainers(completion: @escaping ([Container]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = runSync("docker ps -a --format \"{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\"")
            let list: [Container]
            switch result {
            case .success(let output):
                list = parseContainerList(output)
            case .failure:
                list = []
            }
            DispatchQueue.main.async { completion(list) }
        }
    }

    /// Parses tab-separated docker ps format output into Container array. Used by tests.
    static func parseContainerList(_ output: String) -> [Container] {
        output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> Container? in
                let cols = line.split(separator: "\t", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                guard cols.count >= 4 else { return nil }
                return Container(
                    id: String(cols[0]),
                    names: cols[1],
                    image: cols[2],
                    status: cols[3]
                )
            }
    }

    /// Starts a container by ID. Completion is called on main with success flag.
    static func startContainer(id: String, completion: ((Bool) -> Void)? = nil) {
        guard isSafeContainerId(id) else { DispatchQueue.main.async { completion?(false) }; return }
        runDockerAsync(["start", id], completion: completion)
    }

    /// Stops a container by ID. Completion is called on main with success flag.
    static func stopContainer(id: String, completion: ((Bool) -> Void)? = nil) {
        guard isSafeContainerId(id) else { DispatchQueue.main.async { completion?(false) }; return }
        runDockerAsync(["stop", id], completion: completion)
    }

    /// Only allow hex container IDs (12 or 64 chars) to avoid command injection.
    private static func isSafeContainerId(_ id: String) -> Bool {
        (id.count == 12 || id.count == 64) && id.allSatisfy { $0.isHexDigit }
    }

    private static func runDockerAsync(_ args: [String], completion: ((Bool) -> Void)? = nil) {
        let command = "docker " + args.map { arg in arg.contains(" ") ? "'\(arg)'" : arg }.joined(separator: " ")
        DispatchQueue.global(qos: .userInitiated).async {
            let result = runSync(command)
            let success = (try? result.get()) != nil
            DispatchQueue.main.async { completion?(success) }
        }
    }

    // MARK: - Colima lifecycle

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

    // MARK: - Private

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
}
