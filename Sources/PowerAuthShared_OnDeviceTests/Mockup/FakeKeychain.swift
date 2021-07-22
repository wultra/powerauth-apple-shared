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
#if os(iOS) || os(macOS)
import LocalAuthentication
#endif

/// The `FakeKeychain` implements `Keychain` protocol for the testing purposes.
/// The class allows you to simulate various situtions, such as biometric authentication
/// or IO failures.
public final class FakeKeychain: Keychain {
    
    /// Thread synchronization primitive.
    private let lock = RecursiveLock()
    /// Keychain's content.
    private var content = [String:Item]()
    
    public let identifier: String
    public let accessGroup: String?
    
    private let maxReuseDuration: TimeInterval
    
    /// Internal keychain item
    private struct Item {
        /// Value stored in keychain
        let value: Data
        /// Type of access required for such item
        let access: KeychainItemAccess
    }
    
    /// Construct fake keychain with identifier.
    /// - Parameters:
    ///   - identifier: Keychain's identifier.
    ///   - dumpOperations: If `true` then keychain will dump all operations do debug log.
    ///   - maxReuseDuration: Maximum reuse duration for `LAContext`. Default is 10.
    public init(identifier: String, dumpOperations: Bool = false, maxReuseDuration: TimeInterval = 10) {
        self.identifier = identifier
        self.accessGroup = nil
        self.maxReuseDuration = maxReuseDuration
        if dumpOperations {
            operationObservers.append { keychain, operation in
                switch operation {
                    case .contains(let key):
                        D.print("  * Keychain.containsData(forKey: \"\(key)\")")
                    case .get(let key, let prompt, let data):
                        let prompt = prompt != nil ? "\"\(prompt!.prompt)\"" : "nil"
                        let data = data != nil ? "[\(data!.count) bytes]" : "nil"
                        D.print("  * Keychain.data(forKey: \"\(key)\", prompt: \(prompt)) -> \(data)")
                    case .set(let key, let data, let access, let replace):
                        D.print("  * Keychain.set([\(data.count) bytes], forKey: \"\(key)\", access: \(access), replace: \(replace))")
                    case .remove(let key):
                        D.print("  * Keychain.remove(forKey: \"\(key)\")")
                    case .removeAll:
                        D.print("  * Keychain.removeAll()")
                }
            }
        }
    }
    
    public func synchronized<T>(block: () throws -> T) rethrows -> T {
        try lock.synchronized {
            try block()
        }
    }
    
    public func containsData(forKey key: String) throws -> Bool {
        try lock.synchronized {
            try validate(key: key)
            try simulateIoFailure(.contains(key: key))
            return content[key] != nil
        }
    }
    
    public func data(forKey key: String, authentication: KeychainPrompt?) throws -> Data? {
        try lock.synchronized {
            try validate(key: key)
            try simulateIoFailure(.get(key: key, prompt: authentication, result: content[key]?.value))
            guard let item = content[key] else {
                return nil
            }
            if item.access != .none {
                guard currentBiometryStatus == .available else {
                    throw KeychainError.biometryNotAvailable
                }
                guard let authentication = authentication else {
                    throw KeychainError.missingAuthentication
                }
                #if os(iOS) || os(macOS)
                if #available(iOS 11.0, *) {
                    if let context = authentication.asLAContext {
                        guard !context.interactionNotAllowed else {
                            throw KeychainError.disabledAuthentication
                        }
                        guard context.touchIDAuthenticationAllowableReuseDuration < maxReuseDuration else {
                            throw KeychainError.other(reason: .reuseDurationTooLong)
                        }
                    }
                }
                #endif // os(iOS) || os(macOS)
                switch authenticate(with: authentication) {
                    case .success:
                        break
                    case .authError:
                        throw KeychainError.authenticationFailed
                    case .biometryNotAvailable:
                        throw KeychainError.biometryNotAvailable
                    case .cancel:
                        throw KeychainError.userCancel
                    case .error(let error):
                        throw error
                    default:
                        D.fatalError("Unexpected authentication result")
                }
            }
            return item.value
        }
    }
    
    public func set(_ data: Data, forKey key: String, access: KeychainItemAccess, replace: Bool) throws {
        try lock.synchronized {
            try validate(key: key)
            if access != .none {
                guard currentBiometryStatus == .available else {
                    throw KeychainError.biometryNotAvailable
                }
            }
            try simulateIoFailure(.set(key: key, data: data, access: access, replace: replace))
            if let currentItem = content[key] {
                guard currentItem.access == .none else {
                    throw KeychainError.removeProtectedItemFirst
                }
                guard replace else {
                    throw KeychainError.itemExists
                }
            }
            content[key] = Item(value: data, access: access)
        }
    }
    
    public func remove(forKey key: String) throws {
        try lock.synchronized {
            try validate(key: key)
            try simulateIoFailure(.remove(key: key))
            content.removeValue(forKey: key)
        }
    }
    
    public func removeAll() throws {
        try lock.synchronized {
            try simulateIoFailure(.removeAll)
            content.removeAll(keepingCapacity: true)
        }
    }
    
    
    /// Function validates whether the provided key is valid key.
    /// - Parameter key: Key to validate
    /// - Throws: `KeychainError.invalidKey` in case that provided key is not valid.
    private func validate(key: String) throws {
        guard !key.isEmpty else {
            throw KeychainError.invalidKey
        }
    }
    
    // MARK: - Fake Authentication
    
    /// Enum representing a future authentication result when authentication with `KeychainPrompt` is required.
    public enum AuthResult {
        /// Simulate success result.
        case success
        /// Simulate user's cancel.
        case cancel
        /// Simulate authentication failure.
        case authError
        /// Simulate that biometric authentication is not available.
        case biometryNotAvailable
        /// Provide your own authentication evaluation.
        case evaluate(closure: (KeychainPrompt) -> AuthResult)
        /// Provide your own KeychainError
        case error(error: KeychainError)
    }
    
    /// FIFO queue for authentication results
    private var authResultQueue = [AuthResult]()
    /// Default auth result when queue is empty
    private var defaultAuthResult = AuthResult.success
    
    /// Sets default simulated authentication result that will be applied when queue is empty.
    /// - Parameter result: Default simulated authentication result.
    public func setDefaultAuthenticationResult(_ result: AuthResult) {
        lock.synchronized {
            defaultAuthResult = result
        }
    }
    
    /// Push authentication result into internal FIFO queue.
    /// - Parameter result: Future result of authentication.
    public func pushAuthenticationResult(_ result: AuthResult) {
        lock.synchronized {
            authResultQueue.insert(result, at: authResultQueue.startIndex)
        }
    }
    
    /// Simulate user's authentication with given result.
    /// - Parameter prompt: `KeychainPrompt` containing information for an authentication dialog.
    /// - Returns: Simulated authentication result.
    private func authenticate(with prompt: KeychainPrompt) -> AuthResult {
        let result = authResultQueue.popLast() ?? defaultAuthResult
        if case AuthResult.evaluate(let closure) = result {
            return closure(prompt)
        }
        return result
    }
    
    /// Current simulated biometry status.
    private var currentBiometryStatus: BiometryInfo.BiometryStatus = .available
    
    /// Sets desired biometry status to simulate missing or not-configured biometry.
    /// - Parameter status: Status to simulate.
    public func setSimulatedBiometryStatus(_ status: BiometryInfo.BiometryStatus) {
        lock.synchronized {
            currentBiometryStatus = status
        }
    }
    
    // MARK: - Fake IO result
    
    /// Enum representing a simulated type of operation to evaluate or observe.
    public enum IOOperation {
        /// Simulate IOResult for `containsData(forKey:)` method.
        case contains(key: String)
        /// Simulate IOResult for `data(forKey:)` method.
        case get(key: String, prompt: KeychainPrompt?, result: Data?)
        /// Simulate IOResult for `set(_ data:, forKey, access:, replace:)` method.
        case set(key: String, data: Data, access: KeychainItemAccess, replace: Bool)
        /// Simulate IOResult for `remove(forKey:)` method.
        case remove(key: String)
        /// Simulate IOResult for `removeAll()` method.
        case removeAll
    }
    
    /// Enum representing a simulated IO operation result.
    public enum IOResult {
        /// Everything's OK
        case success
        /// Operation failed on I/O failure
        case ioError
        /// Operation failed with simulated race condition (e.g. two processess access the same keychain)
        case raceCondition
        /// Provide your own IO result for the operation.
        case evaluate(closure: (IOOperation) -> IOResult)
        /// Provide your own `KeychainError`
        case error(error: KeychainError)
    }
    
    /// FIFO queue for authentication results
    private var ioResultQueue = [IOResult]()
    /// Default IO result applied when queue is empty
    private var defaultIoResult = IOResult.success
    
    /// Push authentication result into internal FIFO queue.
    /// - Parameter result: Future result of authentication.
    public func pushIOResult(_ result: IOResult) {
        lock.synchronized {
            ioResultQueue.insert(result, at: ioResultQueue.startIndex)
        }
    }
    
    /// Sets default simulated IO operation result that will be applied when queue is empty.
    /// - Parameter result: Future result of IO operation
    public func setDefaultIOResult(_ result: IOResult) {
        lock.synchronized {
            defaultIoResult = result
        }
    }
    
    /// Simulate unexpected failure when accessing data in keychain. The function also
    /// notifies all observers about given operation.
    /// - Parameter operation: Type of operation to simulate.
    /// - Throws: Exception if `ioResultQueue` contains failure
    private func simulateIoFailure(_ operation: IOOperation) throws {
        // Notify all observers
        try operationObservers.forEach { try $0(self, operation) }
        // Get operation result from queue or use default one
        var result = ioResultQueue.popLast() ?? defaultIoResult
        if case IOResult.evaluate(let closure) = result {
            result = closure(operation)
        }
        switch result {
            case .success:
                return
            case .raceCondition:
                throw KeychainError.changedFromElsewhere
            case .ioError:
                throw KeychainError.other(reason: .securityFramework(error: .IO))
            case .error(let error):
                throw error
            default:
                D.fatalError("Unexpected simulated IO failure")
        }
    }
    
    // MARK: - Observers
    
    /// List of registered observers
    private var operationObservers = [(FakeKeychain, IOOperation) throws -> Void]()
    
    /// Add operation observer that will be notified about all operations performed with the keychain.
    /// - Parameter observer: Observer that will be notified about all operations performed with the keychain.
    public func addOperationObserver(_ observer: @escaping (_ keychain: FakeKeychain, _ operation: IOOperation) throws -> Void) {
        lock.synchronized {
            operationObservers.append(observer)
        }
    }
}


public extension Keychain {
    
    /// Cast keychain to `FakeKeychain` implementation.
    var asFakeKeychain: FakeKeychain? {
        self as? FakeKeychain
    }
    
    /// Cast keychain to `FakeKeychain` implementation and throw a fatal error if object has different implementation.
    var asFakeKeychainOrFail: FakeKeychain {
        if let fk = self as? FakeKeychain {
            return fk
        }
        D.fatalError("Keychain is not FakeKeychain class")
    }
    
}
