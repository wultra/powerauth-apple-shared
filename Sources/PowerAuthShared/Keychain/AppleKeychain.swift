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

class AppleKeychain: PowerAuthKeychain {

    let identifier: String
    let accessGroup: String?
    
    init(identifier: String, accessGroup: String?) {
        self.identifier = identifier
        self.accessGroup = accessGroup
    }
    
    func contains(dataFor key: String) -> Bool {
        D.fatalError("Not implemented yet")
    }
    
    func remove(key: String) throws {
        D.fatalError("Not implemented yet")
    }
    
    func set(data: Data, for key: String, access: PowerAuthKeychainItemAccess, replace: Bool) throws {
        D.fatalError("Not implemented yet")
    }
    
    func data(for key: String, authentication: LAContext?) throws -> Data? {
        D.fatalError("Not implemented yet")
    }
}
