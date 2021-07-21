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

class CommonKeychainTests: BaseTestCase {
    
    let keychainIdentifier = "testKeychain.CommonKeychainTests"
    
    override init(testCaseName: String, interactive: Bool) {
        super.init(testCaseName: testCaseName, interactive: interactive)
        // Doesn't require user's interaction
        register(methodName: "testStoreRestoreData") { try self.testStoreRestoreData(monitor: $0) }
        register(methodName: "testMissingAuthentication") { try self.testMissingAuthentication(monitor: $0) }
        register(methodName: "testDisabledAuthentication") { try self.testDisabledAuthentication(monitor: $0) }
        register(methodName: "testUpdateProtectedItem") { try self.testUpdateProtectedItem(monitor: $0) }
        register(methodName: "testUpdateAndProtect") { try self.testUpdateAndProtect(monitor: $0) }
        // Requires user's interaction
        register(methodName: "testBiometricAuthentication") { try self.testBiometricAuthentication(monitor: $0) }
        register(methodName: "testBiometricAuthenticationWithContext") { try self.testBiometricAuthenticationWithContext(monitor: $0) }
        register(methodName: "testCancelBiometricAuthentication") { try self.testCancelBiometricAuthentication(monitor: $0) }
        register(methodName: "testFailedBiometricAuthentication") { try self.testFailedBiometricAuthentication(monitor: $0) }
        register(methodName: "testNoBiometrySupport") { try self.testNoBiometrySupport(monitor: $0) }
        register(methodName: "testBiometryLockout") { try self.testBiometryLockout(monitor: $0) }
        register(methodName: "testNoEnrolledBiometry") { try self.testNoEnrolledBiometry(monitor: $0) }
        register(methodName: "testNoAvailableBiometry") { try self.testNoAvailableBiometry(monitor: $0) }
    }
    
    /// Return keychain from external provider. Subclass must implement this method.
    /// - Parameters:
    ///   - testName: Name of test to be executed.
    ///   - monitor: `TestMonitor` to capture other types of errors.
    /// - Throws: Error in case of failure.
    /// - Returns: Keychain instance or nil if test cannot be executed right now. The returned keychain must be empty.
    open func getKeychain(forTest testName: String, monitor: TestMonitor, biometry: BiometryInfo.BiometryStatus = .available) throws -> Keychain? {
        D.fatalError("Subclass must provide own `getKeychain()` method implementation.")
    }
    
    // MARK: - Without authentication
    
    
    /// Test for basic operations.
    func testStoreRestoreData(monitor: TestMonitor) throws {
        guard let keychain = try getKeychain(forTest: "testStoreRestoreData", monitor: monitor) else {
            return
        }
        try commonNonInteractiveTests(keychain: keychain, monitor: monitor)
    }
    
    /// Function implements tests for common behavior for operations that must work in all cases.
    private func commonNonInteractiveTests(keychain: Keychain, monitor: TestMonitor) throws {
        let randomData1 = Data.random(count: 128)
        let randomData2 = Data.random(count: 128)
        let randomData3 = Data.random(count: 128)
        
        try keychain.set(randomData1, forKey: "Key1")
        try keychain.set(randomData2, forKey: "Key2")
        
        try assertEqual(randomData1, try keychain.data(forKey: "Key1"))
        try assertEqual(randomData2, try keychain.data(forKey: "Key2"))
        
        try assertTrue(try keychain.containsData(forKey: "Key1"))
        try assertTrue(try keychain.containsData(forKey: "Key2"))
        try assertFalse(try keychain.containsData(forKey: "Key-Unknown"))
        
        try keychain.remove(forKey: "Key1")
        
        try assertFalse(try keychain.containsData(forKey: "Key1"))
        try assertTrue(try keychain.containsData(forKey: "Key2"))
        try assertFalse(try keychain.containsData(forKey: "Key-Unknown"))
        
        try keychain.removeAll()
        
        try assertFalse(try keychain.containsData(forKey: "Key1"))
        try assertFalse(try keychain.containsData(forKey: "Key2"))
        try assertFalse(try keychain.containsData(forKey: "Key-Unknown"))

        try assertNil(try keychain.data(forKey: "Key3"))
        try assertEqual(randomData3, try keychain.data(forKey: "Key3", orSet: randomData3))
        try assertEqual(randomData3, try keychain.data(forKey: "Key3", orSet: randomData3))
        try assertEqual(randomData3, try keychain.data(forKey: "Key3"))

        do {
            try keychain.set(randomData1, forKey: "Key3", access: .none, replace: false)
            try alwaysFail()
        } catch KeychainError.itemExists {
        }
        
        try keychain.set(randomData1, forKey: "Key3", access: .none, replace: true)
        try assertEqual(randomData1, try keychain.data(forKey: "Key3"))
        
        try keychain.set(randomData2, forKey: "Key3")
        try assertEqual(randomData2, try keychain.data(forKey: "Key3"))
    }
    
    
    /// Test for accessing protected item with no prompt provided. The expected result is that `KeychainError.missingAuthentication` is reported.
    func testMissingAuthentication(monitor: TestMonitor) throws {
      
        guard let keychain = try getKeychain(forTest: "testMissingAuthentication", monitor: monitor) else {
            return
        }
        
        let randomData1 = Data.random(count: 128)
        let testKey = "AuthKey1"
        
        try [ KeychainItemAccess.anyBiometricSet, .anyBiometricSetOrDevicePasscode, .currentBiometricSet]
            .forEach { access in
                try keychain.remove(forKey: testKey)
                try keychain.set(randomData1, forKey: testKey, access: access)
                do {
                    _ = try keychain.data(forKey: testKey)
                    try alwaysFail()
                } catch KeychainError.missingAuthentication {
                }
            }
    }
    
    
    /// Test for accessing protected item with prompt, configured with `LAContext` with disabled interaction.
    /// The expected result is `KeychainError.disabledAuthentication` is reported.
    func testDisabledAuthentication(monitor: TestMonitor) throws {

        guard let keychain = try getKeychain(forTest: "testDisabledAuthentication", monitor: monitor) else {
            return
        }
        
        guard #available(iOS 11.0, macOS 10.15, *) else {
            D.error("--- \(name).testDisabledAuthentication require iOS 11, macOS 10.15 to run")
            return
        }
        
        let randomData1 = Data.random(count: 128)
        let testKey = "AuthKey2"
        
        try [ KeychainItemAccess.anyBiometricSet, .anyBiometricSetOrDevicePasscode, .currentBiometricSet]
            .forEach { access in
                try keychain.remove(forKey: testKey)
                try keychain.set(randomData1, forKey: testKey, access: access)
                do {
                    let context = LAContext()
                    context.localizedReason = "PowerAuthShared tests"
                    context.interactionNotAllowed = true
                    _ = try keychain.data(forKey: testKey, authentication: KeychainPrompt(with: context))
                    try alwaysFail()
                } catch KeychainError.disabledAuthentication {
                }
            }
    }
    
    /// Test for updating already protected item. The expected result is that it's not possible to update protected item and application
    /// must remove data first and then set new value.
    func testUpdateProtectedItem(monitor: TestMonitor) throws {
        
        guard let keychain = try getKeychain(forTest: "testUpdateProtectedItem", monitor: monitor) else {
            return
        }
        
        let randomData1 = Data.random(count: 128)
        let randomData2 = Data.random(count: 128)
        let testKey = "AuthKey3"
        
        try [ KeychainItemAccess.anyBiometricSet, .anyBiometricSetOrDevicePasscode, .currentBiometricSet]
            .forEach { access in
                try keychain.remove(forKey: testKey)
                try keychain.set(randomData1, forKey: testKey, access: access)
                do {
                    try keychain.set(randomData2, forKey: testKey, access: access)
                    try alwaysFail()
                } catch KeychainError.removeProtectedItemFirst {
                }
                do {
                    try keychain.set(randomData2, forKey: testKey, access: .none)
                    try alwaysFail()
                } catch KeychainError.removeProtectedItemFirst {
                }
            }
    }
    
    /// Test for access mode change from `none` to any type of `KeychainItemAccess` protection. The expected result is that
    /// changing protection from `none` to any other is allowed.
    func testUpdateAndProtect(monitor: TestMonitor) throws {
        
      guard let keychain = try getKeychain(forTest: "testUpdateAndProtect", monitor: monitor) else {
            return
        }
        
        let randomData1 = Data.random(count: 128)
        let randomData2 = Data.random(count: 128)
        
        let testKey = "AuthKey4"
        
        try [ KeychainItemAccess.anyBiometricSet, .anyBiometricSetOrDevicePasscode, .currentBiometricSet]
            .forEach { newAccess in
                try keychain.remove(forKey: testKey)
                try keychain.set(randomData1, forKey: testKey, access: .none)
                
                let stored = try keychain.data(forKey: testKey)
                try assertEqual(randomData1, stored)
                
                try keychain.set(randomData2, forKey: testKey, access: .anyBiometricSet)
                do {
                    _ = try keychain.data(forKey: testKey)
                    try alwaysFail()
                } catch KeychainError.missingAuthentication {
                }
            }
    }

    // MARK: - With authentication
    
    
    /// Test for accessing a biometry protected data with using standard `KeychainPrompt` structure.
    func testBiometricAuthentication(monitor: TestMonitor) throws {
        
        guard let keychain = try getKeychain(forTest: "testBiometricAuthentication", monitor: monitor) else {
            return
        }
        
        let testData: [(testKey: String, access: KeychainItemAccess, data: Data)] = [
            ("AuthKey5-1", .anyBiometricSet, .random(count: 16)),
            ("AuthKey5-2", .anyBiometricSetOrDevicePasscode, .random(count: 16)),
            ("AuthKey5-3", .currentBiometricSet, .random(count: 16))
        ]
        // Setup data
        try testData.forEach { (testKey, access, data) in
            try keychain.set(data, forKey: testKey, access: access)
        }
        
        // Don't reuse prompt.
        
        // Query for data
        try testData.forEach { (testKey, access, data) in
            monitor.promptForInteraction("Authenticate with biometry to get \(access) protected data")
            let prompt = KeychainPrompt(with: "Please authenticate with biometry")
            let receivedData = try keychain.data(forKey: testKey, authentication: prompt)
            try assertEqual(data, receivedData)
        }
        
        // Reuse one prompt data
        monitor.promptForInteraction("Authenticate with biometry to get multiple protected data")
        let prompt = KeychainPrompt(with: "Please authenticate with biometry", reuseDuration: 5.0)
        
        // Query for data
        try testData.forEach { (testKey, access, data) in
            let receivedData = try keychain.data(forKey: testKey, authentication: prompt)
            try assertEqual(data, receivedData)
        }
        
        // Set too long reuse duration
        try testData.forEach { (testKey, access, data) in
            do {
                let prompt = KeychainPrompt(with: "Please authenticate with biometry", reuseDuration: LATouchIDAuthenticationMaximumAllowableReuseDuration + 1)
                _ = try keychain.data(forKey: testKey, authentication: prompt)
                try alwaysFail()
            } catch KeychainError.other(let reason) {
                if case KeychainError.OtherReason.reuseDurationTooLong = reason {} else {
                    try alwaysFail()
                }
            }
        }
    }
    
    /// Test for accessing a biometry protected data with using custom `KeychainPrompt` created from `LAContext`.
    func testBiometricAuthenticationWithContext(monitor: TestMonitor) throws {
        
        guard let keychain = try getKeychain(forTest: "testBiometricAuthenticationWithContext", monitor: monitor) else {
            return
        }
        
        guard #available(iOS 11.0, macOS 10.15, *) else {
            D.error("--- \(name).testBiometricAuthenticationWithContext require iOS 11, macOS 10.15 to run")
            return
        }
        
        let testData: [(testKey: String, access: KeychainItemAccess, data: Data)] = [
            ("AuthKey6-1", .anyBiometricSet, .random(count: 16)),
            ("AuthKey6-2", .anyBiometricSetOrDevicePasscode, .random(count: 16)),
            ("AuthKey6-3", .currentBiometricSet, .random(count: 16))
        ]
        // Setup data
        try testData.forEach { (testKey, access, data) in
            try keychain.set(data, forKey: testKey, access: access)
        }
        
        // Don't reuse prompt
        
        // Query for data
        try testData.forEach { (testKey, access, data) in
            monitor.promptForInteraction("Authenticate with biometry to get \(access) protected data")
            let laContext = LAContext()
            laContext.localizedReason = "Please authenticate with biometry with LAContext"
            let prompt = KeychainPrompt(with: laContext)
            let receivedData = try keychain.data(forKey: testKey, authentication: prompt)
            try assertEqual(data, receivedData)
        }
        
        // Reuse one prompt data
        
        monitor.promptForInteraction("Authenticate with biometry to get multiple protected data")
        
        let laContext = LAContext()
        laContext.localizedReason = "Please authenticate with biometry with LAContext"
        laContext.touchIDAuthenticationAllowableReuseDuration = 5
        let prompt = KeychainPrompt(with: laContext)
        
        // Query for data
        try testData.forEach { (testKey, access, data) in
            let receivedData = try keychain.data(forKey: testKey, authentication: prompt)
            try assertEqual(data, receivedData)
        }
        
        // Set too long reuse duration
        try testData.forEach { (testKey, access, data) in
            do {
                let laContext = LAContext()
                laContext.localizedReason = "Please authenticate with biometry with LAContext"
                laContext.touchIDAuthenticationAllowableReuseDuration = LATouchIDAuthenticationMaximumAllowableReuseDuration + 1
                let prompt = KeychainPrompt(with: laContext)
                _ = try keychain.data(forKey: testKey, authentication: prompt)
                try alwaysFail()
            } catch KeychainError.other(let reason) {
                if case KeychainError.OtherReason.reuseDurationTooLong = reason {} else {
                    try alwaysFail()
                }
            }
        }
    }
    
    /// Test for accessing a biometry protected data, but user must cancel authentication dialog.
    func testCancelBiometricAuthentication(monitor: TestMonitor) throws {
        
        guard let keychain = try getKeychain(forTest: "testCancelBiometricAuthentication", monitor: monitor) else {
            return
        }
        
        let randomData1 = Data.random(count: 18)
        let testKey = "AuthKey7"
        
        try keychain.set(randomData1, forKey: testKey, access: .anyBiometricSetOrDevicePasscode)
        do {
            monitor.promptForInteraction("Please cancel authentication dialog", wait: .long)
            _ = try keychain.data(forKey: testKey, authentication: KeychainPrompt(with: "Please authenticate"))
            try alwaysFail()
        } catch KeychainError.userCancel {
        }
    }
    
    /// Test for accessing a biometry protected data, but user must fail in authentication dialog.
    func testFailedBiometricAuthentication(monitor: TestMonitor) throws {
        
        guard let keychain = try getKeychain(forTest: "testFailedBiometricAuthentication", monitor: monitor) else {
            return
        }
        
        let randomData1 = Data.random(count: 18)
        let testKey = "AuthKey8"
        
        try keychain.set(randomData1, forKey: testKey, access: .anyBiometricSet)
        do {
            monitor.promptForInteraction("Please fail an authentication dialog", wait: .long)
            _ = try keychain.data(forKey: testKey, authentication: KeychainPrompt(with: "Please authenticate"))
            try alwaysFail()
        } catch KeychainError.authenticationFailed {
        }
    }
    
    // MARK: - Biometry not available
    
    /// Common function that tests keychain when biometry is not available.
    private func biometryUnavailableTests(keychain: Keychain, monitor: TestMonitor) throws {
        try commonNonInteractiveTests(keychain: keychain, monitor: monitor)
        
        let randomData1 = Data.random(count: 48)
        let testKey = "AuthKey8"
        
        try [ KeychainItemAccess.anyBiometricSet, .anyBiometricSetOrDevicePasscode, .currentBiometricSet]
            .forEach { access in
                do {
                    try keychain.set(randomData1, forKey: testKey, access: access)
                    try alwaysFail()
                } catch KeychainError.biometryNotAvailable {
                }
            }
    }
    
    func testNoBiometrySupport(monitor: TestMonitor) throws {
        guard let keychain = try getKeychain(forTest: "testNoBiometrySupport", monitor: monitor, biometry: .notSupported) else {
            return
        }
        try biometryUnavailableTests(keychain: keychain, monitor: monitor)
    }
    
    func testBiometryLockout(monitor: TestMonitor) throws {
        guard let keychain = try getKeychain(forTest: "testBiometryLockout", monitor: monitor, biometry: .lockout) else {
            return
        }
        try biometryUnavailableTests(keychain: keychain, monitor: monitor)
    }
    
    func testNoEnrolledBiometry(monitor: TestMonitor) throws {
        guard let keychain = try getKeychain(forTest: "testNoEnrolledBiometry", monitor: monitor, biometry: .notEnrolled) else {
            return
        }
        try biometryUnavailableTests(keychain: keychain, monitor: monitor)
    }
    
    func testNoAvailableBiometry(monitor: TestMonitor) throws {
        guard let keychain = try getKeychain(forTest: "testNoAvailableBiometry", monitor: monitor, biometry: .notAvailable) else {
            return
        }
        try biometryUnavailableTests(keychain: keychain, monitor: monitor)
    }
}
