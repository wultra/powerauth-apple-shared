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
#if os(iOS) || os(macOS)
        register(methodName: "testWithPreauthorizedLAContext") { try self.testWithPreauthorizedLAContext(monitor:$0) }
#endif
    }
    
    override func getKeychain(forTest testName: String, monitor: TestMonitor, biometry: BiometryInfo.BiometryStatus) throws -> Keychain? {
        
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
    
    // Exclute tests that require LAContext or authentication on tvOS and watchOS
    
    #if os(iOS) || os(macOS)
    func testWithPreauthorizedLAContext(monitor: TestMonitor) throws {
        guard let keychain = try getKeychain(forTest: "testWithPreauthorizedLAContext", monitor: monitor, biometry: .available) else {
            return
        }
        
        guard #available(iOS 11.0, macOS 10.15, *) else {
            D.error("--- \(name).testWithPreauthorizedLAContext require iOS 11, macOS 10.15 to run")
            return
        }
        
        let testData: [(testKey: String, access: KeychainItemAccess, data: Data)] = [
            ("AuthKeyA1-1", .anyBiometricSet, .random(count: 16)),
            ("AuthKeyA1-2", .anyBiometricSetOrDevicePasscode, .random(count: 16)),
            ("AuthKeyA1-3", .currentBiometricSet, .random(count: 16))
        ]
        // Setup data
        try testData.forEach { (testKey, access, data) in
            try keychain.set(data, forKey: testKey, access: access)
        }
        
        monitor.promptForInteraction("Please authenticate with biometry", wait: .long)
        let context = try AsyncHelper<LAContext>().waitForCompletion { helper in
            let context = LAContext()
            context.localizedReason = "Please authenticate with biometry with LAContext"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Please authenticate with biometry") { result, error in
                if result {
                    helper.complete(withObject: context)
                } else {
                    helper.complete(withError: error!)
                }
            }
        }

        let prompt = KeychainPrompt(with: context)
        
        // Query for data
        try testData.forEach { (testKey, access, data) in
            let receivedData = try keychain.data(forKey: testKey, authentication: prompt)
            try assertEqual(data, receivedData)
        }
        
        context.invalidate()
        
        // Query for data
        testData.forEach { (testKey, access, data) in
            do {
                _ = try keychain.data(forKey: testKey, authentication: prompt)
                try alwaysFail()
            } catch {
                // This is OK
            }
        }
    }
    #endif // os(iOS) || os(macOS)
}
