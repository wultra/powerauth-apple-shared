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

#if os(watchOS) || os(tvOS)
import Foundation

public extension BiometryInfo {
    /// Static property that returns full information about biometry on the system. The resturned structure contains
    /// information about supported type (Touch ID or Face ID) and also actual biometry status (N/A, not enrolled, etc.)
    /// Note that if process is running in limited sandbox, such as application extension do, then property always contain
    /// `BiometryInfo(biometryType: .none, currentStatus: .notSupported)`.
    static var current: BiometryInfo {
        BiometryInfo(biometryType: .none, currentStatus: .notSupported)
    }
}

#endif // #if os(watchOS) || os(tvOS)
