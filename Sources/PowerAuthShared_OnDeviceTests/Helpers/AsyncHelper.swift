//
// Copyright 2022 Wultra s.r.o.
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
import PowerAuthShared
import SwiftUI

enum AsyncHelperError: Error {
    case alreadyWaiting
    case alreadyFinished
    case timeoutReached
    case noResultReported
    case noPendingWait
}

class AsyncHelper<T> {
    typealias ResultType = Result<T, Error>
    let semaphore = DispatchSemaphore(value: 0)
    let lock = Lock()
    var result: ResultType?
    var endTime: TimeInterval?
    
    static func wait<T>(interval: TimeInterval = 10, action: (AsyncHelper<T>) throws -> Void) throws -> T {
        let helper = AsyncHelper<T>()
        return try helper.waitForCompletion(wait: interval, action: action)
    }
    
    static func sleep(for interval: TimeInterval) throws {
        do {
            _ = try AsyncHelperBool().waitForCompletion(wait: interval) { _ in }
        } catch (e: AsyncHelperError.timeoutReached) {
            // Ignore timeout error
        }
    }
    
    func waitForCompletion(wait: TimeInterval = 10.0, action: (AsyncHelper<T>) throws -> Void) throws -> T {
        try action(self)
        return try waitImpl(wait: wait).get()
    }
    
    private func waitImpl(wait: TimeInterval) throws -> ResultType {
        try startWait(wait: wait, extendsTime: false)
        while (shouldWait()) {
            RunLoop.current .run(until: Date.init(timeIntervalSinceNow: 0.01))
            if semaphore.wait(timeout: .now() + .microseconds(10)) == .success {
                break
            }
        }
        return try lock.synchronized {
            guard let result = result else {
                throw AsyncHelperError.timeoutReached
            }
            endTime = nil
            return result
        }
    }
    
    private func startWait(wait: TimeInterval, extendsTime: Bool) throws {
        try lock.synchronized {
            if (!extendsTime) {
                // Starting new wait
                guard endTime == nil else {
                    throw AsyncHelperError.alreadyWaiting
                }
                result = nil
            } else {
                // Extending time
                guard endTime != nil else {
                    throw AsyncHelperError.noPendingWait
                }
            }
            endTime = Date().timeIntervalSince1970 + wait
        }
    }
    
    private func shouldWait() -> Bool {
        return lock.synchronized {
            guard let endTime = endTime else {
                return false
            }
            return Date().timeIntervalSince1970 < endTime
        }
    }
    
    func complete(with r: ResultType) {
        lock.synchronized {
            guard result == nil else {
                D.error("AsyncHelper has already result")
                return
            }
            self.result = r
            semaphore.signal()
        }
    }
    
    func complete(withError error: Error) {
        complete(with: .failure(error))
    }
    
    func complete(withObject value: T) {
        complete(with: .success(value))
    }
    
    func extendWaitingTime(wait: TimeInterval = 10.0) throws {
        try startWait(wait: wait, extendsTime: true)
    }
}

typealias AsyncHelperBool = AsyncHelper<Bool>

