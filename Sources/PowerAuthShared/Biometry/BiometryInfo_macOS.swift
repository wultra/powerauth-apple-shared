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

#if os(macOS)
import Foundation
import LocalAuthentication

public extension BiometryInfo {
    /// Static property that returns full information about biometry on the system. The resturned structure contains
    /// information about supported type (Touch ID or Face ID) and also actual biometry status (N/A, not enrolled, etc.)
    /// Note that if process is running in limited sandbox, such as application extension do, then property always contain
    /// `BiometryInfo(biometryType: .none, currentStatus: .notSupported)`.
    static var current: BiometryInfo {
        // Check if we're running in app extension context.
        if SystemInfo.current.isAppExtension {
            return BiometryInfo(biometryType: .none, currentStatus: .notSupported)
        }
        // The rest is much simpler on macOS than on iOS, due to we support 10.15+, where LAContext
        // already supports the required functionality.
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        let biometryType = context.biometryType.toSdkType
        let status: BiometryStatus
        if canEvaluate {
            // Can evaluate, so status is `available`
            status = .available
        } else if biometryType == .none {
            // If type is "none", then status must be "notSupported"
            status = .notSupported
        } else {
            // Evaluate error
            let code = (error?.domain == LAErrorDomain ? error?.code : 0) ?? 0
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
        }
        return BiometryInfo(biometryType: biometryType, currentStatus: status)
    }
}

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

#endif // #if os(macOS)
