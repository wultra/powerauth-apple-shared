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

open class BaseTestCase: TestCase {

    public let name: String
    public let isInteractive: Bool
    var testMethods: [(String, (TestMonitor) throws -> Void)]
   
    public init(testCaseName: String, interactive: Bool) {
        self.name = testCaseName
        self.isInteractive = interactive
        self.testMethods = []
    }

    public func register(methodName: String, _ method: @escaping (TestMonitor) throws -> Void) {
        testMethods.append((methodName, method))
    }

    public func run(with monitor: TestMonitor) throws {
        var firstError: Error?
        testMethods.forEach { methodName, method in
            do {
                monitor.increaseTestCount()
                try method(monitor)
            } catch {
                monitor.error("\(name).\(methodName) failed: \(error.localizedDescription)")
                if firstError == nil {
                    firstError = error
                }
            }
        }
    }
}
