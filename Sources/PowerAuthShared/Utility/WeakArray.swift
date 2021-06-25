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

/// The WeakReference is a generic protocol which helps capture weak referenced objects
/// into the safe typed Array.
public protocol WeakReference: AnyObject {

    ///  T is a generic type associated with this protocol
    associatedtype T where T: AnyObject
    
    /// An actual reference to the object. The implementation
    /// must make weak reference to the object.
    var instance: T? { get }
    
    /// Contains true if instance is equal to nil
    var isEmpty: Bool { get }
    
    /// A designated initializer
    init(_ weakRef: T)
}

/// This Array extension is adding generic functionality for
/// capturing a weak referenced objects into the swift erray.
///
/// The `Element` used in array must conform to `WeakReference`
/// protocol, so you can use, for example `WeakObject<T>` to create
/// array of weak referenced objects.
public extension Array where Element: WeakReference {

    ///  Initializes an array with sequence of WeakReference.T objects
    init<S>(_ weakReferences: S) where S: Sequence, Element.T == S.Element {
        self.init(weakReferences.map { Element($0) })
    }
    
    /// Returns array of strong, nullable referenced objects. The order of objects is the same as
    /// order of WeakReference-d items.
    /// Note that complexity of this operation is O(N)
    var allNullableStrongReferences: [Element.T?] {
        return self.map { $0.instance }
    }

    /// Returns strong referenced array with all still valid stored objects
    /// Note that complexity of this operation is O(N)
    var allStrongReferences: [Element.T] {
        var result = [Element.T]()
        result.reserveCapacity(self.count)
        self.forEach { (weakRef) in
            if let strongRef = weakRef.instance {
                result.append(strongRef)
            }
        }
        return result
    }
    
    /// Removes all empty WeakReference elements from the array.
    mutating func removeAllEmptyReferences() {
        self = self.filter { !$0.isEmpty }
    }
    
    /// Append sequence of WeakReference.T typed objects.
    mutating func append<S>(contentsOf newElements: S) where S : Sequence, Element.T == S.Element {
        self.append(contentsOf: newElements.map { Element($0) })
    }
    
    /// Assign sequence of WeakReference.T typed objects.
    mutating func assign<S>(contentsOf newElements: S) where S : Sequence, Element.T == S.Element {
        self = newElements.map { Element($0) }
    }
    
    /// Append one element which is `WeakReference.T` type.
    mutating func append(_ newElement: Element.T) {
        self.append(Element(newElement))
    }
    
    /// Removes one element which is `WeakReference.T` type.
    mutating func remove(_ element: Element.T) {
        if let index = self.firstIndex(where: { $0.instance === element }) {
            self.remove(at: index)
        }
    }
}

/// The WeakObject class implements the `WeakReference` protocol. You can use
/// this class to create an array of weak referenced objects, for example:
/// ```
/// var controllers = Array<WeakObject<UIViewController>>()
/// ```
public class WeakObject<T: AnyObject>: WeakReference {
    
    /// An actual weak reference to the object
    public private(set) weak var instance: T?
    
    /// Returns true if captured instance is equal to nil
    public var isEmpty: Bool {
        return instance == nil
    }
    
    /// A designated initializer
    public required init(_ weakRef: T) {
        self.instance = weakRef
    }
}
