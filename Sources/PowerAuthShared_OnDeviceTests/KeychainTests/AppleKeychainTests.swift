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
import LocalAuthentication

class AppleKeychainTests: CommonKeychainTests {
    
    static let factory = KeychainFactory(removeContentOnFirstAccess: true)

    init() {
        super.init(testCaseName: "AppleKeychainTests", interactive: true)
    }
    
    override func getKeychain(forTest testName: String, monitor: TestMonitor, biometry: BiometryInfo.BiometryStatus) throws -> Keychain? {
        
        D.print("--- \(name).\(testName)")
        
        let bi = BiometryInfo.current

        if biometry != bi.currentStatus {
            monitor.warning("\(name).\(testName) requires \(biometry) biometry status")
            return nil
        }
        
        switch testName {
            case "testFailedBiometricAuthentication":
                guard bi.biometryType == .touchID else {
                    monitor.warning("\(name).\(testName) requires touchID to simulate failure.")
                    return nil
                }
            default:
                break
        }
        return try AppleKeychainTests.factory.keychain(identifier: keychainIdentifier)
    }
}
