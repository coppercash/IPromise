//
//  APlusPromiseTests.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/25/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import UIKit
import XCTest
import CCOPromise

let value1 = "value 1"
let value2 = "value 2"
let error1 = NSError(domain: "error 1", code: 0, userInfo: nil)
let error2 = NSError(domain: "error 2", code: 0, userInfo: nil)

class APlusPromiseTests: XCTestCase
{
    func test_init()
    {
        let pendingPrms = APlusPromise()
        XCTAssertNotNil(pendingPrms, " ")
        XCTAssertEqual(pendingPrms.state, APlusPromise.State.Pending, " ")
        XCTAssertTrue(pendingPrms.value == nil, " ")
        XCTAssertTrue(pendingPrms.reason == nil, " ")

        (pendingPrms.value as APlusPromise?) == nil
        
        let fulfulledPrms = APlusPromise(value: "A value")
        XCTAssertNotNil(fulfulledPrms, " ")
        XCTAssertEqual(fulfulledPrms.state, APlusPromise.State.Fulfilled, " ")
        XCTAssertEqual((fulfulledPrms.value as String), "A value", " ")
        XCTAssertTrue(fulfulledPrms.reason == nil, " ")

        let error = NSError()
        let rejectedPrms = APlusPromise(reason: error)
        XCTAssertNotNil(rejectedPrms, " ")
        XCTAssertEqual(rejectedPrms.state, APlusPromise.State.Rejected, " ")
        XCTAssertTrue(rejectedPrms.value == nil, " ")
        XCTAssertEqual((rejectedPrms.reason as NSError), error, " ")
    }
    
    func test_initWithAction()
    {
        let actionPrms = APlusPromise { (resolve, reject) -> Void in
        }
        
        XCTAssertNotNil(actionPrms, " ")
        XCTAssertEqual(actionPrms.state, APlusPromise.State.Pending, " ")
        XCTAssertTrue(actionPrms.value == nil, " ")
        XCTAssertTrue(actionPrms.reason == nil, " ")
        
        let actionPrmsFulfill = APlusPromise { (resolve, reject) -> Void in
            resolve(value: value1)
            reject(reason: error1)
            resolve(value: value2)
            reject(reason: error2)
        }
        
        XCTAssertNotNil(actionPrmsFulfill, " ")
        XCTAssertEqual(actionPrmsFulfill.state, APlusPromise.State.Fulfilled, " ")
        XCTAssertEqual((actionPrmsFulfill.value as String), value1, " ")
        XCTAssertTrue(actionPrmsFulfill.reason == nil, " ")

        let actionPrmsReject = APlusPromise { (resolve, reject) -> Void in
            reject(reason: error1)
            resolve(value: value1)
            reject(reason: error2)
            resolve(value: value2)
        }
        
        XCTAssertNotNil(actionPrmsReject, " ")
        XCTAssertEqual(actionPrmsReject.state, APlusPromise.State.Rejected, " ")
        XCTAssertTrue(actionPrmsReject.value == nil, " ")
        XCTAssertEqual((actionPrmsReject.reason as NSError), error1, " ")
    }
    
    func test_initWithActionFulfill()
    {
        let expectation = expectationWithDescription("initWithActionFulfill");

        let actionPrms = APlusPromise { (resolve, reject) -> Void in
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    resolve(value: value1)
                    reject(reason: error1)
                    resolve(value: value2)
                    reject(reason: error2)
                })
            })
        }
        actionPrms.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual((value as String), value1, " ")
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true, "")
                return nil
            }
        )
        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertEqual(actionPrms.state, APlusPromise.State.Fulfilled, " ")
            XCTAssertTrue((actionPrms.value as String) == value1, " ")
            XCTAssertTrue(actionPrms.reason == nil, " ")
        };
    }
    
    func test_initWithActionReject()
    {
        let expectation = expectationWithDescription("initWithActionReject");
        
        let actionPrms = APlusPromise { (resolve, reject) -> Void in
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    reject(reason: error1)
                    resolve(value: value1)
                    reject(reason: error2)
                    resolve(value: value2)
                })
            })
        }
        actionPrms.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true, "")
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual((reason as NSError), error1, " ")
                expectation.fulfill()
                return nil
            }
        )
        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertEqual(actionPrms.state, APlusPromise.State.Rejected, " ")
            XCTAssertTrue(actionPrms.value == nil, " ")
            XCTAssertEqual((actionPrms.reason as NSError), error1, " ")
        };
    }

}
