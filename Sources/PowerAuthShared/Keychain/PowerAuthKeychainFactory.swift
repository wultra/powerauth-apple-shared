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

/// The `PowerAuthKeychainFactory` allows you to create objects implementing
/// `PowerAuthKeychain` protocol. The created keychain instances are cached internally.
public final class PowerAuthKeychainFactory {

    /// Shared factory instance
    public static let shared = PowerAuthKeychainFactory()
    
    let lock = Lock()
    var instances = [String:PowerAuthKeychain]()
    
    init() {
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
            let newKeychain = AppleKeychain(identifier: identifier, accessGroup: accessGroup)
            instances[keyId] = newKeychain
            return newKeychain
        }
    }
    
    /// Remove all cached `PowerAuthKeychain` instances from the factory.
    public func removeAllInstances() {
        lock.synchronized {
            instances.removeAll(keepingCapacity: true)
        }
    }
}

public extension PowerAuthKeychainFactory {
    

}
