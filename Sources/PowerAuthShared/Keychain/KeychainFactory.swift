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

/// The `KeychainFactory` allows you to create objects implementing `Keychain` protocol.
///
/// The created keychain instances are internally cached. The factory class also supports an automatic cleanup
/// of the content of keychains after application reinstallation. The content of the keychain may survive the
/// application reinstall, depending on the operating system version. So, it's recommended to clean up all
/// content stored in keychains after application reinstallation. To achieve this, you can keep boolean
/// information in volatile storage that lost its content after reinstall. That's typical `UserDefauls` on iOS.
public final class KeychainFactory {
    
    /// Thread synchronization primitive
    let lock = Lock()
    
    /// If `true` then factory will remove all content of newly created `Keychain` instance.
    let removeContentOnFirstAccess: Bool
    
    /// Cached instances of `Keychain` objects
    var instances = [String:Keychain]()
    
    /// Set of keychain identifiers that has already been cleaned up after application restart.
    var instancesAlreadyCleanedUp = Set<String>()
    
    /// Initialize `KeychainFactory` with option to cleanup keychain content after first access.
    ///
    /// - Parameter removeContentOnFirstAccess: If set, then factory will remove all content of keychain when is accessed for first time.
    public init(removeContentOnFirstAccess: Bool) {
        self.removeContentOnFirstAccess = removeContentOnFirstAccess
    }
    
    /// Create `Keychain` object for a given identifier and access group.
    /// - Parameters:
    ///   - identifier: Keychain identifier.
    ///   - accessGroup: Access group for the Keychain Sharing.
    /// - Throws:
    ///   - `KeychainError.invalidAccessGroup` if `accessGroup` parameter doesn't match previously created keychain with the same identifier.
    /// - Returns: `Keychain` object.
    public func keychain(identifier: String, accessGroup: String? = nil) throws -> Keychain {
        return try lock.synchronized {
            if let keychain = instances[identifier] {
                guard keychain.accessGroup == accessGroup else {
                    throw KeychainError.invalidAccessGroup
                }
                return keychain
            }
            let newKeychain = buildKeychain(identifier: identifier, accessGroup: accessGroup)
            if removeContentOnFirstAccess && !instancesAlreadyCleanedUp.contains(identifier) {
                D.print("Removing ALL data stored in keychain: \(identifier)")
                instancesAlreadyCleanedUp.insert(identifier)
                try newKeychain.removeAll()
            }
            instances[identifier] = newKeychain
            return newKeychain
        }
    }
    
    /// Remove all cached `Keychain` instances from the factory.
    public func removeAllCachedInstances() {
        lock.synchronized {
            instances.removeAll(keepingCapacity: true)
        }
    }
    
    /// Internal keychain instance builder.
    /// - Parameters:
    ///   - identifier: Keychain identifier.
    ///   - accessGroup: Access group
    /// - Returns: New instance of `Keychain`
    private func buildKeychain(identifier: String, accessGroup: String?) -> Keychain {
        return AppleKeychain(identifier: identifier, accessGroup: accessGroup)
    }
}

