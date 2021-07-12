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


/// Protocol defining methods for thread synchronization.
public protocol Locking {
    
    /// Attempts to acquire a lock, blocking a thread’s execution
    /// until the lock can be acquired.
    func lock()
    
    /// Attempts to acquire a lock for a limited time, blocking a thread’s
    /// execution until the lock can be acquired or timeout elapsed.
    /// - Returns: true if lock has been acquired
    func tryLock() -> Bool
    
    /// Releases a previously acquired lock.
    func unlock()
}


public extension Locking {
    
    /// Executes block after lock is acquired and releases it immediately afterwards.
    func synchronized<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try block()
    }
}
