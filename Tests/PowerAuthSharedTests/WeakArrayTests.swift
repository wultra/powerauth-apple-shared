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

import XCTest
@testable import PowerAuthShared

typealias WeakStrings = Array<WeakObject<NSString>>

extension WeakStrings {
    func contains(_ string: String) -> Bool {
        return firstIndex { $0.instance as String? == string } != nil
    }
}

internal extension String {
    func makeCopy() -> NSString {
        return NSString(format: "%@", self)
    }
}

final class WeakArrayTests: XCTestCase {
    
    var queue: OperationQueue!
    
    override func setUp() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 4
        D.verboseLevel = .all
    }
    
    override func tearDown() {
        queue.cancelAllOperations()
        queue.waitUntilAllOperationsAreFinished()
    }
    
    let TEST_1 = "Hello world !!!"
    let TEST_2 = "This is sparta!!!"
    let TEST_3 = "One more string to capture"
    let TEST_4 = "A very important information."
    
    func testBasicFunctions() throws {
        var array = WeakStrings()
        
        autoreleasepool {
            let t1 = TEST_1.makeCopy()
            let t2 = TEST_2.makeCopy()
            let t3 = TEST_3.makeCopy()
            let t4 = TEST_4.makeCopy()
            
            array.append(t1)
            array.append(t2)
            array.append(contentsOf: [t3, t4])
            
            XCTAssertEqual(4, array.count)
            
            array.remove(t1)
            array.remove(t2)
            
            XCTAssertEqual(2, array.count)
            XCTAssertFalse(array.contains(TEST_1))
            XCTAssertFalse(array.contains(TEST_2))
            XCTAssertTrue(array.contains(TEST_3))
            XCTAssertTrue(array.contains(TEST_4))
        }
        array.removeAllEmptyReferences()
        
        XCTAssertFalse(array.contains(TEST_1))
        XCTAssertFalse(array.contains(TEST_2))
        XCTAssertFalse(array.contains(TEST_3))
        XCTAssertFalse(array.contains(TEST_4))
        
        XCTAssertEqual(0, array.count)
    }
    
    func testReleasingFunctionality() throws {
        
        var array = WeakStrings()
        
        autoreleasepool {
            capture(string: TEST_1, into: &array, for: 0.4)
            capture(string: TEST_2, into: &array, for: 0.6)
            capture(string: TEST_3, into: &array, for: 0.5)
            
            D.print("All captured...")
        }
        
        array.removeAllEmptyReferences()
        XCTAssertEqual(3, array.count)
       
        XCTAssertTrue(array.contains(TEST_1))
        XCTAssertTrue(array.contains(TEST_2))
        XCTAssertTrue(array.contains(TEST_3))

        D.print("Going to wait...")
        
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))
        
        XCTAssertEqual(3, array.count)
        
        XCTAssertFalse(array.contains(TEST_1))
        XCTAssertFalse(array.contains(TEST_2))
        XCTAssertFalse(array.contains(TEST_3))
        
        array.removeAllEmptyReferences()
        XCTAssertEqual(0, array.count)
    }
    
    internal func capture(string: String, into array: inout WeakStrings, for timeInterval: TimeInterval) {
        let nsString = string.makeCopy()
        array.append(nsString)
        queue.addOperation {
            D.print("Capturing string '\(nsString)' for \(timeInterval) seconds...")
            Thread.sleep(forTimeInterval: timeInterval)
            D.print("Releasing string '\(nsString)'")
        }
    }

}
