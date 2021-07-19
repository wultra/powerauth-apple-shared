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

extension Data {
    /// Generate required amount of random data. Do not use this function for
    /// generating strong random cryptographic data in production.
    /// - Parameter count: Number of bytes to generate
    /// - Returns: Data filled with random bytes.
    static func random(count: Int) -> Data {
        var data = Data(count: count)
        data.withUnsafeMutableBytes { ptr in
            arc4random_buf(ptr.baseAddress!, ptr.count)
        }
        return data
    }
}

extension String {
    /// Generate random Base64 encoded string containing a required number of random bytes.
    /// Do not use this function for generating strong random cryptographic data in production.
    /// - Parameter dataCount: Number of bytes to generate. 
    /// - Returns: Base64 encoded string
    static func randomBase64(dataCount: Int) -> String {
        return Data.random(count: dataCount).base64EncodedString()
    }
}
