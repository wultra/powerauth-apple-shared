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

final class KeychainFactoryTests: TestCase {
    
    let keychainName1 = "com.wultra.powerAuthShared.keychain1"
    let keychainName2 = "com.wultra.powerAuthShared.keychain2"
    let keychainName3 = "com.wultra.powerAuthShared.keychain3"
    
    let accessGroup1 = "com.wultra.powerAuthShared.accessGroup1"
    let accessGroup2 = "com.wultra.powerAuthShared.accessGroup2"
    
    let name = "KeychainFactoryTests"
    let isInteractive = false
    
    func run(with monitor: TestMonitor) throws {
        try testFactory()
        try testInvalidAccessGroup()
        try testInvalidateKeychains()
        try testReleaseFactory()
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
}
