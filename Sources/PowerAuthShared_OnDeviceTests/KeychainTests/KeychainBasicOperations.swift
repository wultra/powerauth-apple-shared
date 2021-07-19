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

class BasicKeychainOperations: TestCase {
    
    var name = "BasicKeychainOperations"
    
    let factory: KeychainFactory
    
    required init() throws {
        factory = KeychainFactory(removeContentOnFirstAccess: true)
    }
    
    func run() throws {
        try testStoreRestoreData()
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

}
