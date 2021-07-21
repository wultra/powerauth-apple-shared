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

public enum TestError: Error, LocalizedError {
    
    case alwaysFailAt(file: StaticString, line: Int)
    case assertAt(file: StaticString, line: Int)
    case failedWithError(reason: Error)
    case failedWithMessage(message: String)
    
    public var errorDescription: String? {
        switch self {
            case .alwaysFailAt(let file, let line):
                let location = URL(fileURLWithPath: "\(file)").pathComponents.last!
                return "Execution should not reach location at \(location), line \(line)"
            case .assertAt(let file, let line):
                let location = URL(fileURLWithPath: "\(file)").pathComponents.last!
                return "Assertion failed at \(location), line \(line)"
            case .failedWithMessage(let message):
                return "Test failed: \(message)"
            case .failedWithError(let reason):
                return "Test failed with error: \(reason.localizedDescription)"
        }
    }
}

func assertEqual<T>(_ a: T, _ b: T, file: @autoclosure () -> StaticString = #file, line: Int = #line) throws where T: Equatable {
    if a != b {
        throw TestError.assertAt(file: file(), line: line)
    }
}

func assertTrue(_ value: Bool, file: @autoclosure () -> StaticString = #file, line: Int = #line) throws {
    if !value {
        throw TestError.assertAt(file: file(), line: line)
    }
}

func assertFalse(_ value: Bool, file: @autoclosure () -> StaticString = #file, line: Int = #line) throws {
    if value {
        throw TestError.assertAt(file: file(), line: line)
    }
}

func assertNil<T>(_ value: T?, file: @autoclosure () -> StaticString = #file, line: Int = #line) throws {
    if value != nil {
        throw TestError.assertAt(file: file(), line: line)
    }
}

func assertNotNil<T>(_ value: T?, file: @autoclosure () -> StaticString = #file, line: Int = #line) throws {
    if value == nil {
        throw TestError.assertAt(file: file(), line: line)
    }
}

func alwaysFail(file: StaticString = #file, line: Int = #line) throws -> Never {
    throw TestError.alwaysFailAt(file: file, line: line)
}
