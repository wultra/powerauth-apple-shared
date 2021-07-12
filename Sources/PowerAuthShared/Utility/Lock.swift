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
import Dispatch

/// The `Lock` structure is a simple thread synchronization primitive which provides
/// simple lock / unlock methods.
///
/// The `DispatchSemafore` is used as underlying synchronization primitive.
public struct Lock: Locking {
    
    public func lock() {
        semaphore.wait()
    }

    public func tryLock() -> Bool {
        return semaphore.wait(timeout: .now()) == .success
    }
    
    public func unlock() {
        semaphore.signal()
    }
    
    /// Designated initializer
    public init() {
        semaphore = DispatchSemaphore(value: 1)
    }
    
    /// A private `DispatchSemaphore` as underlying synchronization primitive.
    private let semaphore: DispatchSemaphore
}

