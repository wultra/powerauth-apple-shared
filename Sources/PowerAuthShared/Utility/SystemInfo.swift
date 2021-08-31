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

/// The `SystemInfo` structure contains information about the current platform and device.
public struct SystemInfo {
    
    /// Platform, such as `iOS`, `macOS`.
    public let platform: String
    
    /// Device name, for example `"iPhone12,3"`.
    public let deviceName: String
    
    /// Application is running on simulator.
    public let isSimulator: Bool
    
    /// Application is linked with DEBUG library.
    public let isDebugLibrary: Bool
}

public extension SystemInfo {
    
    // MARK: Current system info
    
    static var current: SystemInfo {
        return SystemInfo(
            platform: platformName,
            deviceName: getDeviceName(),
            isSimulator: isSimulator,
            isDebugLibrary: isDebugLibrary
        )
    }
    
    // MARK: Platform name
    
    #if os(iOS)
    static let platformName = "iOS"
    #elseif targetEnvironment(macCatalyst)
    static let platformName = "macCatalyst"
    #elseif os(macOS)
    static let platformName = "macOS"
    #elseif os(tvOS)
    static let platformName = "tvOS"
    #elseif os(watchOS)
    static let platformName = "watchOS"
    #else
    #error("Unsupported platform")
    #endif

    // MARK: Device name
    
    #if !targetEnvironment(simulator)
    // A real device
    static let isSimulator = false
    static func getDeviceName() -> String {
        var systemInfo = utsname()
        let result = uname(&systemInfo)
        guard result == 0 else {
            return "iDeviceUnknown"
        }
        let identifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return identifier ?? "iDeviceUnknown"
    }
    #else
    // Simulator targetrs
    static let isSimulator = true
    static func getDeviceName() -> String {
        "simulator"
    }
    #endif

    // MARK: Debug
    
    #if DEBUG
    static let isDebugLibrary = true
    #else
    static let isDebugLibrary = false
    #endif
    
}
