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
import LocalAuthentication

/// Class implementing `PowerAuthKeychain` protocol on Apple platforms.
class AppleKeychain: PowerAuthKeychain {

    /// Construct keychain with given identifier and optional access group.
    /// - Parameters:
    ///   - identifier: Keychain identifier
    ///   - accessGroup: Access group
    init(identifier: String, accessGroup: String?) {
        self.identifier = identifier
        self.accessGroup = accessGroup
    }

    // MARK: - PowerAuthKeychain protocol -
    
    let identifier: String
    let accessGroup: String?
    
    func set(_ data: Data, forKey key: String, access: PowerAuthKeychainItemAccess, replace: Bool) throws {
        D.fatalError("Not implemented yet")
    }
    
    func data(forKey key: String, authentication: LAContext?) throws -> Data? {
        D.fatalError("Not implemented yet")
    }
    
    func containsData(forKey key: String) -> Bool {
        D.fatalError("Not implemented yet")
    }
    
    func remove(forKey key: String) throws {
        D.fatalError("Not implemented yet")
    }
    
    func removeAll() throws {
        D.fatalError("Not implemented yet")
    }
    
    // MARK: - Internals -
}
