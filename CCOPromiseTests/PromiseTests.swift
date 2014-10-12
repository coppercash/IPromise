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
let STRING_VALUE_3 = "STRING_VALUE_3"

let ERROR_0 = NSError.errorWithDomain(" ", code: 0, userInfo: nil)
let ERROR_1 = NSError.errorWithDomain(" ", code: 1, userInfo: nil)
let ERROR_2 = NSError.errorWithDomain(" ", code: 2, userInfo: nil)
let ERROR_3 = NSError.errorWithDomain(" ", code: 3, userInfo: nil)

class PromiseTests: XCTestCase
{
    // MARK: - 2.1.1; init(resolver)
    
    func test_state_pendingToFulfill(){
        let expt = expectationWithDescription(__FUNCTION__)

        let promise = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }
        promise.then { (value) -> Void in
            expt.fulfill()
        }
        
        XCTAssertEqual(promise.state, PromiseState.Pending)
        XCTAssertNil(promise.value)
        XCTAssertNil(promise.reason)
        
        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Fulfilled)
            XCTAssertEqual(promise.value!, STRING_VALUE_0)
            XCTAssertNil(promise.reason)
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
        XCTAssertNil(promise.reason)

        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Rejected)
            XCTAssertEqual(promise.reason!, ERROR_0)
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
    
    // MARK: - 2.2.4; 2.2.5
    
    // MARK: - 2.2.2; 2.2.6
    
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

    // MARK: - 2.2.3; 2.2.6

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
    
    // MARK: - 2.2.1; 2.2.7.3; init(value:)
    
    func test_optional_fulfill() {
        let promise = Promise(value: STRING_VALUE_0)
        XCTAssertEqual(promise.state, PromiseState.Fulfilled)
        XCTAssertNil(promise.reason)
        
        promise
            .then(
                onFulfilled: nil,
                onRejected: nil
            )
            .then(
                onFulfilled: { (value) -> Void in
                    XCTAssertEqual(value as String, STRING_VALUE_0)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertFalse(true)
                }
        )
    }
    
    // MARK: - 2.2.1; 2.2.7.4; init(reason:)

    func test_optional_reject() {
        let promise = Promise<String>(reason: ERROR_0)
        XCTAssertEqual(promise.state, PromiseState.Rejected)
        XCTAssertNil(promise.value)

        promise
            .then(
                onFulfilled: nil,
                onRejected: nil
            )
            .then(
                onFulfilled: { (value) -> Void in
                    XCTAssertFalse(true)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertEqual(reason, ERROR_0)
                }
        )
    }
    
    // MARK: 2.3.1
    
    func test_typeError_fulfill() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        var subPromise: Promise<String>? = nil
        
        let promise = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
            }
            .then(
                onFulfilled: { (value) -> Promise<String> in
                    return subPromise!
                },
                onRejected: { (reason) -> Promise<String> in
                    return subPromise!
                }
        )
        subPromise = promise
        
        promise.catch { (reason) -> Void in
            XCTAssertEqual(reason, NSError.promiseTypeError())
            expt.fulfill()
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
        })
    }
    
    func test_typeError_reject() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        var subPromise: Promise<String>? = nil
        
        let promise = Promise<String> { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_0)
            }
            .then(
                onFulfilled: { (value) -> Promise<String> in
                    return subPromise!
                },
                onRejected: { (reason) -> Promise<String> in
                    return subPromise!
                }
        )
        subPromise = promise
        
        promise.catch { (reason) -> Void in
            XCTAssertEqual(reason, NSError.promiseTypeError())
            expt.fulfill()
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
        })
    }
    
    // MARK: - 2.3.2; chain
    
    func test_chain_promise() {
        
        var expts: [Int: XCTestExpectation] = [:]
        for index in 1...5 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }
        var counter = 0
        
        let toFulfill = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_2)
        }
        let toReject = Promise<String> { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_2)
        }
        
        Promise<Void>(reason: ERROR_0)
            .then(
                onFulfilled: { (value) -> Promise<String> in
                    XCTAssertFalse(true)
                    return Promise(value: STRING_VALUE_0)
                },
                onRejected: { (reason) -> Promise<String> in
                    XCTAssertEqual(reason, ERROR_0)
                    XCTAssertEqual(++counter, 1)
                    expts[1]!.fulfill()
                    return Promise(value: STRING_VALUE_0)
                }
            ).then { (value) -> Promise<String> in
                XCTAssertEqual(value, STRING_VALUE_0)
                XCTAssertEqual(++counter, 2)
                expts[2]!.fulfill()
                return Promise<String>(reason: ERROR_1)
            }.then(
                onFulfilled: { (value) -> Promise<String> in
                    XCTAssertFalse(true)
                    return toFulfill
                },
                onRejected: { (reason) -> Promise<String> in
                    XCTAssertEqual(reason, ERROR_1)
                    XCTAssertEqual(++counter, 3)
                    expts[3]!.fulfill()
                    return toFulfill
            }).then { (value) -> Promise<String> in
                XCTAssertEqual(value, STRING_VALUE_2)
                XCTAssertEqual(++counter, 4)
                expts[4]!.fulfill()
                return toReject
            }.catch { (reason) -> Void in
                XCTAssertEqual(reason, ERROR_2)
                XCTAssertEqual(++counter, 5)
                expts[5]!.fulfill()
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
        })
    }

    // MARK: - 2.3.3
    
    // MARK: - 2.3.4; chain
    
    func test_chain_value() {
        
        var expts: [Int: XCTestExpectation] = [:]
        for index in 0...3 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }

        Promise<Any?>(reason: ERROR_0)
            .then(
                onFulfilled: { (value) -> String in
                    XCTAssertFalse(true)
                    return STRING_VALUE_0
                },
                onRejected: { (reason) -> String in
                    XCTAssertEqual(reason, ERROR_0)
                    expts[0]!.fulfill()
                    return STRING_VALUE_0
            }).then(
                onFulfilled: { (value) -> String in
                    XCTAssertEqual(value, STRING_VALUE_0)
                    expts[1]!.fulfill()
                    return STRING_VALUE_1
                },
                onRejected: { (reason) -> String in
                    XCTAssertFalse(true)
                    return STRING_VALUE_1
            }).then { (value) -> String in
                XCTAssertEqual(value, STRING_VALUE_1)
                expts[2]!.fulfill()
                return STRING_VALUE_2
            }.then { (value) -> Void in
                XCTAssertEqual(value, STRING_VALUE_2)
                expts[3]!.fulfill()
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
        })
    }
    
    func test_chain_void() {
        
        var expts: [Int: XCTestExpectation] = [:]
        for index in 0...3 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }

        Promise<Any?>(reason: ERROR_0)
            .then(
                onFulfilled: { (value) -> Void in
                    XCTAssertFalse(true)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertEqual(reason, ERROR_0)
                    expts[0]!.fulfill()
            }).then(
                onFulfilled: { (value: Any?) -> Void in
                    XCTAssertTrue(value == nil)
                    expts[1]!.fulfill()
                },
                onRejected: { (reason) -> Void in
                    XCTAssertFalse(true)
            }).then { (value: Any?) -> Void in
                XCTAssertTrue(value == nil)
                expts[2]!.fulfill()
            }.then { (value: Any?) -> Void in
                XCTAssertTrue(value == nil)
                expts[3]!.fulfill()
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
        })
    }

    // MARK: - init(:thenable)
    
    func test_init_thenable() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }
        
        let promise = Promise(thenable: superPromise)
        promise.then(
                onFulfilled: { (value) -> Void in
                    XCTAssertEqual(value, STRING_VALUE_0)
                    expt.fulfill()
                },
                onRejected: { (reason) -> Void in
                    XCTAssertFalse(true)
                }
        )
        
        XCTAssertEqual(promise.state, PromiseState.Pending)
        XCTAssertNil(promise.value)
        XCTAssertNil(promise.reason)

        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Fulfilled)
            XCTAssertEqual(promise.value!, STRING_VALUE_0)
            XCTAssertNil(promise.reason)
        })
    }
    
    // MARK: - init(:anyThenable)

    func test_init_anyThenable_fulfill() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = APlusPromise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }
        
        let promise = Promise<Any?>(anyThenable: superPromise)
        promise.then(
            onFulfilled: { (value) -> Void in
                XCTAssertEqual(value as String, STRING_VALUE_0)
                expt.fulfill()
            },
            onRejected: { (reason) -> Void in
                XCTAssertFalse(true)
            }
        )
        
        XCTAssertEqual(promise.state, PromiseState.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertNil(promise.reason)
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Fulfilled)
            XCTAssertEqual(promise.value as String, STRING_VALUE_0)
            XCTAssertNil(promise.reason)
        })
    }

    
    func test_init_anyThenable_rejectNSError() {
        let expt = expectationWithDescription(__FUNCTION__)

        let superPromise = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_0)
        }
        
        let promise = Promise<Any?>(anyThenable: superPromise)
        promise.then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                XCTAssertEqual(reason, ERROR_0)
                expt.fulfill()
            }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    func test_init_anyThenable_rejectAny() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: STRING_VALUE_0)
        }
        
        let promise = Promise<Any?>(anyThenable: superPromise)
        promise.then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                XCTAssertEqual(reason, NSError.promiseReasonWrapperError(STRING_VALUE_0))
                expt.fulfill()
            }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }

    
    // MARK: - resolve(_)
    
    func test_init_resolve() {
        // Can't test. Compiler keeps crashing.

        let a0 = Promise<Any?>.resolve(STRING_VALUE_0)
        a0.then { (value) -> Void in
            XCTAssertEqual(value as String, STRING_VALUE_0)
        }
        XCTAssertEqual(a0.value as String, STRING_VALUE_0)
        
        let a1 = Promise<Any?>.resolve(nil)
        a1.then { (value) -> Void in
            XCTAssertTrue(value == nil)
        }
        XCTAssertTrue(a1.value! == nil)
        
        let q2 = Promise(value: STRING_VALUE_0)
        let a2 = Promise<Any?>.resolve(q2)
        //XCTAssertTrue(a2 === q2)
    }
    
    // MARK: - all
    
    func test_init_all_fulfill() {

        //let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = Promise(value: STRING_VALUE_0)
        let prms2 = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }


    }
    
    // MARK: - race

}
