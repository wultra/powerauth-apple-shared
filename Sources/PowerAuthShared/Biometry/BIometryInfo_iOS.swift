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

#if os(iOS)
import Foundation
import LocalAuthentication

public extension BiometryInfo {
    /// Static property that returns full information about biometry on the system. The resturned structure contains
    /// information about supported type (Touch ID or Face ID) and also actual biometry status (N/A, not enrolled, etc.)
    static var current: BiometryInfo {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // If we can evaluate, then everything is quite simple.
            if #available(iOS 11.0, *) {
                // On iOS11, we can determine type of biometry
                return BiometryInfo(biometryType: context.biometryType.toSdkType, currentStatus: .available)
            } else {
                // No FaceID before iOS11, so it has to be TouchID
                return BiometryInfo(biometryType: .touchID, currentStatus: .available)
            }
        } else {
            // In case of error we cannot evaluate, but the type of biometry can be determined.
            let code = (error?.domain == LAErrorDomain ? error?.code : 0) ?? 0
            if #available(iOS 11.0, *) {
                // On iOS 11 its quite simple, we have type property available and status can be determined
                // from the error.
                let biometryType = context.biometryType.toSdkType
                let status: BiometryStatus
                if biometryType != .none {
                    if code == kLAErrorBiometryLockout {
                        status = .lockout
                    } else if code == kLAErrorBiometryNotEnrolled {
                        status = .notEnrolled
                    } else if code == kLAErrorBiometryNotAvailable {
                        status = .notAvailable
                    } else {
                        D.error("LAContext.canEvaluatePolicy() failed with error code \(code)")
                        status = .notAvailable
                    }
                } else {
                    // If type is "none", then status must be "notSupported"
                    status = .notSupported
                }
                return BiometryInfo(biometryType: biometryType, currentStatus: status)
            } else {
                // On older systems (iOS 9,10), only Touch ID is available.
                if code == kLAErrorBiometryLockout {
                    return BiometryInfo(biometryType: .touchID, currentStatus: .lockout)
                } else if code == kLAErrorBiometryNotEnrolled {
                    return BiometryInfo(biometryType: .touchID, currentStatus: .notEnrolled)
                }
            }
        }
        // Otherwise fallback to "none" and "notSUpported"
        return BiometryInfo(biometryType: .none, currentStatus: .notSupported)
    }
}

@available(iOS 11.0, *)
fileprivate extension LABiometryType {
    /// Convert `LABiometryType` to `BiometryInfo.BiometryType`
    var toSdkType: BiometryInfo.BiometryType {
        switch self {
            case .faceID:
                return .faceID
            case .touchID:
                return .touchID
            case .none:
                return .none
            default:
                D.error("Unknown LABiometryType value \(self)")
                return .none
        }
    }
}

#endif // #if os(iOS)
