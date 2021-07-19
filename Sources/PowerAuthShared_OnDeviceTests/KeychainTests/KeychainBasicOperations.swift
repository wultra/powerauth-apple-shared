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

class BasicKeychainOperations: TestCase {
    
    var name = "BasicKeychainOperations"
    
    let factory: KeychainFactory
    
    required init() throws {
        factory = KeychainFactory(removeContentOnFirstAccess: true)
    }
    
    func run() throws {
        try testStoreRestoreData()
        try testMissingAuthentication()
        try testDisabledAuthentication()
        try testUpdateProtectedItem()
        try testUpdateAndProtect()
    }
    
    func testStoreRestoreData() throws {
        
        D.print("--- \(name).testStoreRestoreData")
        
        let keychain = try factory.keychain(identifier: "testKeychain.BasicKeychainOperations")
        
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
    
    func testMissingAuthentication() throws {
        
        D.print("--- \(name).testMissingAuthentication")
        
        guard BiometryInfo.current.currentStatus == .available else {
            D.error("--- \(name).testMissingAuthentication require enrolled biometry")
            return
        }
        
        let keychain = try factory.keychain(identifier: "testKeychain.BasicKeychainOperations")
        let randomData1 = Data.random(count: 128)
        try keychain.set(randomData1, forKey: "AuthKey1", access: .anyBiometricSet)
        
        do {
            _ = try keychain.data(forKey: "AuthKey1")
            try alwaysFail()
        } catch KeychainError.missingAuthentication {
        }
        
        try keychain.remove(forKey: "AuthKey1")
        try keychain.set(randomData1, forKey: "AuthKey1", access: .currentBiometricSet)
        do {
            _ = try keychain.data(forKey: "AuthKey1")
            try alwaysFail()
        } catch KeychainError.missingAuthentication {
        }
    }
    
    func testDisabledAuthentication() throws {
        
        D.print("--- \(name).testDisabledAuthentication")
        
        guard BiometryInfo.current.currentStatus == .available else {
            D.error("--- \(name).testDisabledAuthentication require enrolled biometry")
            return
        }
        
        guard #available(iOS 13.0, macOS 10.15, *) else {
            D.error("--- \(name).testDisabledAuthentication require iOS 13, macOS 10.15 to run")
            return
        }
        
        let keychain = try factory.keychain(identifier: "testKeychain.BasicKeychainOperations")
        let randomData1 = Data.random(count: 128)
        try keychain.set(randomData1, forKey: "AuthKey2", access: .anyBiometricSet)
        
        do {
            let context = LAContext()
            context.localizedReason = "PowerAuthShared tests"
            context.interactionNotAllowed = true
            _ = try keychain.data(forKey: "AuthKey2", authentication: KeychainPrompt(with: context))
            try alwaysFail()
        } catch KeychainError.disabledAuthentication {
        }
        
        try keychain.remove(forKey: "AuthKey2")
        try keychain.set(randomData1, forKey: "AuthKey2", access: .currentBiometricSet)
        do {
            let context = LAContext()
            context.localizedReason = "PowerAuthShared tests"
            context.interactionNotAllowed = true
            _ = try keychain.data(forKey: "AuthKey2", authentication: KeychainPrompt(with: context))
            try alwaysFail()
        } catch KeychainError.disabledAuthentication {
        }
    }
    
    func testUpdateProtectedItem() throws {
        D.print("--- \(name).testUpdateProtectedItem")
        
        guard BiometryInfo.current.currentStatus == .available else {
            D.error("--- \(name).testUpdateWithNoAuth require enrolled biometry")
            return
        }
        
        let randomData1 = Data.random(count: 128)
        let randomData2 = Data.random(count: 128)
        
        let keychain = try factory.keychain(identifier: "testKeychain.BasicKeychainOperations")
        try keychain.set(randomData1, forKey: "AuthKey3", access: .anyBiometricSet)
        do {
            try keychain.set(randomData2, forKey: "AuthKey3", access: .anyBiometricSet)
        } catch KeychainError.removeProtectedItemFirst {
        }
    }

    func testUpdateAndProtect() throws {
        D.print("--- \(name).testUpdateWithNoAuth")
        
        guard BiometryInfo.current.currentStatus == .available else {
            D.error("--- \(name).testUpdateWithNoAuth require enrolled biometry")
            return
        }
        
        let randomData1 = Data.random(count: 128)
        let randomData2 = Data.random(count: 128)
        
        let keychain = try factory.keychain(identifier: "testKeychain.BasicKeychainOperations")
        try keychain.set(randomData1, forKey: "AuthKey4", access: .none)
        
        let stored = try keychain.data(forKey: "AuthKey4")
        try assertEqual(randomData1, stored)
        
        try keychain.set(randomData2, forKey: "AuthKey4", access: .anyBiometricSet)
        do {
            _ = try keychain.data(forKey: "AuthKey4")
            try alwaysFail()
        } catch KeychainError.missingAuthentication {
        }
    }
}
