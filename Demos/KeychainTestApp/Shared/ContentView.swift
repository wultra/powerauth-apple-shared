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

import SwiftUI
import PowerAuthShared
import PowerAuthShared_OnDeviceTests

struct ContentView: View {
    
    @State var biometryInfo: BiometryInfo?
    
    var body: some View {
        VStack() {
            Text("Biometric tests")
                .font(.largeTitle)
                .padding(.top, 20)
                .padding(.bottom, 20)
            
            Spacer()
            Text("Biometry status: \(biometryInfo?.currentStatus.description ?? "...")")
                .font(.body)
                .multilineTextAlignment(.center)
            Text("Biometry type: \(biometryInfo?.biometryType.description ?? "...")")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button("Run tests") {
                DispatchQueue.global().async {
                    _ = TestManager.allKeychainTests.runAll()
                }
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif


extension BiometryInfo.BiometryStatus {
    var description: String {
        switch self {
            case .available:
                return "Available"
            case .lockout:
                return "Lockout"
            case .notAvailable:
                return "Not Available"
            case .notEnrolled:
                return "Not Enrolled"
            case .notSupported:
                return "Not supported"
        }
    }
}

extension BiometryInfo.BiometryType {
    var description: String {
        switch self {
            case .none:
                return "Sensor not present"
            case .faceID:
                return "FaceID"
            case .touchID:
                return "TouchID"
        }
    }
}
