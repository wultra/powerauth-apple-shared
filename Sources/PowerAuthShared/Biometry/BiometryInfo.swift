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

/// The `BiometryInfo` structure contains information about
/// supported type of biometry and its current status on the system.
public struct BiometryInfo {
    
    /// Enum encapsulating supported biometric authentication types.
    public enum BiometryType {
        /// Biometric authentication is not supported on the current system.
        case none
        /// Touch ID is supported on the current system.
        case touchID
        /// Face ID is supported on the current system.
        case faceID
    }
    
    /// Enum encapsulating status of biometric authentication on the system.
    public enum BiometryStatus {
        /// Biometric authentication is not present on the system.
        case notSupported
        /// Biometric authentication is available on the system, but for an unknown
        /// reason is not available right now. This may happen on iOS 11+, when an
        /// unknown error is returned from `LAContext.canEvaluatePolicy()`.
        case notAvailable
        /// Biometric authentication is supported, but not enrolled on the system.
        case notEnrolled
        /// Biometric authentication is supported, but too many failed attempts caused its lockout.
        /// User has to authenticate with the password or passcode.
        case lockout
        /// Biometric authentication is supported and can be evaluated on the system.
        case available
    }

    /// Type of supported biometric authentication on the system.
    public let biometryType: BiometryType

    /// Current status of supported biometry on the system.
    public let currentStatus: BiometryStatus
}


public extension BiometryInfo {
    
    /// Convenience static property that checks if biometry can be used on the current system.
    ///
    /// Note that the property contains `false` also if biometry is not enrolled or if it has been locked down.
    /// To distinguish between an availability and lockdown you can use `BiometryInfo.current.currentStatus` static property.
    static var canUseBiometricAuthentication: Bool {
        current.currentStatus == .available
    }
    
    /// Convenience static property that returns supported biometry type on the current system.
    ///
    /// Note that the property contains `.none` also if biometry is not enrolled or if it has been locked down.
    /// To distinguish between an availability and lockdown you can use `biometricAuthenticationInfo` static property.
    static var supportedBiometricAuthentication: BiometryInfo.BiometryType {
        current.biometryType
    }
}
