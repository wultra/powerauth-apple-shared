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

import XCTest
@testable import PowerAuthShared

final class LockTests: XCTestCase {
    
    var q1: OperationQueue!
    var q2: OperationQueue!
    
    var COUNTER: Int64 = 0
    
    override func setUp() {
        q1 = OperationQueue()
        q1.maxConcurrentOperationCount = 4
        q1.name = "test q1"
        q2 = OperationQueue()
        q2.maxConcurrentOperationCount = 4
        q2.name = "test q2"
        D.verboseLevel = .all
    }
    
    override func tearDown() {
        q1.cancelAllOperations()
        q1.waitUntilAllOperationsAreFinished()
        q2.cancelAllOperations()
        q2.waitUntilAllOperationsAreFinished()
    }
    
    // MARK: Lock
    
    func testLocking() throws {
        let iterations = 10000
        let concurrentJobs = 8
        let lock = Lock()
        // 8 jobs on each queue
        for _ in 1...concurrentJobs {
            q1.addOperation {
                for _ in 1...iterations {
                    lock.synchronized {
                        self.COUNTER += 1
                    }
                }
            }
            q2.addOperation {
                for _ in 1...iterations {
                    lock.synchronized {
                        self.COUNTER += 1
                    }
                }
            }
        }
        
        q1.waitUntilAllOperationsAreFinished()
        q2.waitUntilAllOperationsAreFinished()
        
        XCTAssertTrue(iterations * concurrentJobs * 2 == COUNTER)
    }
    
    func testTryLock() throws {
        let lock = Lock()
        // Acquire lock for 1s
        D.print("Adding operation 1")
        q1.addOperation {
            lock.synchronized {
                D.print("Long lock 1 acquired")
                Thread.sleep(forTimeInterval: 1.0)
                D.print("Long lock 1 released")
            }
        }
        Thread.sleep(forTimeInterval: 0.1)
        D.print("Try lock 1...")
        var result = lock.tryLock()
        XCTAssertFalse(result)
        if result {
            return
        }
        D.print("Try lock 2...")
        Thread.sleep(forTimeInterval: 1.9)
        result = lock.tryLock()
        XCTAssertTrue(result)
        // Retry long lock
        D.print("Adding operation 2")
        q1.addOperation {
            lock.synchronized {
                D.print("Long lock 2 acquired")
                Thread.sleep(forTimeInterval: 1.0)
                D.print("Long lock 2 released")
            }
        }
        D.print("Removing lock on MT")
        lock.unlock()
        Thread.sleep(forTimeInterval: 0.1)
        
        D.print("Try lock 3...")
        Thread.sleep(forTimeInterval: 1.0)
        result = lock.tryLock()
        XCTAssertTrue(result)
        lock.unlock()
    }
    
    // MARK: RecursiveLock
    
    func testRecursiveLocking() throws {
        let iterations = 10000
        let concurrentJobs = 8
        let lock = RecursiveLock()

        // 8 jobs on each queue
        for _ in 1...concurrentJobs {
            q1.addOperation {
                for _ in 1...iterations {
                    lock.synchronized {
                        self.COUNTER += 1
                    }
                }
            }
            q2.addOperation {
                for _ in 1...iterations {
                    lock.synchronized {
                        lock.synchronized {
                            self.COUNTER += 1
                        }
                    }
                }
            }
        }

        q1.waitUntilAllOperationsAreFinished()
        q2.waitUntilAllOperationsAreFinished()

        XCTAssertTrue(iterations * concurrentJobs * 2 == COUNTER)
    }
    
    func testTryRecursiveLock() throws {
        let lock = RecursiveLock()
        // Acquire lock for 1s
        D.print("Adding operation 1")
        q1.addOperation {
            lock.synchronized {
                lock.synchronized {
                    D.print("Long lock 1 acquired")
                    Thread.sleep(forTimeInterval: 1.0)
                    D.print("Long lock 1 released")
                }
            }
        }
        Thread.sleep(forTimeInterval: 0.1)
        D.print("Try lock 1...")
        var result = lock.tryLock()
        XCTAssertFalse(result)
        if result {
            return
        }
        D.print("Try lock 2...")
        Thread.sleep(forTimeInterval: 1.9)
        result = lock.tryLock()
        XCTAssertTrue(result)
        result = lock.tryLock()
        XCTAssertTrue(result)
        lock.unlock()
        
        // Retry long lock
        D.print("Adding operation 2")
        q1.addOperation {
            lock.synchronized {
                lock.synchronized {
                    D.print("Long lock 2 acquired")
                    Thread.sleep(forTimeInterval: 1.0)
                    D.print("Long lock 2 released")
                }
            }
        }
        D.print("Removing lock on MT")
        lock.unlock()
        Thread.sleep(forTimeInterval: 0.1)
        
        D.print("Try lock 3...")
        Thread.sleep(forTimeInterval: 1.0)
        result = lock.tryLock()
        XCTAssertTrue(result)
        lock.unlock()
    }
}
