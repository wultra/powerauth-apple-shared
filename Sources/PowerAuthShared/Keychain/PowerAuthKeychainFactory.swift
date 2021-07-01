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

/// The `PowerAuthKeychainFactory` allows you to create objects implementing `PowerAuthKeychain` protocol.
/// The created keychain instances are internally cached. The factory class also supports an automatic cleanup
/// of content of keychains after application re-install. The content of keychain may survive the application
/// reinstall, depending on the operating system version. So, it's recommended to cleanup all content stored in
/// keychains after application reinstall. To achieve this, you can keep a boolean information in volatile storage
/// that lost its content after reinstall. That's typically `UserDefauls` on iOS.
public final class PowerAuthKeychainFactory {
    
    /// Thread synchronization primitive
    let lock = Lock()
    
    /// If `true` then factory will remove all content of newly created `PowerAUthKeychain` instance.
    let removeContentOnFirstAccess: Bool
    
    /// Cached instances of `PowerAuthKeychain` objects
    var instances = [String:PowerAuthKeychain]()
    
    /// Set of keychain identifiers that has already been cleaned up after application restart.
    var instancesAlreadyCleanedUp = Set<String>()
    
    /// Initialize `PowerAuthKeychainFactory` with option to cleanup keychain content after first access.
    ///
    /// - Parameter removeContentOnFirstAccess: If set, then factory will remove all content of keychain when is accessed for first time.
    public init(removeContentOnFirstAccess: Bool) {
        self.removeContentOnFirstAccess = removeContentOnFirstAccess
    }
    
    /// Create `PowerAuthKeychain` object for a given identifier and access group.
    /// - Parameters:
    ///   - identifier: Keychain identifier.
    ///   - accessGroup: Access group for the Keychain Sharing.
    /// - Throws: `PowerAuthKeychainError.invalidAccessGroup` if `accessGroup` parameter doesn't match previously created keychain with the same identifier.
    /// - Returns: `PowerAuthKeychain` object.
    public func keychain(identifier: String, accessGroup: String? = nil) throws -> PowerAuthKeychain {
        let keyId = "\(identifier)##\(accessGroup ?? "no-acg")"
        return try lock.synchronized {
            if let keychain = instances[keyId] {
                if keychain.accessGroup != accessGroup {
                    throw PowerAuthKeychainError.invalidAccessGroup
                }
                return keychain
            }
            let newKeychain = buildKeychain(identifier: identifier, accessGroup: accessGroup)
            if removeContentOnFirstAccess && !instancesAlreadyCleanedUp.contains(keyId) {
                D.print("Removing ALL data stored in keychain: \(identifier)")
                instancesAlreadyCleanedUp.insert(keyId)
                try newKeychain.removeAll()
            }
            instances[keyId] = newKeychain
            return newKeychain
        }
    }
    
    /// Remove all cached `PowerAuthKeychain` instances from the factory.
    public func removeAllCachedInstances() {
        lock.synchronized {
            instances.removeAll(keepingCapacity: true)
        }
    }
    
    /// Internal keychain instance builder.
    /// - Parameters:
    ///   - identifier: Keychain identifier.
    ///   - accessGroup: Access group
    /// - Returns: New instance of `PowerAuthKeychain`
    private func buildKeychain(identifier: String, accessGroup: String?) -> PowerAuthKeychain {
        return AppleKeychain(identifier: identifier, accessGroup: accessGroup)
    }
}

