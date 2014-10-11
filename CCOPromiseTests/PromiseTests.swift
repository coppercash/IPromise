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
    
    // MARK: - 2.2.4 2.2.5
    
    // MARK: - 2.2.2 2.2.6
    
    func test_then_onFulfilled() {
        
        var counter = 0
        var expts: [Int: XCTestExpectation] = [:]
        for index in 2...7 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }
        
        let promise = Promise<String> { (resolve, reject) -> Void in
            0 ~> {
                XCTAssertEqual(++counter, 1)
                
                resolve(value: STRING_VALUE_0)

                resolve(value: STRING_VALUE_1)
                reject(reason: ERROR_1)
                
                XCTAssertEqual(++counter, 8)
                }()
        }
        
        promise.then(
            onFulfilled: { (value) -> Void in
                XCTAssertEqual(value, STRING_VALUE_0)
                XCTAssertEqual(++counter, 2)
                expts[2]!.fulfill()
            },
            onRejected: { (reason) -> Void in
                XCTAssertFalse(true)
            }
        )
        
        promise.then { (value) -> Void in
            XCTAssertEqual(value, STRING_VALUE_0)
            XCTAssertEqual(++counter, 3)
            expts[3]!.fulfill()
        }

        promise.catch { (reason) -> Void in
            XCTAssertFalse(true)
        }
        
        promise.then(
            onFulfilled: { (value) -> String in
                XCTAssertEqual(value, STRING_VALUE_0)
                XCTAssertEqual(++counter, 4)
                expts[4]!.fulfill()
                return STRING_VALUE_2
            },
            onRejected: { (reason) -> String in
                XCTAssertFalse(true)
                return STRING_VALUE_2
            }
        )
        
        promise.then { (value) -> String in
            XCTAssertEqual(value, STRING_VALUE_0)
            XCTAssertEqual(++counter, 5)
            expts[5]!.fulfill()
            return STRING_VALUE_2
        }
        
        promise.then(
            onFulfilled: { (value) -> Promise<String> in
                XCTAssertEqual(value, STRING_VALUE_0)
                XCTAssertEqual(++counter, 6)
                expts[6]!.fulfill()
                return Promise(value: STRING_VALUE_2)
            },
            onRejected: { (reason) -> Promise<String> in
                XCTAssertFalse(true)
                return Promise(value: STRING_VALUE_2)
            }
        )
        
        promise.then { (value) -> Promise<String> in
            XCTAssertEqual(value, STRING_VALUE_0)
            XCTAssertEqual(++counter, 7)
            expts[7]!.fulfill()
            return Promise(value: STRING_VALUE_2)
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
            
        })
    }

    func test_then_onRejected() {
        
        var counter = 0
        var expts: [Int: XCTestExpectation] = [:]
        for index in 2...5 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }
        
        let promise = Promise<String> { (resolve, reject) -> Void in
            0 ~> {
                XCTAssertEqual(++counter, 1)
                
                reject(reason: ERROR_0)
                
                resolve(value: STRING_VALUE_1)
                reject(reason: ERROR_1)
                
                XCTAssertEqual(++counter, 6)
                }()
        }
        
        promise.then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                XCTAssertEqual(reason, ERROR_0)
                XCTAssertEqual(++counter, 2)
                expts[2]!.fulfill()
            }
        )
        
        promise.then { (value) -> Void in
            XCTAssertFalse(true)
        }
        
        promise.catch { (reason) -> Void in
            XCTAssertEqual(reason, ERROR_0)
            XCTAssertEqual(++counter, 3)
            expts[3]!.fulfill()
        }
        
        promise.then(
            onFulfilled: { (value) -> String in
                XCTAssertFalse(true)
                return STRING_VALUE_2
            },
            onRejected: { (reason) -> String in
                XCTAssertEqual(reason, ERROR_0)
                XCTAssertEqual(++counter, 4)
                expts[4]!.fulfill()
                return STRING_VALUE_2
            }
        )
        
        promise.then { (value) -> String in
            XCTAssertFalse(true)
            return STRING_VALUE_2
        }
        
        promise.then(
            onFulfilled: { (value) -> Promise<String> in
                XCTAssertFalse(true)
                return Promise(value: STRING_VALUE_2)
            },
            onRejected: { (reason) -> Promise<String> in
                XCTAssertEqual(reason, ERROR_0)
                XCTAssertEqual(++counter, 5)
                expts[5]!.fulfill()
                return Promise(value: STRING_VALUE_2)
            }
        )
        
        promise.then { (value) -> Promise<String> in
            XCTAssertFalse(true)
            return Promise(value: STRING_VALUE_2)
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
            
        })
    }
}
