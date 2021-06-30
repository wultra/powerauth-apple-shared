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

/// The Lock class is a simple thread synchronization primitive which provides
/// simple lock / unlock methods and synchronized block execution.
///
/// The `DispatchSemafore` is used as underlying synchronization primitive.
public struct Lock {
    
    /// Attempts to acquire a lock, blocking a thread’s execution
    /// until the lock can be acquired.
    public func lock() {
        semaphore.wait()
    }
    
    /// Attempts to acquire a lock for a limited time, blocking a thread’s
    /// execution until the lock can be acquired or timeout elapsed.
    /// - Parameter timeout: Timeout for lock acquire
    /// - Returns: true if lock has been acquired
    public func tryLock(timeout: TimeInterval) -> Bool {
        let time = DispatchTime.now() + .milliseconds(Int(timeout * 1000.0))
        return semaphore.wait(timeout: time) == .success
    }
    
    /// Releases a previously acquired lock.
    public func unlock() {
        semaphore.signal()
    }

    /// Executes block after lock is acquired and releases it immediately afterwards.
    public func synchronized<T>(_ block: () throws -> T) rethrows -> T {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return try block()
    }
    
    /// Designated initializer
    public init() {
        semaphore = DispatchSemaphore(value: 1)
    }
    
    /// A private `DispatchSemaphore` as underlying synchronization primitive.
    private let semaphore: DispatchSemaphore
}

