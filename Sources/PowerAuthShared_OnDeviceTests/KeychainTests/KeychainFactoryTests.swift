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

/// The `KeychainFactoryTests` implements tests of
final class KeychainFactoryTests: BaseTestCase {
    
    let keychainName1 = "com.wultra.powerAuthShared.keychain1"
    let keychainName2 = "com.wultra.powerAuthShared.keychain2"
    let keychainName3 = "com.wultra.powerAuthShared.keychain3"
    
    let accessGroup1 = "com.wultra.powerAuthShared.accessGroup1"
    let accessGroup2 = "com.wultra.powerAuthShared.accessGroup2"
    
    init() {
        super.init(testCaseName: "KeychainFactoryTests", interactive: false)
        register(methodName: "testFactory") { _ in try self.testFactory() }
        register(methodName: "testInvalidAccessGroup") { _ in try self.testInvalidAccessGroup() }
        register(methodName: "testInvalidateKeychains") { _ in try self.testInvalidateKeychains() }
        register(methodName: "testInvalidateKeychains") { _ in try self.testReleaseFactory() }
        register(methodName: "testRemoveContentOnFirstAccess") { _ in try self.testRemoveContentOnFirstAccess() }
    }
    
    func testFactory() throws {
        let factory = KeychainFactory(removeContentOnFirstAccess: false)
        let k1 = try factory.keychain(identifier: keychainName1)
        try assertEqual(keychainName1, k1.identifier)
        try assertNil(k1.accessGroup)
        let k2 = try factory.keychain(identifier: keychainName2)
        try assertEqual(keychainName2, k2.identifier)
        try assertNil(k2.accessGroup)
        let k3 = try factory.keychain(identifier: keychainName3, accessGroup: accessGroup1)
        try assertEqual(keychainName3, k3.identifier)
        try assertNotNil(k3.accessGroup)
        
        let k1Alt = try factory.keychain(identifier: keychainName1)
        try assertTrue(k1 === k1Alt)
        let k2Alt = try factory.keychain(identifier: keychainName2)
        try assertTrue(k2 === k2Alt)
        let k3Alt = try factory.keychain(identifier: keychainName3, accessGroup: accessGroup1)
        try assertTrue(k3 === k3Alt)
        
        factory.removeAllCachedInstances()
        
        let k1New = try factory.keychain(identifier: keychainName1)
        try assertFalse(k1 === k1New)
        let k2New = try factory.keychain(identifier: keychainName2)
        try assertFalse(k2 === k2New)
        let k3New = try factory.keychain(identifier: keychainName3, accessGroup: accessGroup1)
        try assertFalse(k3 === k3New)
    }
    
    func testInvalidAccessGroup() throws {
        let factory = KeychainFactory(removeContentOnFirstAccess: false)
        _ = try factory.keychain(identifier: keychainName1)
        _ = try factory.keychain(identifier: keychainName2, accessGroup: accessGroup2)
        // nil vs some
        do {
            _ = try factory.keychain(identifier: keychainName1, accessGroup: accessGroup1)
            try alwaysFail()
        } catch KeychainError.invalidAccessGroup {
            // Success
        }
        // Some vs nil
        do {
            _ = try factory.keychain(identifier: keychainName2)
            try alwaysFail()
        } catch KeychainError.invalidAccessGroup {
            // Success
        }
        // Some vs Another
        do {
            _ = try factory.keychain(identifier: keychainName2, accessGroup: accessGroup1)
            try alwaysFail()
        } catch KeychainError.invalidAccessGroup {
            // Success
        }
    }
    
    func testInvalidateKeychains() throws {
        let factory = KeychainFactory(removeContentOnFirstAccess: false)
        let k1 = try factory.keychain(identifier: keychainName1)
        try assertFalse(try k1.containsData(forKey: "DataNotFound"))
        factory.removeAllCachedInstances()
        do {
            _ = try k1.containsData(forKey: "DataNotFound")
            try alwaysFail()
        } catch KeychainError.other(let reason) {
            if case KeychainError.OtherReason.keychainInstanceNoLongerValid = reason {} else {
                try alwaysFail()
            }
        }
    }
    
    func testReleaseFactory() throws {
        let k1: Keychain
        do {
            // Instantiate factory in do-block, to release it at the end of block.`
            let factory = KeychainFactory(removeContentOnFirstAccess: false)
            k1 = try factory.keychain(identifier: keychainName1)
            try assertFalse(try k1.containsData(forKey: "DataNotFound"))
            // Trick compiler to do not release factory too soon
            _ = try factory.keychain(identifier: keychainName1)
        } catch {
            try alwaysFail()
        }
        do {
            _ = try k1.containsData(forKey: "DataNotFound")
            try alwaysFail()
        } catch KeychainError.other(let reason) {
            if case KeychainError.OtherReason.keychainInstanceNoLongerValid = reason {} else {
                try alwaysFail()
            }
        }
    }
    
    func testRemoveContentOnFirstAccess() throws {
        let randomData1 = Data.random(count: 16)
        let testKey = "PreserveKey"
        let factory1 = KeychainFactory(removeContentOnFirstAccess: true)
        
        let k1_1 = try factory1.keychain(identifier: keychainName1)
        try k1_1.set(randomData1, forKey: testKey)
        try assertEqual(randomData1, k1_1.data(forKey: testKey))
        
        // After clear, the content of newly created keychain instance should be preserved.
        // This tests whether `removeContentOnFirstAccess` option is properly implemented.
        
        factory1.removeAllCachedInstances()
        let k1_2 = try factory1.keychain(identifier: keychainName1)
        try assertFalse(k1_1 === k1_2) // must be different instance
        try assertEqual(randomData1, k1_2.data(forKey: testKey))
     
        // Now create a new factory, but with `removeContentOnFirstAccess` set to false
        // This simulates application restart.
        
        let factory2 = KeychainFactory(removeContentOnFirstAccess: false)
        let k1_3 = try factory2.keychain(identifier: keychainName1)
        try assertFalse(k1_1 === k1_3) // must be different instance
        try assertEqual(randomData1, k1_3.data(forKey: testKey))
        
        // Now create a new factory, but with `removeContentOnFirstAccess` set back to true
        
        let factory3 = KeychainFactory(removeContentOnFirstAccess: true)
        let k1_4 = try factory3.keychain(identifier: keychainName1)
        try assertFalse(k1_1 === k1_4) // must be different instance
        try assertNil(k1_4.data(forKey: testKey))
    }
}
