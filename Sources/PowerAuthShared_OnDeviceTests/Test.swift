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

func assertEqual<T>(_ a: T, _ b: T, closure: @autoclosure () -> TestError = .failed) throws where T: Equatable {
    if a != b {
        throw closure()
    }
}

func assertTrue(_ value: Bool, closure: @autoclosure () -> TestError = .failed) throws {
    if !value {
        throw closure()
    }
}

func assertFalse(_ value: Bool, closure: @autoclosure () -> TestError = .failed) throws {
    if value {
        throw closure()
    }
}

func assertNil<T>(_ value: T?, closure: @autoclosure () -> TestError = .failed) throws {
    if value != nil {
        throw closure()
    }
}

func assertNotNil<T>(_ value: T?, closure: @autoclosure () -> TestError = .failed) throws {
    if value == nil {
        throw closure()
    }
}

func alwaysFail() throws -> Never {
    throw TestError.failed
}

func biometryPrompt(_ prompt: String) {
    let padding = 16
    let row = String(repeating: "*", count: prompt.count + padding)
    let spc = String(repeating: " ", count: prompt.count + padding)
    let pad = String(repeating: " ", count: padding/2)
    print("")
    print("*\(row)*")
    print("*\(spc)*")
    print("*\(pad)\(prompt)\(pad)*")
    print("*\(spc)*")
    print("*\(row)*")
    print("")
}
