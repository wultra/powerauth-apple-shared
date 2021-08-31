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
import PowerAuthShared

/// The `FakeKeychainTests` run all common keychain tests on `FakeKeychain` implementation.
class FakeKeychainTests: CommonKeychainTests {

    let dumpOperations: Bool
    
    /// Initialize test with options.
    /// - Parameter dumpOperations: If `true` then fake keychain will dump all operations.
    init(dumpOperations: Bool) {
        self.dumpOperations = dumpOperations
        super.init(testCaseName: "FakeKeychainTests", interactive: false)
    }
    
    override func getKeychain(forTest testName: String, monitor: TestMonitor, biometry: BiometryInfo.BiometryStatus) throws -> Keychain? {
        
        let keychain = FakeKeychain(identifier: keychainIdentifier, dumpOperations: dumpOperations)
        
        switch testName {
            case "testCancelBiometricAuthentication":
                keychain.pushAuthenticationResult(.cancel)
            case "testFailedBiometricAuthentication":
                keychain.pushAuthenticationResult(.authError)
            default:
                break
        }
        if biometry != .available {
            keychain.setSimulatedBiometryStatus(biometry)
            keychain.setDefaultAuthenticationResult(.biometryNotAvailable)
        }
        return keychain
    }
}
