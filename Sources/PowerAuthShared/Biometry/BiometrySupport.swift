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

/// The `BiometrySupport` encapsulates various support functions related to biometric authentication.
public enum BiometrySupport {
    
    #if os(iOS) || os(macOS)
    
    // MARK: iOS + macOS
    
    /// Internal global biometric lock.
    private static let biometricLock = Lock()
    
    /// Try lock the global mutex and execute the provided block, but only if the lock is acquired. T
    /// he mutex is released immediately after the block execution.
    ///
    /// The function is useful in case that PowerAuth SDK needs to guarantee that only one biometric authentication request
    /// is executed at the same time. It's forbidden to call this function when biometric lock has been already acquired for
    /// the current thread.
    ///
    /// Note that the method is not implemented on watchOS or tvOS. On such systems function always returns `false`.
    ///
    /// - Parameter closure: Closure to execute after global lock acquire.
    /// - Throws: Rethrows error from the closure.
    /// - Returns: `true` in case that the provided block has been executed and `false` if biometric lock cannot be acquired.
    public static func tryLockBiometryAndExecute(closure: () throws -> Void) rethrows -> Bool {
        guard biometricLock.tryLock() else {
            return false
        }
        defer {
            biometricLock.unlock()
        }
        try closure()
        return true
    }
    
    #else
    
    // MARK: Dummy fallback
    
    /// Try lock the global mutex and execute the provided block, but only if the lock is acquired. T
    /// he mutex is released immediately after the block execution.
    ///
    /// The function is useful in case that PowerAuth SDK needs to guarantee that only one biometric authentication request
    /// is executed at the same time. It's forbidden to call this function when biometric lock has been already acquired for
    /// the current thread.
    ///
    /// Note that the method is not implemented on watchOS or tvOS. On such systems function always returns `false`.
    ///
    /// - Parameter closure: Closure to execute after global lock acquire.
    /// - Throws: Rethrows error from the closure.
    /// - Returns: `true` in case that the provided block has been executed and `false` if biometric lock cannot be acquired.
    public static func tryLockBiometryAndExecute(closure: () throws -> Void) rethrows -> Bool {
        return false
    }
    #endif // #if os(iOS) || os(macOS)
}
