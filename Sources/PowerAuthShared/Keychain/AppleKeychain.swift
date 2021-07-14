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
#if os(iOS) || os(macOS)
import LocalAuthentication
#endif

/// Class implementing `Keychain` protocol on Apple platforms.
class AppleKeychain: Keychain {
    
    let lock = RecursiveLock()
    
    /// Construct keychain with given identifier and optional access group.
    /// - Parameters:
    ///   - identifier: Keychain identifier
    ///   - accessGroup: Access group
    init(identifier: String, accessGroup: String?) {
        self.identifier = identifier
        self.accessGroup = accessGroup
    }

    // MARK: - Keychain protocol -
    
    let identifier: String
    let accessGroup: String?
    
    func synchronized<T>(block: () throws -> T) rethrows -> T {
        try lock.synchronized {
            try block()
        }
    }
    
    func set(_ data: Data, forKey key: String, access: KeychainItemAccess, replace: Bool) throws {
        try lock.synchronized {
            // Validate biometry support
            if access != .none {
                guard BiometryInfo.canUseBiometricAuthentication else {
                    throw KeychainError.biometryNotAvailable
                }
            }
            let useUpdate = replace ? try containsData(forKey: key) : false
            if useUpdate {
                try updateImpl(data, forKey: key)
            } else {
                try addImpl(data, forKey: key, access: access, replace: true)
            }
        }
    }
        
    func data(forKey key: String, authentication: KeychainPrompt?) throws -> Data? {
        try lock.synchronized {
            // Prepare query
            let queryBuilder = baseQuery()
                .returnData(forKey: key)
            if let authentication = authentication {
                guard BiometryInfo.canUseBiometricAuthentication else {
                    throw KeychainError.biometryNotAvailable
                }
                queryBuilder.set(prompt: authentication)
            }
            let query = try queryBuilder.build()
            // Execute query
            var result: AnyObject?
            let status = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query, UnsafeMutablePointer($0))
            }
            // Process result
            guard status == errSecSuccess else {
                switch KeychainError.SecurityFrameworkError.from(status: status) {
                    case .itemNotFound:
                        return nil
                    case .interactionRequired:
                        throw KeychainError.missingAuthentication
                    case .interactionNotAllowed:
                        throw KeychainError.disabledAuthentication
                    case .userCanceled:
                        throw KeychainError.userCancel
                    case .authFailed:
                        // FaceID permission not granted, or other authentication failure
                        throw KeychainError.biometryNotAvailable
                    default:
                        break
                }
                throw KeychainError.wrap(secError: status)
            }
            guard let data = result as? Data else {
                throw KeychainError.other(reason: .unexpectedResultType)
            }
            return data
        }
    }
    
    func containsData(forKey key: String) throws -> Bool {
        try lock.synchronized {
            let query = try baseQuery()
                .set(key: key)
                .setNoUI()
                .build()
            
            var result: AnyObject?
            let status = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query, UnsafeMutablePointer($0))
            }
            if status == errSecSuccess ||
                status == errSecInteractionNotAllowed {
                return true
            } else if status == errSecItemNotFound ||
                status == errSecUnimplemented ||
                status == errSecUserCanceled ||
                status == errSecNotAvailable {
                return false
            }
            throw KeychainError.wrap(secError: status)
        }
    }
    
    func remove(forKey key: String) throws {
        try lock.synchronized {
            let query = try baseQuery()
                .set(key: key)
                .build()
            let status = SecItemDelete(query)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.wrap(secError: status)
            }
        }
    }
    
    func removeAll() throws {
        try lock.synchronized {
            // TODO: this looks like a bug, we need to test it whether access group is required or not.
            let query = try baseQuery(skipAccessGroup: true)
                .build()
            let status = SecItemDelete(query)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.wrap(secError: status)
            }
        }
    }
    
    
    
    // MARK: - Internals -
    
    /// Update data for already existing item in keychain. The item for the given key must exist in the underlying keychain.
    /// - Parameters:
    ///   - data: Data to store to keychain.
    ///   - key: Key to store data.
    /// - Throws:
    ///   - `KeychainError.changedFromElsewhere` if data is not present in underlying keychain.
    ///   - `KeychainError.other()` for all other underlying failures.
    private func updateImpl(_ data: Data, forKey key: String) throws {
        // Update an existing data
        let query = try baseQuery()
            .set(data: data, forKey: key)
            .build()
        let dataToUpdate = try QueryBuilder()
            .set(data: data, forKey: key)
            .set(access: .none)
            .build()
        // Execute update query
        let status = SecItemUpdate(query, dataToUpdate)
        // Process result
        guard status == errSecSuccess else {
            switch KeychainError.SecurityFrameworkError.from(status: status) {
                case .itemNotFound:
                    // This is weird, looks like the content of keychain has been removed from elsewhere.
                    // We know this, because update function is used only when item is already set in the keychain.
                    // This may sometime happen when keychain shared between multiple applications, or application
                    // extensions is used.
                    throw KeychainError.changedFromElsewhere
                default:
                    break
            }
            // Otherwise wrap an error.
            throw KeychainError.wrap(secError: status)
        }
    }
    
    /// Add data to keychain. The item for the given key must not exist in the underlying keychain.
    /// - Parameters:
    ///   - data: Data to store to keychain.
    ///   - key: Key to store data.
    ///   - access: Type of protection of stored item.
    ///   - replace: Affects type of err
    /// - Throws:
    ///   - `KeychainError.itemExists` if `replace` parameter is `false` and if data is already present in underlying keychain.
    ///   - `KeychainError.changedFromElsewhere` if `replace` parameter is `true` and  data is already present in underlying keychain.
    ///   - `KeychainError.other()` for all other underlying failures.
    private func addImpl(_ data: Data, forKey key: String, access: KeychainItemAccess, replace: Bool) throws {
        // Simply add data
        let query = try baseQuery()
            .set(data: data, forKey: key)
            .set(access: access)
            .build()
        // Execute add query
        let status = SecItemAdd(query, nil)
        // Process result
        guard status == errSecSuccess else {
            switch KeychainError.SecurityFrameworkError.from(status: status) {
                case .duplicateItem:
                    if replace {
                        // This is weird, looks like the content of keychain has been changed from elsewhere.
                        // We know this, because update function is used only when item is not set in the keychain.
                        // This may sometime happen when keychain shared between multiple applications, or application
                        // extensions is used.
                        throw KeychainError.changedFromElsewhere
                    } else {
                        // Replace was not requested by application, so return `itemExists` error in such case.
                        throw KeychainError.itemExists
                    }
                default:
                    break
            }
            // Otherwise wrap an error.
            throw KeychainError.wrap(secError: status)
        }
    }
    
    /// Returns internal `QueryBuilder` with base query for Sec* operations. The base query contains identification of keychain,
    /// and access group, if group is specified.
    /// - Parameter skipAccessGroup: If `true` then configured access group is not added to base query. The default value is `false`.
    /// - Returns: Dictionary with base query specific for this keychain setup.
    private func baseQuery(skipAccessGroup: Bool = false) -> QueryBuilder {
        // Skip access group on simulators.
        if !(skipAccessGroup || SystemInfo.isSimulator), let accessGroup = accessGroup {
            return QueryBuilder(with: [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: identifier,
                kSecAttrAccessGroup: accessGroup])
        } else {
            return QueryBuilder(with: [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: identifier])
        }
     }
}

// MARK: - Query builder


/// The `QueryBuilder` class helps to construct database queries for Keychain services.
fileprivate class QueryBuilder {
    
    /// Dictionary type representing a database query for Keychain services.
    typealias Query = [CFString:Any]
    
    /// Content of query
    var query: Query
    
    var noUI = false
    var usePrompt = false
    var returnData = false
    var key: String?
    var data: Data?
    var access: KeychainItemAccess?
    
    
    /// Initialize query builder with base query.
    /// - Parameter query: Base query to set to builder. If not provided, then empty dictionary is applied.
    init(with query: Query = [:]) {
        self.query = query
    }
    
    /// Build final dictionary from query parameters.
    /// - Throws:
    ///   - `KeychainError.invalidKey` in case you provide an invalid or empty key.
    ///   - `KeychainError.other` in case that internal object creation failed.
    /// - Returns: `CFDictionary` type with query content.
    func build() throws -> CFDictionary {
        
        #if DEBUG
        // Inernal sanity check
        if usePrompt && noUI {
            D.fatalError("Prompt cannot be combined with noUI")
        }
        if returnData && data != nil {
            D.fatalError("returnData option cannot be combied with data")
        }
        #endif
        
        // Build final query
        if returnData {
            query[kSecReturnData] = kCFBooleanTrue
        }
        if let key = key {
            guard !key.isEmpty else {
                throw KeychainError.invalidKey
            }
            query[kSecAttrAccount] = key
        }
        if let data = data {
            query[kSecValueData] = data
        }
        if let access = access {
            try implSet(access: access)
        }
        return query as CFDictionary
    }

    /// Alternate query to retrieve data for given key.
    /// - Parameter key: Key to identify stored data.
    /// - Returns: `QueryBuilder` instance.
    @discardableResult
    func returnData(forKey key: String) -> QueryBuilder {
        returnData = true
        self.key = key
        return self
    }
    
    /// Alternate query to identify key to address data. This is useful for queries that doesn't
    /// return data but require key to identify item, for example for data removal.
    /// - Parameter key: Key to identify stored data.
    /// - Returns: `QueryBuilder` instance.
    @discardableResult
    func set(key: String) -> QueryBuilder {
        self.key = key
        return self
    }
    
    /// Alternate query to set data for given key.
    /// - Parameters:
    ///   - data: Data to set to keychain.
    ///   - key: Key to identify stored data.
    /// - Returns: `QueryBuilder` instance.
    @discardableResult
    func set(data: Data, forKey key: String) -> QueryBuilder {
        self.key = key
        self.data = data
        return self
    }
    
    /// Alternate query by setting type of item access protection.
    /// - Parameter access: Type of item access protection.
    /// - Returns: `QueryBuilder` instance.
    @discardableResult
    func set(access: KeychainItemAccess) -> QueryBuilder {
        self.access = access
        return self
    }
    
    #if os(iOS) || os(macOS)
    
    // MARK: - iOS + macOS specific
    
    /// Alternate query to fail when authentication dialog needs to be displayed.
    /// - Returns: `QueryBuilder` instance.
    @discardableResult
    func setNoUI() -> QueryBuilder {
        noUI = true
        if #available(macOS 10.15, iOS 11.0, *) {
            let context = LAContext()
            context.interactionNotAllowed = true
            query[kSecUseAuthenticationContext] = context
        } else {
            query[kSecUseAuthenticationUI] = kSecUseAuthenticationUIFail
        }
        return self
    }
    
    /// Alternate query with provided prompt for biometric authentication dialog.
    /// - Parameter prompt: `KeychainPrompt` structure.
    /// - Returns: `QueryBuilder` instance.
    @discardableResult
    func set(prompt: KeychainPrompt) -> QueryBuilder {
        usePrompt = true
        if #available(iOS 11.0, *) {
            if let context = prompt.asLAContext {
                query[kSecUseAuthenticationContext] = context
                return self
            }
        }
        query[kSecUseOperationPrompt] = prompt.prompt
        return self
    }
    
    /// Alternate query by adding `SecAccessControlObject` with protection level required for this item.
    /// - Parameter access: Type of item access protection.
    /// - Throws: `KeychainError.other` - in case that SAC object cannot be created.
    private func implSet(access: KeychainItemAccess) throws {
        //
        // Workaround for bug in iOS13 simulator (Xcode 11)
        //
        // iOS13 simulator are not able to store the data to keychain when AC object is present in the query.
        // In this case, we simply skip this step.
        //
        // Associated ticket: https://github.com/wultra/powerauth-mobile-sdk/issues/248
        //
        #if targetEnvironment(simulator)
        if #available(iOS 13.0, *) {
            return
        }
        #endif
        // Create the Access Control Object telling how the value should be stored.
        let sacFlags = access.biometryAccessControlFlags
        guard let sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, sacFlags, nil) else {
            D.error("Failed to create SecAccessControl object")
            throw KeychainError.other(reason: .failedToCraeteAccessControlObject)
        }
        query[kSecAttrAccessControl] = sacObject
    }
    
    #else
    
    // MARK: - Fallbacks
    
    /// Alternate query to fail when authentication dialog needs to be displayed.
    /// - Returns: `QueryBuilder` instance.
    @discardableResult
    func setNoUI() -> QueryBuilder {
        noUI = true
        return self
    }
    
    /// Alternate query with provided prompt for biometric authentication dialog.
    /// - Parameter prompt: `KeychainPrompt` structure.
    /// - Returns: `QueryBuilder` instance.
    @discardableResult
    func set(prompt: KeychainPrompt) -> QueryBuilder {
        usePrompt = true
        return self
    }
    
    /// Alternate query by adding `SecAccessControlObject` with protection level required for this item.
    /// - Parameter access: Type of item access protection.
    /// - Throws: `KeychainError.other` - in case that SAC object cannot be created.
    @discardableResult
    func implSet(access: KeychainItemAccess) throws {
        // Empty on purpose
    }
    #endif
    
}

fileprivate extension KeychainItemAccess {
    #if os(iOS) || os(macOS)
    /// Convert `KeychainItemAccess` into `SecAccessControlCreateFlags`.
    var biometryAccessControlFlags: SecAccessControlCreateFlags {
        switch self {
            case .anyBiometricSet:
                if #available(macOS 10.15, iOS 11.3, *) {
                    return .biometryAny
                } else {
                    return .touchIDAny
                }
            case .anyBiometricSetOrDevicePasscode:
                return .userPresence
            case .currentBiometricSet:
                if #available(macOS 10.15, iOS 11.3, *) {
                    return .biometryCurrentSet
                } else {
                    return .touchIDCurrentSet
                }
            case .none:
                // kNilOptions
                return SecAccessControlCreateFlags(rawValue: 0)
        }
    }
    #else
    /// Convert `KeychainItemAccess` into `SecAccessControlCreateFlags`.
    var biometryAccessControlFlags: SecAccessControlCreateFlags {
        SecAccessControlCreateFlags(rawValue: 0)    // kNilOptions
    }
    #endif
}

// MARK: - Errors

fileprivate extension KeychainError {
    
    /// Translate error code from `secErr` class of error codes into `KeychainError` object.
    /// - Parameter secError: Error code to translate
    /// - Returns: Appropriate `KeychainError` object
    static func wrap(secError: OSStatus) -> KeychainError {
        if let secError = KeychainError.SecurityFrameworkError.from(status: secError) {
            // Wrap known security error into other reason.
            return KeychainError.other(reason: .securityFramework(error: secError))
        } else {
            // Otherwise wrap OSCode into other resason.
            return KeychainError.other(reason: .securityFrameworkOther(errorCode: secError))
        }
    }
    
}
