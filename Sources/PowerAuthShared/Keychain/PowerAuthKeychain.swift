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
import LocalAuthentication

/// The `PowerAuthKeychainItemAccess` enumeration defines additional protection
/// of item stored in the keychain.
public enum PowerAuthKeychainItemAccess {
    /// No additional authentication is required to access the item.
    case none
    /// Constraint to access an item with Touch ID for currently enrolled fingers,
    /// or from Face ID with the currently enrolled user.
    case currentBiometricSet
    /// Constraint to access an item with Touch ID for any enrolled fingers, or Face ID.
    case anyBiometricSet
    /// Constraint to access an item with any enrolled biometry or device's passcode.
    case anyBiometricSetOrDevicePasscode
}

/// The `PowerAuthKeychain` protocol defines a basic interface for storing a data to
/// a system provided keychain.
public protocol PowerAuthKeychain {
    
    /// Contains keychain's identifier.
    var identifier: String { get }
    
    /// Contains keychain's access group.
    var accessGroup: String? { get }
    
    /// Returns a boolean value indicating that keychain contains data for the requested key.
    ///
    /// - Parameter key: Key to evaluate.
    /// - Returns: `true` if keychain contains data for the requested key.
    func containsData(forKey key: String) -> Bool
    
    /// Removes data for given key. If you try to remove non-existent data, then does nothing.
    ///
    /// - Parameter key: Key to data to remove.
    /// - Throws:
    ///   - `PowerAuthKeychainError.generalFialure(code)` - In case of other error.
    func remove(forKey key: String) throws
    
    
    /// Removes all content stored in this keychain.
    /// - Throws:
    ///   - `PowerAuthKeychainError.generalFialure(code)` - In case of other error.
    func removeAll() throws
    
    /// Get binary data from the keychain for given key. If authentication parameter is provided, then
    /// also authenticate user.
    ///
    /// - Parameters:
    ///   - key: Key to previously stored data.
    ///   - authentication: `LAContext` authentication object, if provided, then authentication dialog may appear.
    /// - Throws:
    ///   - `PowerAuthKeychainError.cancel` - If user cancel authenticatication dialog.
    ///   - `PowerAuthKeychainError.biometryNotAvailable` - If biometric authentication is requested but is not available on the device.
    ///   - `PowerAuthKeychainError.missingAuthentication` if item requires user to authenticate but authentication object is missing.
    ///   - `PowerAuthKeychainError.generalFialure(code)` - In case of other error.
    /// - Returns: Retrieved data or `nil` if keychain has no such item stored for given key.
    func data(forKey key: String, authentication: LAContext?) throws -> Data?
    
    /// Set binary data to keychain for given key with required item protection and option to replace
    /// value.
    ///
    /// - Parameters:
    ///   - data: Bytes to store.
    ///   - key: Key to store data.
    ///   - access: Type of protection of stored item.
    ///   - replace: If `true` then existing value is replaced. If set to `false` then throws
    /// - Throws: `PowerAuthKeychainError` in case of failure.
    func set(_ data: Data, forKey key: String, access: PowerAuthKeychainItemAccess, replace: Bool) throws
}

public extension PowerAuthKeychain {
    
    /// Get binary data from the keychain for given key.
    ///
    /// - Parameter key: Key to previously stored data.
    /// - Throws:
    ///   - `PowerAuthKeychainError.missingAuthentication` if item requires user to authenticate
    /// - Returns: Retrieved data or `nil` if keychain has no such item stored for given key.
    func data(forKey key: String) throws -> Data? {
        return try data(forKey: key, authentication: nil)
    }
    
    /// Set binary data to keychain for given key with no item protection. If keychain already contains
    /// item for given key, then the old data is replaced with new one.
    ///
    /// - Parameters:
    ///   - data: Bytes to store.
    ///   - key: Key to store data.
    /// - Throws: `PowerAuthKeychainError` in case of failure.
    func set(_ data: Data, forKey key: String) throws {
        return try set(data, forKey: key, access: .none, replace: true)
    }
    
    /// Set binary data to keychain for given key with required item protection. If keychain already contains
    /// item for given key, then the old data is replaced with new one.
    ///
    /// - Parameters:
    ///   - data: Bytes to store.
    ///   - key: Key to store data.
    /// - Throws: `PowerAuthKeychainError` in case of failure.
    func set(_ data: Data, for key: String, access: PowerAuthKeychainItemAccess) throws {
        return try set(data, forKey: key, access: access, replace: true)
    }
}
