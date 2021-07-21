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
#if os(iOS) || os(macOS)
import LocalAuthentication
#endif

/// The `KeychainPrompt` represents an biometric authentication prompt displayed in case
/// that item stored in keychain is accessible only after biometric authentication.
/// The structure is available on all supported platforms, but the structure constructor
/// is available only on platforms supporting biometry.
public struct KeychainPrompt {
    /// Fallback prompt applied on older systems.
    public let prompt: String
    /// Property contains `LAContext` object on supported platform.
    public let context: AnyObject?
}

#if os(iOS) || os(macOS)

// MARK: iOS + macOS
public extension KeychainPrompt {
    
    /// Initialize structure with given prompt, fallback title and cancel button title.
    /// Be aweare that on systems older than iOS 11, only "prompt" property is effectively
    /// propagated to the biometric authentication dialog.
    ///
    /// - Parameters:
    ///   - prompt: Application reason for authentication.
    ///   - fallbackTitle: Allows fallback button title customization. If set to empty string, the button will be hidden.
    ///   - cancelTitle: Allows cancel button title customization. A default title "Cancel" is used when this property is left nil.
    ///   - reuseDuration: Allows this prompt to be used more than once to access the protected data, within the desired time interval.
    ///                    This value must not exceed `LATouchIDAuthenticationMaximumAllowableReuseDuration` constant.
    init(with prompt: String, fallbackTitle: String? = nil, cancelTitle: String? = nil, reuseDuration: TimeInterval = 0) {
        if #available(macOS 10.15, iOS 11, *) {
            // We can use context on this platform
            let context = LAContext()
            context.localizedReason = prompt
            context.localizedFallbackTitle = fallbackTitle
            context.localizedCancelTitle = cancelTitle
            context.touchIDAuthenticationAllowableReuseDuration = reuseDuration
            self.prompt = prompt
            self.context = context
        } else {
            self.prompt = prompt
            self.context = nil
        }
    }
    
    /// Initialize structure with given `LAContext` object. You must configure the context object on your own with
    /// proper title, cancel button or fallback title.
    ///
    /// - Parameter context: `LAContext` containing information for biometric authentication dialog.
    @available(macOS 10.15, iOS 11.0, *)
    init(with context: LAContext) {
        self.prompt = context.localizedReason
        self.context = context
    }
    
    
    /// Contains `LAContext` object if `KeychainPrompt` has been constructed such object.
    @available(macOS 10.15, iOS 11.0, *)
    var asLAContext: LAContext? {
        context as? LAContext
    }
}

#endif // os(iOS) || os(macOS)
