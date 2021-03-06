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

/// `KeychainError` is the error type returned by `PowerAuthShared` library.
public enum KeychainError: Error {
    
    /// `KeychainFactory` throws this error in case you getting `Keychain` with the same
    /// keychain identifier but with a different access group than last access. You must use
    /// the same access group for the same keychain identifier.
    case invalidAccessGroup
    
    /// The provided key is empty or its name is reserved.
    case invalidKey

    /// The data you're trying to store to the keychain already exists.
    case itemExists
    
    /// User did cancel authentication dialog.
    case userCancel
    
    /// User did fail to authenticate.
    case authenticationFailed
    
    /// The `KeychainPrompt` is required but not provided while getting data from the keychain.
    case missingAuthentication
    
    /// The `KeychainPrompt` contains `LAContext` with not allowed interaction, while getting data from the keychain.
    case disabledAuthentication
    
    /// Biometric authentication is not available right now on the device. You can use `BiometryInfo.current.currentStatus`
    /// to determine exact reason why this error happened.
    case biometryNotAvailable
  
    /// The content of keychain has been modified from elsewhere, typically from an another application, or process.
    /// This may happen when a keychain shared between multiple applications, or multiple application extensions is used.
    case changedFromElsewhere
    
    /// Setting a new value over the biometry protected item failed. You must remove such item first and then set a new value.
    case removeProtectedItemFirst
    
    /// The underlying failure reason for `.other(reason:)` error case.
    public enum OtherReason: Error {
        
        /// The Keychain instance has been invalidated by its parent factory. This error typically happens
        /// after you call `KeychainFactory.removeAllCachedInstances()` and keep your own reference to previously
        /// accessed keychain.
        case keychainInstanceNoLongerValid
        
        /// Failed to create internal Access Control object.
        case failedToCraeteAccessControlObject
        
        /// The provided `LAContext` contains too long reuse duration.
        case reuseDurationTooLong
        
        /// The data returned from the keychain has an unexpected type.
        case unexpectedResultType
        
        /// Underlying operation failed with given Security framework error. This case contains
        /// only important errors that can occur during interaction with the keychain. Other errors
        /// are covered by `.securityFrameworkOther(errorCode:)`.
        case securityFramework(error: SecurityFrameworkError)
        
        /// Other, less important errors produced by Securityt framework.
        case securityFrameworkOther(errorCode: OSStatus)
    }
    
    /// The underlying failure reason for `OtherReasons.securityFramework(error:)` mapped from `errSec*` group of errors. Note that
    /// this enumeration covers only errors that are important for interacting with underlying Keychain services.
    public enum SecurityFrameworkError: Error {
        case unimplemented /* Function or operation not implemented. */
        case diskFull /* The disk is full. */
        case IO /* I/O error. */
        case param /* One or more parameters passed to a function were not valid. */
        case wrPerm /* Write permissions error. */
        case allocate /* Failed to allocate memory. */
        case userCanceled /* User canceled the operation. */
        case badReq /* Bad parameter or invalid state for operation. */

        case missingEntitlement /* A required entitlement isn't present. */
        case restrictedAPI /* Client is restricted and is not permitted to perform this operation. */

        case notAvailable /* No keychain is available. You may need to restart your computer. */
        case readOnly /* This keychain cannot be modified. */
        case authFailed /* The user name or passphrase you entered is not correct. */
        
        case duplicateItem /* The specified item already exists in the keychain. */
        case itemNotFound /* The specified item could not be found in the keychain. */
        case bufferTooSmall /* There is not enough memory available to use the specified item. */
        case dataTooLarge /* This item contains information which is too large or in a format that cannot be displayed. */

        case noSuchAttr /* The specified attribute does not exist. */
        case noSuchClass /* The specified item does not appear to be a valid keychain item. */
        case noDefaultKeychain /* A default keychain could not be found. */

        case interactionNotAllowed /* User interaction is not allowed. */
        case interactionRequired /* User interaction is required, but is currently not allowed. */
        case dataNotAvailable /* The contents of this item cannot be retrieved. */
        case dataNotModifiable /* The contents of this item cannot be modified. */
        
        case noAccessForItem /* The specified item has no access control. */
        case decode /* Unable to decode the provided data. */
    }
    
    /// Operation failed with an unexpected error.
    case other(reason: OtherReason)
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .biometryNotAvailable:
                return "Biometric authentication is not available"
            case .invalidKey:
                return "Key is empty or contains reserved string"
            case .invalidAccessGroup:
                return "Invalid access group. You must use the same access group for the same keychain identifier"
            case .itemExists:
                return "Item exists"
            case .removeProtectedItemFirst:
                return "Remove protected item first, then set new data"
            case .userCancel:
                return "User did cancel authentication dialog"
            case .authenticationFailed:
                return "User did fail to authenticate"
            case .missingAuthentication:
                return "KeychainPrompt is required for accessing this item"
            case .disabledAuthentication:
                return "KeychainPrompt contains LAContext that prevents interactive authentication"
            case .changedFromElsewhere:
                return "The content was changed from elsewhere."
            case .other(let reason):
                return "Other failure: \(reason.localizedDescription)"
        }
    }
}

extension KeychainError.OtherReason: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .keychainInstanceNoLongerValid:
                return "Keychain instance is no longer valid"
            case .failedToCraeteAccessControlObject:
                return "Failed to create Access Control object"
            case .reuseDurationTooLong:
                return "KeychainPrompt or LAContext contains too long reuse duration"
            case .unexpectedResultType:
                return "Query returned an unexpected object"
            case .securityFrameworkOther(let errorCode):
                return "Security framework error: \(errorCode)"
            case .securityFramework(let error):
                return "Security framework error: \(error.localizedDescription)"
        }
    }
}

extension KeychainError.SecurityFrameworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .unimplemented             : return "errSecUnimplemented"
            case .diskFull                  : return "errSecDiskFull"
            case .IO                        : return "errSecIO"
            case .param                     : return "errSecParam"
            case .wrPerm                    : return "errSecWrPerm"
            case .allocate                  : return "errSecAllocate"
            case .userCanceled              : return "errSecUserCanceled"
            case .badReq                    : return "errSecBadReq"

            case .missingEntitlement        : return "errSecMissingEntitlement"
            case .restrictedAPI             : return "errSecRestrictedAPI"

            case .notAvailable              : return "errSecNotAvailable"
            case .readOnly                  : return "errSecReadOnly"
            case .authFailed                : return "errSecAuthFailed"

            case .duplicateItem             : return "errSecDuplicateItem"
            case .itemNotFound              : return "errSecItemNotFound"
            case .bufferTooSmall            : return "errSecBufferTooSmall"
            case .dataTooLarge              : return "errSecDataTooLarge"

            case .noSuchAttr                : return "errSecNoSuchAttr"
            case .noSuchClass               : return "errSecNoSuchClass"
            case .noDefaultKeychain         : return "errSecNoDefaultKeychain"
            
            case .interactionNotAllowed     : return "errSecInteractionNotAllowed"
            case .interactionRequired       : return "errSecInteractionRequired"
            case .dataNotAvailable          : return "errSecDataNotAvailable"
            case .dataNotModifiable         : return "errSecDataNotModifiable"
            
            case .noAccessForItem           : return "errSecNoAccessForItem"
            case .decode                    : return "errSecDecode"
        }
    }
}

extension KeychainError.SecurityFrameworkError {
    
    /// Translate `OSStatus` to `KeychainError.SecurityFrameworkError`
    /// - Parameter status: `OSStatus` constant to translate.
    /// - Returns: `KeychainError.SecurityFrameworkError` or nil if such constant doesn't fit our enum.
    static func from(status: OSStatus) -> KeychainError.SecurityFrameworkError? {
        switch status {
            case errSecUnimplemented:           return .unimplemented
            case errSecDiskFull:                return .diskFull
            case errSecIO:                      return .IO
            case errSecParam:                   return .param
            case errSecWrPerm:                  return .wrPerm
            case errSecAllocate:                return .allocate
            case errSecUserCanceled:            return .userCanceled
            case errSecBadReq:                  return .badReq
            case errSecMissingEntitlement:      return .missingEntitlement
            case errSecRestrictedAPI:           return .restrictedAPI
            case errSecNotAvailable:            return .notAvailable
            case errSecReadOnly:                return .readOnly
            case errSecAuthFailed:              return .authFailed
            case errSecDuplicateItem:           return .duplicateItem
            case errSecItemNotFound:            return .itemNotFound
            case errSecBufferTooSmall:          return .bufferTooSmall
            case errSecDataTooLarge:            return .dataTooLarge
            case errSecNoSuchAttr:              return .noSuchAttr
            case errSecNoSuchClass:             return .noSuchClass
            case errSecNoDefaultKeychain:       return .noDefaultKeychain
            case errSecInteractionNotAllowed:   return .interactionNotAllowed
            case errSecInteractionRequired:     return .interactionRequired
            case errSecDataNotAvailable:        return .dataNotAvailable
            case errSecDataNotModifiable:       return .dataNotModifiable
            case errSecNoAccessForItem:         return .noAccessForItem
            case errSecDecode:                  return .decode
            default:
                return nil
        }
    }
}
