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

/// The `RecursiveLock` class is a recursive thread synchronization primitive which provides
/// simple lock / unlock methods.
///
/// The `pthread_mutex_t` is used as underlying synchronization primitive.
public class RecursiveLock: Locking {
    
    public func lock() {
        pthread_mutex_lock(mutex)
    }

    public func tryLock() -> Bool {
        pthread_mutex_trylock(mutex) == 0
    }
    
    public func unlock() {
        pthread_mutex_unlock(mutex)
    }
    
    /// Designated initializer.
    public init() {
        mutex = .allocate(capacity: 1)
        let attributes = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        pthread_mutexattr_init(attributes)
        pthread_mutexattr_settype(attributes, PTHREAD_MUTEX_RECURSIVE)
        let result = pthread_mutex_init(mutex, attributes)
        guard result == 0 else {
            D.fatalError("pthread_mutex_init failed with \(result)")
        }
        attributes.deallocate()
    }
    
    deinit {
        let result = pthread_mutex_destroy(mutex)
        guard result == 0 else {
            if result == EBUSY {
                D.fatalError("pthread_mutex_destroy failed because lock is busy")
            } else {
                D.fatalError("pthread_mutex_destroy failde with error \(result)")
            }
        }
        mutex.deallocate()
    }
    
    /// A private `pthread_mutext_t` as underlying synchronization primitive.
    private let mutex: UnsafeMutablePointer<pthread_mutex_t>
}
