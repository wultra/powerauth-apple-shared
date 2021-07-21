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

/// Represents how much must `TestMonitor` wait when prompting for an interaction.
public enum TestMonitorWait {
    /// Represents a short wait time interval.
    case short
    /// Represents a long wait time interval.
    case long
}


/// Defines interface for tests to report additional errors or prompt for user's interaction.
public protocol TestMonitor {
    
    /// Prompt for user's interaction.
    /// - Parameters:
    ///   - message: Message to display to prompt.
    ///   - wait: How much prompt must wait before execution will continue.
    func promptForInteraction(_ message: String, wait: TestMonitorWait)
    
    /// Add additional warning to the test result.
    /// - Parameter message: Warning to add.
    func warning(_ message: String)
    
    /// Add additional error to the test result.
    /// - Parameter message: Error to add.
    func error(_ message: String)
    
    
    /// If test case contains additional functions, then you can increase the total tests count with this function.
    func increaseTestCount()
    
    /// If test case contains additional functions, then you can increase the total failed tests count with this function.
    func increaseFailedTestCount()
    
    /// Collected additional errors.
    var errors: [String] { get }
    
    /// Collected additional warnings.
    var warnings: [String] { get }
}

public extension TestMonitor {
    
    /// Prompt for interaction with short wait.
    /// - Parameter message: Message to display.
    func promptForInteraction(_ message: String) {
        promptForInteraction(message, wait: .short)
    }
}


/// Defines interface that test case must implement
public protocol TestCase {
    /// Name of test
    var name: String { get }

    /// Contains `true` if test needs real user's interaction.
    var isInteractive: Bool { get }
    
    /// Run all sub-tests with given `TestMonitor`
    func run(with monitor: TestMonitor) throws
}
