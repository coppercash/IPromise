//
//  PromiseTests.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import UIKit
import XCTest
import CCOPromise

let STRING_VALUE_0 = "STRING_VALUE_0"
let STRING_VALUE_1 = "STRING_VALUE_1"
let STRING_VALUE_2 = "STRING_VALUE_2"

let ERROR_0 = NSError.errorWithDomain(" ", code: 0, userInfo: nil)
let ERROR_1 = NSError.errorWithDomain(" ", code: 1, userInfo: nil)
let ERROR_2 = NSError.errorWithDomain(" ", code: 2, userInfo: nil)

class PromiseTests: XCTestCase
{
    // MARK: - 2.1.1
    
    func test_state_pendingToFulfill(){
        let expt = expectationWithDescription(__FUNCTION__)

        let promise = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }
        promise.then { (value) -> Void in
            expt.fulfill()
        }
        
        XCTAssertEqual(promise.state, PromiseState.Pending)
        
        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Fulfilled)
        })
    }
    
    func test_state_pendingToReject(){
        let expt = expectationWithDescription(__FUNCTION__)
        
        let promise = Promise<Void> { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_0)
        }
        promise.catch { (reason) -> Void in
            expt.fulfill()
        }
        
        XCTAssertEqual(promise.state, PromiseState.Pending)

        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Rejected)
        })
    }
    
    // MARK: - 2.1.2
    
    func test_state_fulfill() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let promise = Promise<String> { (resolve, reject) -> Void in
            0 ~> {
                resolve(value: STRING_VALUE_1)
                reject(reason: ERROR_1)
                expt.fulfill()
                }()
            
            resolve(value: STRING_VALUE_0);
            
            resolve(value: STRING_VALUE_2);
            reject(reason: ERROR_2)
        }
        
        XCTAssertEqual(promise.state, PromiseState.Fulfilled)
        XCTAssertEqual(promise.value!, STRING_VALUE_0)
        XCTAssertNil(promise.reason)
        
        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Fulfilled)
            XCTAssertEqual(promise.value!, STRING_VALUE_0)
            XCTAssertNil(promise.reason)
        })
    }
    
    // MARK: - 2.1.3
    
    func test_state_reject() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let promise = Promise<String> { (resolve, reject) -> Void in
            0 ~> {
                resolve(value: STRING_VALUE_1)
                reject(reason: ERROR_1)
                expt.fulfill()
                }()
            
            reject(reason: ERROR_0)
            
            resolve(value: STRING_VALUE_2);
            reject(reason: ERROR_2)
        }
        
        XCTAssertEqual(promise.state, PromiseState.Rejected)
        XCTAssertEqual(promise.reason!, ERROR_0)
        XCTAssertNil(promise.value)
        
        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Rejected)
            XCTAssertEqual(promise.reason!, ERROR_0)
            XCTAssertNil(promise.value)
        })
    }
}
