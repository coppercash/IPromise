//
//  ThenableTests.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import UIKit
import XCTest
import CCOPromise

typealias NewCallback = (Float) -> Void

protocol FutureTnenable
{
    func then(#onFulfilled: Resolution?, onRejected: Rejection?, onNewCallback: NewCallback?) -> Self
    func then(onFulfilled: Resolution) -> Self
    func catch(onRejected: Rejection) -> Self
}

class ThenableObject: Thenable
{
    func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil) -> Self
    {
        println("\(__FUNCTION__)")
        return self
    }
    
    func then(onFulfilled: Resolution) -> Self
    {
        return then(onFulfilled: onFulfilled, onRejected: nil);
    }
    
    func catch(onRejected: Rejection) -> Self
    {
        return then(onFulfilled: nil, onRejected: onRejected);
    }
}

class FutureThenableObject: FutureTnenable
{
    func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil, onNewCallback: NewCallback? = nil) -> Self
    {
        return self;
    }
    
    func then(onFulfilled: Resolution) -> Self
    {
        return then(onFulfilled, onRejected: nil, onNewCallback: nil);
    }
    
    func catch(onRejected: Rejection) -> Self
    {
        return then(nil, onRejected: onRejected, onNewCallback: nil)
    }
}


class ThenableTests: XCTestCase
{
    func test_expansibility()
    {
        let aThenableObject = ThenableObject()
        
        aThenableObject.then(
            onFulfilled:
            { (result) -> Any? in
                return nil
            },
            onRejected:
            { (error) -> Any? in
                return nil
        })
        
        let aFutureThenableObject = FutureThenableObject()
        
        aThenableObject.then(
            onFulfilled:
            { (result) -> Any? in
                return nil
            },
            onRejected:
            { (error) -> Any? in
                return nil
        })
    }
    
    func test_convenience()
    {
        let aThenableObject = ThenableObject()

        
        // General
        
        aThenableObject.then(
            onFulfilled:
            { (result) -> Any? in
                
                return nil
            },
            onRejected:
            { (error) -> Any? in
                
                return nil
            }
        )
        
        aThenableObject.then(
            onFulfilled:
            { (result) -> Any? in
                
                return nil
            }
        )
        
        aThenableObject.then(
            onRejected:
            { (error) -> Any? in
                
                return nil
            }
        )
        
        // Then
        
        aThenableObject.then(
            { (result) -> Any? in
                
                return nil
            }
        )
        
        aThenableObject.then { (result) -> Any? in
            return nil
        }
        
        // Catch
        
        aThenableObject.catch (
            { (error) -> Any? in
                return nil
            }
        )
        
        aThenableObject.catch { (error) -> Any? in
            return nil
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}