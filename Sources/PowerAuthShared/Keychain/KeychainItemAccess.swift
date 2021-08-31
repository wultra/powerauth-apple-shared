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

/// The `KeychainItemAccess` enumeration defines additional protection
/// of item stored in the keychain.
public enum KeychainItemAccess {
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
