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

public class TestManager {
    
    public let name: String
    public let testCases: () throws -> [TestCase]
    
    public init(name: String, tests testCases: @escaping () throws -> [TestCase]) {
        self.name = name
        self.testCases = testCases
    }
        
    public func runAll() {
        D.verboseLevel = .all
        D.print("======================================================")
        D.print("=== Starting \(name) tests...")
        D.print("======================================================")
        
        let result = runTests()
        D.print("======================================================")
        if result.count == 0 {
            D.print("=== FAILED: No test was executed for ")
        } else if result.failed > 0 {
            D.print("=== FAILED: Executed \(result.count) tests, but \(result.count) failed.")
        } else {
            D.print("=== OK: Executed \(result.count) tests.")
        }
        D.print("======================================================")
    }
    
    private func runTests() -> (count: Int, failed: Int) {
        let tests: [TestCase]
        do {
            tests = try testCases()
        } catch {
            D.print("=== \(name): Failed to initialize test list: \(error.localizedDescription)")
            return (0, 0)
        }
        var failures = 0
        tests.forEach { testCase in
            do {
                D.print("=== \(name).\(testCase.name) - starting...")
                try testCase.run()
                D.print("=== \(name).\(testCase.name) - OK")
            } catch {
                D.print("=== \(name).\(testCase.name) - FAILED - \(error.localizedDescription)")
                failures += 1
            }
        }
        return (tests.count, failures)
    }
}
