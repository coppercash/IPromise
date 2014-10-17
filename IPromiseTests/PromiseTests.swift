//
//  PromiseTests.swift
//  IPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import UIKit
import XCTest
import IPromise

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
                    XCTAssertEqual("\(value)", VOID_SUMMARY)
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
            XCTAssertEqual((reason as NSError).domain, PromiseErrorDomain)
            XCTAssertEqual((reason as NSError).code, PromiseTypeError)
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
            XCTAssertEqual((reason as NSError).domain, PromiseErrorDomain)
            XCTAssertEqual((reason as NSError).code, PromiseTypeError)
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

        Promise<Void>(reason: ERROR_0)
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
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    func test_chain_void_reject() {
        
        var expts: [Int: XCTestExpectation] = [:]
        for index in 0...3 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }

        Promise<Void>(reason: ERROR_0)
            .then(
                onFulfilled: { (value: Void) -> Void in
                    XCTAssertFalse(true)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertEqual(reason, ERROR_0)
                    expts[0]!.fulfill()
            }).then(
                onFulfilled: { (value) -> Void in
                    XCTAssertEqual("\(value)", VOID_SUMMARY)
                    expts[1]!.fulfill()
                },
                onRejected: { (reason) -> Void in
                    XCTAssertFalse(true)
            }).then { (value: Void) -> Void in
                XCTAssertEqual("\(value)", VOID_SUMMARY)
                expts[2]!.fulfill()
            }.then { (value: Void) -> Void in
                XCTAssertEqual("\(value)", VOID_SUMMARY)
                expts[3]!.fulfill()
        }
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }

    func test_chain_void_fulfill() {

        var expts: [Int: XCTestExpectation] = [:]
        for index in 0...2 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }
        
        Promise<String>(value: STRING_VALUE_0)
        .then { (value) -> Void in
            XCTAssertEqual(value, STRING_VALUE_0)
            expts[0]!.fulfill()
        }.catch { (reason) -> Void in
            XCTAssertFalse(true)
        }.then { (value) -> String in
            XCTAssertEqual("\(value)", VOID_SUMMARY)
            expts[1]!.fulfill()
            return STRING_VALUE_1
        }.then { (value) -> Void in
            XCTAssertEqual(value, STRING_VALUE_1)
            expts[2]!.fulfill()
        }
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    // MARK: - init(:thenable)
    
    func test_init_thenable_fulfill() {
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
    
    func test_init_thenable_reject() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = Promise<Any?> { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_0)
        }
        
        let promise = Promise(thenable: superPromise)
        promise.then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                XCTAssertEqual(reason, ERROR_0)
                expt.fulfill()
            }
        )
        
        XCTAssertEqual(promise.state, PromiseState.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertNil(promise.reason)
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Rejected)
            XCTAssertTrue(promise.value == nil)
            XCTAssertEqual(promise.reason!, ERROR_0)
        })
    }
    
    // MARK: - resolve(_)
    
    func test_resolve() {

        let expt0 = expectationWithDescription("\(__FUNCTION__)_0")
        let a0: Promise<String> = Promise<String>.resolve(STRING_VALUE_0)
        a0.then { (value) -> Void in
            XCTAssertEqual(value as String, STRING_VALUE_0)
            expt0.fulfill()
        }
        XCTAssertEqual(a0.value! as String, STRING_VALUE_0)
        
        let a1: Promise<Any> = Promise<String>.resolve(STRING_VALUE_0)
        XCTAssertEqual(a1.value as String, STRING_VALUE_0)
        
        let q2 = Promise<String>(value: STRING_VALUE_0)
        let a2: Promise<String> = Promise<String>.resolve(q2)
        XCTAssertTrue(a2 === q2)
        
        // This does not behave as expect
        let q3 = Promise<String>(value: STRING_VALUE_0)
        let a3: Promise<Any> = Promise<Any>.resolve(q3)
        XCTAssertTrue(a3.value as Promise<String> === q3)
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    func skip_test_resolve_valueTypeError() {
        
        let expt1 = expectationWithDescription("\(__FUNCTION__)_1")
        let a1: Promise<String> = Promise<String>.resolve(1)
        a1.catch { (reason) -> Void in
            XCTAssertEqual(reason.domain, PromiseErrorDomain)
            XCTAssertEqual(reason.code, PromiseValueTypeError)
            println(reason.localizedDescription)
            expt1.fulfill()
        }
        XCTAssertEqual(a1.state, PromiseState.Rejected)

        let expt3 = expectationWithDescription("\(__FUNCTION__)_3")
        let q3 = Promise<Int>(value: 3)
        let a3: Promise<String> = Promise<String>.resolve(q3)
        a3.catch { (reason) -> Void in
            XCTAssertEqual(reason.domain, PromiseErrorDomain)
            XCTAssertEqual(reason.code, PromiseValueTypeError)
            println(reason.localizedDescription)
            expt3.fulfill()
        }
        XCTAssertEqual(a3.state, PromiseState.Rejected)
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    // MARK: - reject(_)

        func test_reject() {
        let a0 = APlusPromise.reject(ERROR_0)
        XCTAssertEqual(a0.state, PromiseState.Rejected)
        XCTAssertTrue(a0.value == nil)
        XCTAssertEqual(a0.reason as NSError, ERROR_0)
    }

    
    // MARK: - all
    
    func test_all_fulfill_async() {

        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms0 = Promise(value: STRING_VALUE_0 as Any?)
        let prms1 = Promise(value: STRING_VALUE_1 as Any?)
        let prms2 = Promise<Any?>(vagueThenable:
            APlusPromise { (resolve, reject) -> Void in
                0 ~> resolve(value: STRING_VALUE_2)
            })
        
        let promise = Promise<Any>.all(prms0, prms1, prms2)
        promise.then(
            onFulfilled: { (value) -> Any? in
                
                let results = value as [Any?]
                
                XCTAssertEqual(results[0] as String, STRING_VALUE_0)
                XCTAssertEqual(results[1] as String, STRING_VALUE_1)
                XCTAssertEqual(results[2] as String, STRING_VALUE_2)
                
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        XCTAssertTrue(promise.value == nil)
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_all_fulfill_sync() {
        
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms0 = Promise(value: STRING_VALUE_0)
        let prms1 = Promise(value: STRING_VALUE_1)
        let prms2 = Promise(value: STRING_VALUE_2)
        
        let promise = Promise<Any>.all(prms0, prms1, prms2)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual(value, [STRING_VALUE_0, STRING_VALUE_1, STRING_VALUE_2])
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        XCTAssertEqual(promise.value!, [STRING_VALUE_0, STRING_VALUE_1, STRING_VALUE_2])

        waitForExpectationsWithTimeout(7) { println($0) }
    }

    func test_all_reject_aync() {
        
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms0 = Promise(value: STRING_VALUE_0 as Any?)
        let prms1 = Promise(value: STRING_VALUE_1 as Any?)
        let prms2 = Promise<Any?>(vagueThenable:
            APlusPromise { (resolve, reject) -> Void in
                0 ~> reject(reason: ERROR_2)
            })
        
        let promise = Promise<Any>.all(prms0, prms1, prms2)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual(reason, ERROR_2)
                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertTrue(promise.reason == nil)
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_all_reject_sync() {
        
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms0 = Promise(value: STRING_VALUE_0)
        let prms1 = Promise<String>(reason: ERROR_1)
        let prms2 = Promise<String>(reason: ERROR_2)
        
        let promise = Promise<String>.all(prms0, prms1, prms2)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual(reason, ERROR_1)
                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertEqual(promise.reason!, ERROR_1)
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    // MARK: - race

    func test_race_fulfill_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = Promise(value: STRING_VALUE_1)
        let prms2 = Promise<String>(reason: ERROR_2)
        let prms3 = Promise<String>(reason: ERROR_3)
        
        let promise = Promise<String>.race(prms1, prms2, prms3)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual(value, STRING_VALUE_1)
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        XCTAssertEqual(promise.value!, STRING_VALUE_1)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_race_fulfill_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_1)
        }
        let prms2 = Promise<String>()
        let prms3 = Promise<String>()
        
        let promise = Promise<String>.race(prms1, prms2, prms3)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual(value, STRING_VALUE_1)
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        XCTAssertTrue(promise.value == nil)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_race_reject_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = Promise<String>()
        let prms2 = Promise<String>(reason: ERROR_2)
        let prms3 = Promise(value: STRING_VALUE_3)
        let promise = Promise<String>.race(prms1, prms2, prms3)
        
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual(reason as NSError, ERROR_2)
                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertEqual(promise.reason!, ERROR_2)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_race_reject_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = Promise<String>()
        let prms2 = Promise<String> { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_2)
        }
        let prms3 = Promise<String>()
        let promise = Promise<String>.race(prms1, prms2, prms3)
        
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual(reason, ERROR_2)
                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    

    // MARK: - init(:vagueThenable)
    
    func test_init_vagueThenable_fulfill() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = APlusPromise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }
        
        let promise = Promise<Any?>(vagueThenable: superPromise)
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
    
    func test_init_vagueThenable_rejectNSError() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_0)
        }
        
        let promise = Promise<Any?>(vagueThenable: superPromise)
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
    
    func test_init_vagueThenable_rejectAny() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: STRING_VALUE_0)
        }
        
        let promise = Promise<Any?>(vagueThenable: superPromise)
        promise.then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                XCTAssertEqual(reason.domain, PromiseErrorDomain)
                XCTAssertEqual(reason.code, PromiseReasonWrapperError)
                XCTAssertEqual(reason.userInfo![PromiseErrorReasonKey]! as String, STRING_VALUE_0)

                expt.fulfill()
            }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
}
