//
// Copyright 2021 Wultra s.r.o.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions
// and limitations under the License.
// 

import Foundation
import PowerAuthShared

typealias D = PowerAuthDebug

public class TestManager: TestMonitor {
    
    public struct TestResults {
        let testsCount: Int
        let failedTests: Int
        let warnings: [String]
        let errors: [String]
    }
    
    public let name: String
    public let testCases: () throws -> [TestCase]
    public var promptForInteraction: ((String) -> Void)?
    
    public private(set) var lastResults: TestResults?
    
    public init(name: String, tests: @escaping () throws -> [TestCase]) {
        self.name = name
        self.testCases = tests
        self.promptForInteraction = nil
    }
        
    public func runAll() -> TestResults {
        
        lastPromptDate = nil
        
        D.verboseLevel = .all
        D.print("======================================================")
        D.print("=== Starting \(name) tests...")
        D.print("======================================================")
        
        let results = runTests()
        lastResults = results
        
        results.dumpResults()
        
        return results
    }
    
    private func runTests() -> TestResults {
        let tests: [TestCase]
        do {
            tests = try testCases()
        } catch {
            D.print("=== \(name): Failed to initialize test list: \(error.localizedDescription)")
            return TestResults(testsCount: 0, failedTests: 0, warnings: [], errors: [])
        }
        
        var totalCount = 0
        var totalFailures = 0
        var allErrors = [String]()
        var allWarnings = [String]()
        
        tests.forEach { testCase in
            resetCounters()
            do {
                D.print("=== \(name).\(testCase.name) - starting...")
                
                currentTestIsInteractive = testCase.isInteractive
                partialTests += 1
                
                try testCase.run(with: self)
                
                let isError = !errors.isEmpty || partialFailures > 0
                if !isError {
                    D.print("=== \(name).\(testCase.name) - OK")
                } else if !errors.isEmpty {
                    D.print("=== \(name).\(testCase.name) - FAILED")
                }
            } catch {
                self.error("\(testCase.name): \(error.localizedDescription)")
            }
            // Keep partial results
            totalCount += partialTests
            totalFailures += partialFailures
            allErrors.append(contentsOf: errors)
            allWarnings.append(contentsOf: warnings)
        }
        return TestResults(testsCount: totalCount, failedTests: totalFailures, warnings: allWarnings, errors: allErrors)
    }
    
    // MARK: TestResult
    
    public func error(_ message: String) {
        D.print("=== FAIL: \(message)")
        errors.append(message)
        partialFailures += 1
    }
    
    public func warning(_ message: String) {
        D.print("=== WARNING: \(message)")
        warnings.append(message)
    }
    
    public func increaseTestCount() {
        partialTests += 1
    }
    
    public func increaseFailedTestCount() {
        partialFailures += 1
    }
    
    private var currentTestIsInteractive: Bool = true
    private var lastPromptDate: Date?
    
    public func promptForInteraction(_ message: String, wait: TestMonitorWait) {
        
        guard currentTestIsInteractive else {
            return
        }
        
        promptForInteraction?(message)
        
        let padding = 12
        let row = String(repeating: "*", count: message.count + padding)
        let spc = String(repeating: " ", count: message.count + padding)
        let pad = String(repeating: " ", count: padding/2)
        print("")
        print("*\(row)*")
        print("*\(spc)*")
        print("*\(pad)\(message)\(pad)*")
        print("*\(spc)*")
        print("*\(row)*")
        print("")
        
        Thread.sleep(forTimeInterval: wait.timeInterval)
        
        lastPromptDate = Date()
    }
    
    public private(set) var errors = [String]()
    public private(set) var warnings = [String]()
    
    private var partialTests = 0
    private var partialFailures = 0
    
    private func resetCounters() {
        partialTests = 0
        partialFailures = 0
        errors.removeAll()
        warnings.removeAll()
    }
}


extension TestMonitorWait {
    
    /// Wait type converted to TimeInterval.
    var timeInterval: TimeInterval {
        switch self {
            case .long:
                return 5
            case .short:
                return 1
        }
    }
}

extension TestManager.TestResults {
    func dumpResults() {
        D.print("======================================================")
        if testsCount == 0 {
            D.print("=== FAILED: No test was executed for ")
        } else if failedTests > 0 {
            D.print("=== FAILED: Executed \(testsCount) tests, but \(failedTests) failed.")
        } else {
            D.print("=== OK: Executed \(testsCount) tests.")
        }
        errors.forEach { error in
            D.print("  - ERROR: \(error)")
        }
        warnings.forEach { warn in
            D.print("  - WARNING: \(warn)")
        }
        D.print("======================================================")
    }

}
