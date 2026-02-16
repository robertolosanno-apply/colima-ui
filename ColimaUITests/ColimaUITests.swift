//
//  ColimaUITests.swift
//  ColimaUITests
//
//  Created by Roberto Losanno on 16/02/2026.
//

import XCTest

/// Tests the same parsing logic used by ColimaService and Container (duplicated here to avoid
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

    /// Mirror of ColimaService.parseContainerList
    private static func parseContainerList(_ output: String) -> [(id: String, names: String, image: String, status: String)] {
        output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> (String, String, String, String)? in
                let cols = line.split(separator: "\t", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                guard cols.count >= 4 else { return nil }
                return (String(cols[0]), cols[1], cols[2], cols[3])
            }
    }

    /// Mirror of Container.isRunning (status-based)
    private static func containerIsRunning(status: String) -> Bool {
        let lower = status.lowercased()
        return lower.hasPrefix("up ") || lower == "running"
    }

    /// Mirror of Container.displayName (names string)
    private static func containerDisplayName(names: String) -> String {
        let trimmed = names.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "—" }
        return trimmed.split(separator: ",").first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? trimmed
    }

    /// Mirror of ColimaService.isSafeContainerId
    private static func isSafeContainerId(_ id: String) -> Bool {
        (id.count == 12 || id.count == 64) && id.allSatisfy { $0.isHexDigit }
    }

    // MARK: - Colima status / container count tests

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

    // MARK: - Container list parsing tests

    func testParseContainerList_empty() {
        let list = Self.parseContainerList("")
        XCTAssertTrue(list.isEmpty)
    }

    func testParseContainerList_singleLine() {
        let output = "abc123def456\tmy-container\tnginx:latest\tUp 2 hours"
        let list = Self.parseContainerList(output)
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list[0].id, "abc123def456")
        XCTAssertEqual(list[0].names, "my-container")
        XCTAssertEqual(list[0].image, "nginx:latest")
        XCTAssertEqual(list[0].status, "Up 2 hours")
    }

    func testParseContainerList_multipleLines() {
        let output = """
            aaa111\tc1\timg1\tUp 1 minute
            bbb222\tc2\timg2\tExited (0) 3 days ago
            """
        let list = Self.parseContainerList(output)
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0].id, "aaa111")
        XCTAssertEqual(list[0].names, "c1")
        XCTAssertEqual(list[1].status, "Exited (0) 3 days ago")
    }

    func testParseContainerList_invalidLine_skipped() {
        let output = "only\tthree\tcols\n"
        let list = Self.parseContainerList(output)
        XCTAssertTrue(list.isEmpty)
    }

    func testParseContainerList_tabsPreserved() {
        let output = "id123\tname\timage\tstatus"
        let list = Self.parseContainerList(output)
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list[0].names, "name")
    }

    // MARK: - Container isRunning (status) tests

    func testContainerIsRunning_upPrefix() {
        XCTAssertTrue(Self.containerIsRunning(status: "Up 2 hours"))
        XCTAssertTrue(Self.containerIsRunning(status: "Up 5 seconds"))
        XCTAssertTrue(Self.containerIsRunning(status: "UP 1 minute"))
    }

    func testContainerIsRunning_runningLiteral() {
        XCTAssertTrue(Self.containerIsRunning(status: "running"))
        XCTAssertTrue(Self.containerIsRunning(status: "Running"))
    }

    func testContainerIsRunning_exitedNotRunning() {
        XCTAssertFalse(Self.containerIsRunning(status: "Exited (0) 3 days ago"))
        XCTAssertFalse(Self.containerIsRunning(status: "exited"))
    }

    func testContainerIsRunning_empty() {
        XCTAssertFalse(Self.containerIsRunning(status: ""))
    }

    // MARK: - Container displayName tests

    func testContainerDisplayName_singleName() {
        XCTAssertEqual(Self.containerDisplayName(names: "web"), "web")
    }

    func testContainerDisplayName_commaSeparated_takesFirst() {
        XCTAssertEqual(Self.containerDisplayName(names: "first,second"), "first")
    }

    func testContainerDisplayName_empty_returnsEmDash() {
        XCTAssertEqual(Self.containerDisplayName(names: ""), "—")
    }

    func testContainerDisplayName_whitespaceTrimmed() {
        XCTAssertEqual(Self.containerDisplayName(names: "  name  "), "name")
    }

    // MARK: - Safe container ID validation tests

    func testIsSafeContainerId_12HexChars_valid() {
        XCTAssertTrue(Self.isSafeContainerId("abc123def456"))
    }

    func testIsSafeContainerId_64HexChars_valid() {
        let id64 = String(repeating: "a", count: 64)
        XCTAssertTrue(Self.isSafeContainerId(id64))
    }

    func testIsSafeContainerId_11Chars_invalid() {
        XCTAssertFalse(Self.isSafeContainerId("abc123def45"))
    }

    func testIsSafeContainerId_nonHex_invalid() {
        XCTAssertFalse(Self.isSafeContainerId("abc123def45g"))
        XCTAssertFalse(Self.isSafeContainerId("abc123def45-"))
    }

    func testIsSafeContainerId_empty_invalid() {
        XCTAssertFalse(Self.isSafeContainerId(""))
    }
}
