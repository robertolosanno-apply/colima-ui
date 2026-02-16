//
//  ColimaUITests.swift
//  ColimaUITests
//
//  Created by Roberto Losanno on 16/02/2026.
//

import XCTest

/// Tests the same parsing logic used by ColimaService (duplicated here to avoid
/// cross-module calls that cause EXC_BAD_ACCESS when the test bundle loads into the app).
final class ColimaUITests: XCTestCase {

    // MARK: - Parsing helpers (mirror ColimaService implementation)

    private static func isRunning(fromColimaStatusOutput output: String) -> Bool {
        output.lowercased().contains("colima is running")
    }

    private static func parseContainerCountLine(_ line: String) -> (running: Int?, total: Int?) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 2, let r = Int(parts[0]), let t = Int(parts[1]) else { return (nil, nil) }
        return (r, t)
    }

    // MARK: - Tests

    func testIsRunningFromColimaStatusOutput_running() {
        let output = "INFO[0000] colima is running using macOS Virtualization.Framework"
        XCTAssertTrue(Self.isRunning(fromColimaStatusOutput: output))
    }

    func testIsRunningFromColimaStatusOutput_stopped() {
        let output = "colima is not running"
        XCTAssertFalse(Self.isRunning(fromColimaStatusOutput: output))
    }

    func testIsRunningFromColimaStatusOutput_empty() {
        XCTAssertFalse(Self.isRunning(fromColimaStatusOutput: ""))
    }

    func testParseContainerCountLine_valid() {
        let (r, t) = Self.parseContainerCountLine("2 5")
        XCTAssertEqual(r, 2)
        XCTAssertEqual(t, 5)
    }

    func testParseContainerCountLine_withNewline() {
        let (r, t) = Self.parseContainerCountLine("  3  7  \n")
        XCTAssertEqual(r, 3)
        XCTAssertEqual(t, 7)
    }

    func testParseContainerCountLine_invalid() {
        XCTAssertEqual(Self.parseContainerCountLine("").running, nil)
        XCTAssertEqual(Self.parseContainerCountLine("abc def").running, nil)
        XCTAssertEqual(Self.parseContainerCountLine("1").running, nil)
    }
}
