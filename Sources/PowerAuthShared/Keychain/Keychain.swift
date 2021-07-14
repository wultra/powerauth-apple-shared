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

/// The `Keychain` protocol defines a basic interface for storing a data to
/// a system provided keychain.
public protocol Keychain {
    
    /// Contains keychain's identifier.
    var identifier: String { get }
    
    /// Contains keychain's access group.
    var accessGroup: String? { get }
    
    /// Execute multiple modiffications on keychain in one synchronized block.
    ///
    /// - Parameter block: Closure where you can perform multiple changes with this keychain in thread-safe manner.
    ///                    The object returned from the block will be returned as a result of this function.
    func synchronized<T>(block: () throws -> T) rethrows -> T
    
    /// Returns a boolean value indicating that keychain contains data for the requested key.
    ///
    /// - Parameter key: Key to evaluate.
    /// - Throws:
    ///   - `KeychainError.other` in case of unexpected error.
    /// - Returns: `true` if keychain contains data for the requested key.
    func containsData(forKey key: String) throws -> Bool
    
    /// Removes data for given key. If you try to remove non-existent data, then does nothing.
    ///
    /// - Parameter key: Key to data to remove.
    /// - Throws:
    ///   - `KeychainError.other` in case of unexpected error.
    func remove(forKey key: String) throws
    
    
    /// Removes all content stored in this keychain.
    /// - Throws:
    ///   - `KeychainError.other` in case of unexpected error.
    func removeAll() throws
    
    /// Get binary data from the keychain for given key. If authentication parameter is provided, then
    /// also authenticate user.
    ///
    /// - Parameters:
    ///   - key: Key to previously stored data.
    ///   - authentication: `KeychainPrompt` structure required for accessing data stored with access restricted with `KeychainItemAccess`.
    ///     You can use `nil` for items with no restriction.
    /// - Throws:
    ///   - `KeychainError.userCancel` if user cancel authenticatication dialog.
    ///   - `KeychainError.biometryNotAvailable` if biometric authentication is requested but is not available on the device.
    ///   - `KeychainError.missingAuthentication` if item requires user to authenticate but authentication object is missing.
    ///   - `KeychainError.disabledAuthentication` if keychain prompt is provided, but cointains `LAContext` that does not allow interaction.
    ///   - `KeychainError.other` in case of other error.
    /// - Returns: Retrieved data or `nil` if keychain has no such item stored for given key.
    func data(forKey key: String, authentication: KeychainPrompt?) throws -> Data?
    
    /// Set binary data to keychain for given key with required item protection and option to replace
    /// value.
    ///
    /// - Parameters:
    ///   - data: Bytes to store.
    ///   - key: Key to store data.
    ///   - access: Type of protection of stored item.
    ///   - replace: If `true` then existing value is replaced. If set to `false` then throws error if item already exists.
    /// - Throws:
    ///   - `KeychainError.itemExists` if `replace` is `false` and data already exists in the keychain.
    ///   - `KeychainError.biometryNotAvailable` if other than `KeychainItemAccess.none` is requested and biometric authentication is not available right now.
    ///   - `KeychainError.changedFromElsewhere` if content of keychain has been modified from other application or process.
    ///   - `KeychainError.other` for all other underlying failures.
    func set(_ data: Data, forKey key: String, access: KeychainItemAccess, replace: Bool) throws
}

public extension Keychain {
    
    /// Get binary data from the keychain for given key. If keychain doesn't contains such data, then
    /// store new value to the keychain and return this value. In this function variant, you can specify
    /// `KeychainPrompt` to authenticate with biometry while accessing the data and `KeychainItemAccess`
    /// returned from the closure.
    /// 
    /// - Parameters:
    ///   - key: Key to previously stored data.
    ///   - authentication: `KeychainPrompt` structure required for accessing data stored with access restricted with `KeychainItemAccess`.
    ///     Use `nil` for items that doesn't require authentication to retrieve.
    ///   - closure: Closure that provides new data. The returned tuple contains new data to be set and type of protection for new item.
    /// - Throws:
    ///   - `KeychainError.userCancel` if user cancel authenticatication dialog.
    ///   - `KeychainError.biometryNotAvailable` if biometric authentication is requested but is not available on the device.
    ///   - `KeychainError.missingAuthentication` if item requires user to authenticate but authentication object is missing.
    ///   - `KeychainError.disabledAuthentication` if keychain prompt is provided, but cointains `LAContext` that does not allow interaction.
    ///   - `KeychainError.changedFromElsewhere` if content of keychain has been modified from other application or process.
    ///   - `KeychainError.other` in case of other error.
    /// - Returns: Previously stored data or new one, created by provided closure.
    func data(forKey key: String, authentication: KeychainPrompt? = nil, orSet closure: @autoclosure () throws -> (newData: Data, access: KeychainItemAccess)) throws -> Data {
        return try synchronized {
            if let data = try data(forKey: key) {
                return data
            }
            let (newData, access) = try closure()
            do {
                // Do not replace item, we already know that item doesn't exist.
                try set(newData, forKey: key, access: access, replace: false)
            } catch KeychainError.itemExists {
                // If item exists, then content has been changed from elsewhere
                throw KeychainError.changedFromElsewhere
            }
            return newData
        }
    }
    
    /// Get binary data from the keychain for given key. If keychain doesn't contains such data, then
    /// store new value to the keychain and return this value. In this function variant, you cannot specify `KeychainPrompt`
    /// and `KeychainItemAccess`.
    ///
    /// - Parameters:
    ///   - key: Key to previously stored data.
    ///   - closure: Closure that provides new data.
    /// - Throws:
    ///   - `KeychainError.missingAuthentication` if item requires user to authenticate but authentication object is missing.
    ///   - `KeychainError.changedFromElsewhere` if content of keychain has been modified from other application or process.
    ///   - `KeychainError.other` in case of other error.
    /// - Returns: Previously stored data or new one, created by provided closure.
    func data(forKey key: String, orSet closure: @autoclosure () throws -> Data) throws -> Data {
        return try data(forKey: key, authentication: nil, orSet: (closure(), .none))
    }
    
    /// Get binary data from the keychain for given key. The previously stored data must not require authentication to retrieve.
    ///
    /// - Parameter key: Key to previously stored data.
    /// - Throws:
    ///   - `KeychainError.missingAuthentication` if item requires user to authenticate but authentication object is missing.
    ///   - `KeychainError.other` in case of other error.
    /// - Returns: Retrieved data or `nil` if keychain has no such item stored for given key.
    func data(forKey key: String) throws -> Data? {
        return try data(forKey: key, authentication: nil)
    }
    
    /// Set binary data to keychain for given key with no item protection. If keychain already contains
    /// item for given key, then the old data is replaced.
    ///
    /// - Parameters:
    ///   - data: Bytes to store.
    ///   - key: Key to store data.
    /// - Throws:
    ///   - `KeychainError.changedFromElsewhere` if content of keychain has been modified from other application or process.
    ///   - `KeychainError.other` for all other underlying failures.
    func set(_ data: Data, forKey key: String) throws {
        return try set(data, forKey: key, access: .none, replace: true)
    }
    
    /// Set binary data to keychain for given key with required item protection. If keychain already contains
    /// item for given key, then the old data is replaced.
    ///
    /// - Parameters:
    ///   - data: Bytes to store.
    ///   - key: Key to store data.
    /// - Throws:
    ///   - `KeychainError.biometryNotAvailable` if other than `KeychainItemAccess.none` is requested and biometric authentication is not available right now.
    ///   - `KeychainError.changedFromElsewhere` if content of keychain has been modified from other application or process.
    ///   - `KeychainError.other` for all other underlying failures.
    func set(_ data: Data, forKey key: String, access: KeychainItemAccess) throws {
        return try set(data, forKey: key, access: access, replace: true)
    }
}
