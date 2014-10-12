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

class APlusPromiseTests: XCTestCase
{
    // MARK: - 2.1.1; init(resolver)
    
    func test_state_pendingToFulfill(){
        let expt = expectationWithDescription(__FUNCTION__)
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }
        promise.then { (value) -> Any? in
            expt.fulfill()
            return nil
        }
        
        XCTAssertEqual(promise.state, PromiseState.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)

        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Fulfilled)
            XCTAssertEqual(promise.value as String, STRING_VALUE_0)
            XCTAssertTrue(promise.reason == nil)
        })
    }
    
    func test_state_pendingToReject(){
        let expt = expectationWithDescription(__FUNCTION__)
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_0)
        }
        promise.catch { (reason) -> Any? in
            expt.fulfill()
            return nil
        }
        
        XCTAssertEqual(promise.state, PromiseState.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Rejected)
            XCTAssertEqual(promise.reason as NSError, ERROR_0)
            XCTAssertTrue(promise.value == nil)
        })
    }
    
    // MARK: - 2.1.2
    
    func test_state_fulfill() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let promise = APlusPromise { (resolve, reject) -> Void in
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
        XCTAssertEqual(promise.value as String, STRING_VALUE_0)
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Fulfilled)
            XCTAssertEqual(promise.value as String, STRING_VALUE_0)
            XCTAssertTrue(promise.reason == nil)
        })
    }
    
    // MARK: - 2.1.3
    
    func test_state_reject() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let promise = APlusPromise { (resolve, reject) -> Void in
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
        XCTAssertEqual(promise.reason as NSError, ERROR_0)
        XCTAssertTrue(promise.value == nil)
        
        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Rejected)
            XCTAssertEqual(promise.reason as NSError, ERROR_0)
            XCTAssertTrue(promise.value == nil)
        })
    }
    
    // MARK: - 2.2.4; 2.2.5
    
    // MARK: - 2.2.2; 2.2.6
    
    func test_then_onFulfilled() {
        
        var counter = 0
        var expts: [Int: XCTestExpectation] = [:]
        for index in 2...3 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            0 ~> {
                XCTAssertEqual(++counter, 1)
                
                resolve(value: STRING_VALUE_0)
                
                resolve(value: STRING_VALUE_1)
                reject(reason: ERROR_1)
                
                XCTAssertEqual(++counter, 4)
                }()
        }
        
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual(value as String, STRING_VALUE_0)
                XCTAssertEqual(++counter, 2)
                expts[2]!.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        promise.then { (value) -> Any? in
            XCTAssertEqual(value as String, STRING_VALUE_0)
            XCTAssertEqual(++counter, 3)
            expts[3]!.fulfill()
            return nil
        }
        
        promise.catch { (reason) -> Void in
            XCTAssertFalse(true)
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
        })
    }
    
    // MARK: - 2.2.3; 2.2.6
    
    func test_then_onRejected() {
        
        var counter = 0
        var expts: [Int: XCTestExpectation] = [:]
        for index in 2...3 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            0 ~> {
                XCTAssertEqual(++counter, 1)
                
                reject(reason: ERROR_0)
                
                resolve(value: STRING_VALUE_1)
                reject(reason: ERROR_1)
                
                XCTAssertEqual(++counter, 4)
                }()
        }
        
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual(reason as NSError, ERROR_0)
                XCTAssertEqual(++counter, 2)
                expts[2]!.fulfill()
                return nil
            }
        )
        
        promise.then { (value) -> Any? in
            XCTAssertFalse(true)
            return nil
        }
        
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, ERROR_0)
            XCTAssertEqual(++counter, 3)
            expts[3]!.fulfill()
            return nil
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
        })
    }
    
    // MARK: - 2.2.1; 2.2.7.3; init(value:)
    
    func test_optional_fulfill() {
        let promise = APlusPromise(value: STRING_VALUE_0)
        XCTAssertEqual(promise.state, PromiseState.Fulfilled)
        XCTAssertTrue(promise.reason == nil)
        
        promise
            .then(
                onFulfilled: nil,
                onRejected: nil
            )
            .then(
                onFulfilled: { (value) -> Any? in
                    XCTAssertEqual(value as String, STRING_VALUE_0)
                },
                onRejected: { (reason) -> Any? in
                    XCTAssertFalse(true)
                }
        )
    }
    
    // MARK: - 2.2.1; 2.2.7.4; init(reason:)
    
    func test_optional_reject() {
        let promise = APlusPromise(reason: ERROR_0)
        XCTAssertEqual(promise.state, PromiseState.Rejected)
        XCTAssertTrue(promise.value == nil)
        
        promise
            .then(
                onFulfilled: nil,
                onRejected: nil
            )
            .then(
                onFulfilled: { (value) -> Any? in
                    XCTAssertFalse(true)
                },
                onRejected: { (reason) -> Any? in
                    XCTAssertEqual(reason as NSError, ERROR_0)
                }
        )
    }
    
    // MARK: 2.3.1
    
    func test_typeError_fulfill() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        var subPromise: APlusPromise? = nil
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
            }
            .then(
                onFulfilled: { (value) -> Any? in
                    return subPromise!
                },
                onRejected: { (reason) -> Any? in
                    return subPromise!
                }
        )
        subPromise = promise
        
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, NSError.promiseTypeError())
            expt.fulfill()
            return nil
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
        })
    }
    
    func test_typeError_reject() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        var subPromise: APlusPromise? = nil
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_0)
            }
            .then(
                onFulfilled: { (value) -> Any? in
                    return subPromise!
                },
                onRejected: { (reason) -> Any? in
                    return subPromise!
                }
        )
        subPromise = promise
        
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, NSError.promiseTypeError())
            expt.fulfill()
            return nil
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
        
        let toFulfill = APlusPromise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_2)
        }
        let toReject = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_2)
        }
        
        APlusPromise(reason: ERROR_0)
            .then(
                onFulfilled: { (value) -> Any? in
                    XCTAssertFalse(true)
                    return APlusPromise(value: STRING_VALUE_0)
                },
                onRejected: { (reason) -> Any? in
                    XCTAssertEqual(reason as NSError, ERROR_0)
                    XCTAssertEqual(++counter, 1)
                    expts[1]!.fulfill()
                    return APlusPromise(value: STRING_VALUE_0)
                }
            ).then { (value) -> Any? in
                XCTAssertEqual(value as String, STRING_VALUE_0)
                XCTAssertEqual(++counter, 2)
                expts[2]!.fulfill()
                return APlusPromise(reason: ERROR_1)
            }.then(
                onFulfilled: { (value) -> Any? in
                    XCTAssertFalse(true)
                    return toFulfill
                },
                onRejected: { (reason) -> Any? in
                    XCTAssertEqual(reason as NSError, ERROR_1)
                    XCTAssertEqual(++counter, 3)
                    expts[3]!.fulfill()
                    return toFulfill
            }).then { (value) -> Any? in
                XCTAssertEqual(value as String, STRING_VALUE_2)
                XCTAssertEqual(++counter, 4)
                expts[4]!.fulfill()
                return toReject
            }.catch { (reason) -> Any? in
                XCTAssertEqual(reason as NSError, ERROR_2)
                XCTAssertEqual(++counter, 5)
                expts[5]!.fulfill()
                return nil
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
        
        APlusPromise(reason: ERROR_0)
            .then(
                onFulfilled: { (value) -> Any? in
                    XCTAssertFalse(true)
                    return STRING_VALUE_0
                },
                onRejected: { (reason) -> Any? in
                    XCTAssertEqual(reason as NSError, ERROR_0)
                    expts[0]!.fulfill()
                    return STRING_VALUE_0
            }).then(
                onFulfilled: { (value) -> Any? in
                    XCTAssertEqual(value as String, STRING_VALUE_0)
                    expts[1]!.fulfill()
                    return STRING_VALUE_1
                },
                onRejected: { (reason) -> Any? in
                    XCTAssertFalse(true)
                    return STRING_VALUE_1
            }).then { (value) -> Any? in
                XCTAssertEqual(value as String, STRING_VALUE_1)
                expts[2]!.fulfill()
                return STRING_VALUE_2
            }.then { (value) -> Any? in
                XCTAssertEqual(value as String, STRING_VALUE_2)
                expts[3]!.fulfill()
                return nil
        }
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
        })
    }
    
    func test_chain_nil() {
        
        var expts: [Int: XCTestExpectation] = [:]
        for index in 0...3 {
            expts[index] = expectationWithDescription("\(__FUNCTION__)_\(index)")
        }
        
        APlusPromise(reason: ERROR_0)
            .then(
                onFulfilled: { (value) -> Any? in
                    XCTAssertFalse(true)
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    XCTAssertEqual(reason as NSError, ERROR_0)
                    expts[0]!.fulfill()
                    return nil
            }).then(
                onFulfilled: { (value) -> Any? in
                    XCTAssertTrue(value == nil)
                    expts[1]!.fulfill()
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    XCTAssertFalse(true)
                    return nil
            }).then { (value) -> Any? in
                XCTAssertTrue(value == nil)
                expts[2]!.fulfill()
                return nil
            }.then { (value) -> Any? in
                XCTAssertTrue(value == nil)
                expts[3]!.fulfill()
                return nil
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
    
    // MARK: - reject(_)
    
    
    // MARK: - all
    
    func test_init_all_fulfill() {
        
        //let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = Promise(value: STRING_VALUE_0)
        let prms2 = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }
        
        
    }
    
    // MARK: - race

    /*
    func test_init()
    {
        let pendingPrms = APlusPromise()
        XCTAssertNotNil(pendingPrms)
        XCTAssertEqual(pendingPrms.state, APlusPromise.State.Pending)
        XCTAssertTrue(pendingPrms.value == nil)
        XCTAssertTrue(pendingPrms.reason == nil)

        (pendingPrms.value as APlusPromise?) == nil
        
        let fulfulledPrms = APlusPromise(value: value1)
        XCTAssertNotNil(fulfulledPrms)
        XCTAssertEqual(fulfulledPrms.state, APlusPromise.State.Fulfilled)
        XCTAssertEqual((fulfulledPrms.value as String), value1)
        XCTAssertTrue(fulfulledPrms.reason == nil)

        let error = NSError()
        let rejectedPrms = APlusPromise(reason: error)
        XCTAssertNotNil(rejectedPrms)
        XCTAssertEqual(rejectedPrms.state, APlusPromise.State.Rejected)
        XCTAssertTrue(rejectedPrms.value == nil)
        XCTAssertEqual((rejectedPrms.reason as NSError), error)
    }
    
    func test_init_withAction()
    {
        let actionPrms = APlusPromise { (resolve, reject) -> Void in
        }
        
        XCTAssertNotNil(actionPrms)
        XCTAssertEqual(actionPrms.state, APlusPromise.State.Pending)
        XCTAssertTrue(actionPrms.value == nil)
        XCTAssertTrue(actionPrms.reason == nil)
        
        let actionPrmsFulfill = APlusPromise { (resolve, reject) -> Void in
            resolve(value: value1)
            reject(reason: error1)
            resolve(value: value2)
            reject(reason: error2)
        }
        
        XCTAssertNotNil(actionPrmsFulfill)
        XCTAssertEqual(actionPrmsFulfill.state, APlusPromise.State.Fulfilled)
        XCTAssertEqual((actionPrmsFulfill.value as String), value1)
        XCTAssertTrue(actionPrmsFulfill.reason == nil)

        let actionPrmsReject = APlusPromise { (resolve, reject) -> Void in
            reject(reason: error1)
            resolve(value: value1)
            reject(reason: error2)
            resolve(value: value2)
        }
        
        XCTAssertNotNil(actionPrmsReject)
        XCTAssertEqual(actionPrmsReject.state, APlusPromise.State.Rejected)
        XCTAssertTrue(actionPrmsReject.value == nil)
        XCTAssertEqual((actionPrmsReject.reason as NSError), error1)
    }
    
    func test_init_withAction_fulfill()
    {
        let expectation = expectationWithDescription(__FUNCTION__);

        let actionPrms = APlusPromise { (resolve, reject) -> Void in
            
            let block = { () -> Void in
                resolve(value: value1)
                reject(reason: error1)
                resolve(value: value2)
                reject(reason: error2)
            }
            
            () ~> block()
        }
        actionPrms.then(
            onFulfilled: { (value) -> Any? in
                
                XCTAssertEqual((value as String), value1)
                
                XCTAssertEqual(actionPrms.state, APlusPromise.State.Fulfilled)
                XCTAssertTrue((actionPrms.value as String) == value1)
                XCTAssertTrue(actionPrms.reason == nil)

                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true, "")
                return nil
            }
        )
        
        waitForExpectationsWithTimeout(7) { println($0) };
    }
    
    func test_initWithActionReject()
    {
        let expectation = expectationWithDescription(__FUNCTION__);
        
        let actionPrms = APlusPromise { (resolve, reject) -> Void in
            
            let block = { () -> Void in
                reject(reason: error1)
                resolve(value: value1)
                reject(reason: error2)
                resolve(value: value2)
            }
            
            () ~> block()
        }
        actionPrms.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true, "")
                return nil
            },
            onRejected: { (reason) -> Any? in
                
                XCTAssertEqual((reason as NSError), error1)
                
                XCTAssertEqual(actionPrms.state, APlusPromise.State.Rejected)
                XCTAssertTrue(actionPrms.value == nil)
                XCTAssertEqual((actionPrms.reason as NSError), error1)
                
                expectation.fulfill()
                return nil
            }
        )
        
        waitForExpectationsWithTimeout(7) { println($0) };
    }

    func test_init_thenable()
    {
        let thenObject = APlusPromise()
        let thenPrms = APlusPromise(thenable: thenObject)
        XCTAssertNotNil(thenPrms)
        XCTAssertEqual(thenPrms.state, APlusPromise.State.Pending)
        XCTAssertTrue(thenPrms.value == nil)
        XCTAssertTrue(thenPrms.reason == nil)
    }
    
    func test_init_thenable_fulfill()
    {
        var resolver: APlusPromise.APlusResolver? = nil
        var rejecter: APlusPromise.APlusRejector? = nil
        
        let thenObject = APlusPromise { (resolve, reject) -> Void in
            resolver = resolve
            rejecter = reject
        }
        let thenPrms = APlusPromise(thenable: thenObject)

        resolver!(value: value1)
        rejecter!(reason: error1)
        resolver!(value: value2)
        rejecter!(reason: error2)

        XCTAssertEqual(thenPrms.state, APlusPromise.State.Fulfilled)
        XCTAssertEqual(thenPrms.value as String, value1)
        XCTAssertTrue(thenPrms.reason == nil)
    }

    func test_initThenable_reject()
    {
        var resolver: APlusPromise.APlusResolver? = nil
        var rejecter: APlusPromise.APlusRejector? = nil
        
        let thenObject = APlusPromise { (resolve, reject) -> Void in
            resolver = resolve
            rejecter = reject
        }
        let thenPrms = APlusPromise(thenable: thenObject)
        
        rejecter!(reason: error1)
        resolver!(value: value1)
        rejecter!(reason: error2)
        resolver!(value: value2)
        
        XCTAssertEqual(thenPrms.state, APlusPromise.State.Rejected)
        XCTAssertTrue(thenPrms.value == nil)
        XCTAssertEqual((thenPrms.reason as NSError), error1)
    }
    
    func test_resolve()
    {
        let promiseValue = APlusPromise()
        let promise1 = APlusPromise.resolve(promiseValue)
        XCTAssertTrue(promise1 === promiseValue)
        
        let promise2 = APlusPromise.resolve(value1)
        XCTAssertEqual(promise2.state, APlusPromise.State.Fulfilled)
        XCTAssertTrue((promise2.value as String) == value1)
        XCTAssertTrue(promise2.reason == nil)
    }

    func test_reject()
    {
        let promise1 = APlusPromise.reject(error1)
        XCTAssertEqual(promise1.state, APlusPromise.State.Rejected)
        XCTAssertTrue(promise1.value == nil)
        XCTAssertEqual((promise1.reason as NSError), error1)
    }
    
    func test_all_fullfill_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise(value: nil)
        let prms3 = APlusPromise { (resolve, reject) -> Void in
            () ~> resolve(value: value1)
        }
        
        let promise = APlusPromise.all(prms1, value2, prms3)
        promise.then(
            onFulfilled: { (value) -> Any? in
                
                let results = value as [Any?]
                XCTAssertTrue((results[0] as Any?) == nil)
                XCTAssertEqual((results[1] as String), value2)
                XCTAssertEqual((results[2] as String), value1)
                
                
                XCTAssertEqual(promise.state, APlusPromise.State.Fulfilled)
                XCTAssertTrue(promise.reason == nil)
                
                let promiseResults = promise.value as [Any?]
                XCTAssertTrue((promiseResults[0] as Any?) == nil)
                XCTAssertEqual((promiseResults[1] as String), value2)
                XCTAssertEqual((promiseResults[2] as String), value1)

                
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_all_fulfill_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise(value: value1)
        let promise = APlusPromise.all(nil, value2, prms1)

        promise.then(
            onFulfilled: { (value) -> Any? in
                
                let results = value as [Any?]
                XCTAssertTrue((results[0] as Any?) == nil)
                XCTAssertEqual((results[1] as String), value2)
                XCTAssertEqual((results[2] as String), value1)
                
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )

        promise.then()  //  Test pass nil as callback

        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Fulfilled)
        XCTAssertTrue(promise.reason == nil)
        
        let results = promise.value as [Any?]
        XCTAssertTrue((results[0] as Any?) == nil)
        XCTAssertEqual((results[1] as String), value2)
        XCTAssertEqual((results[2] as String), value1)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_all_reject_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        var counter = 0
        
        let prms1 = APlusPromise(value: value1)
        let prms3 = APlusPromise { (resolve, reject) -> Void in
            () ~> reject(reason: error2)
        }
        
        let promise = APlusPromise.all(prms1, value2, prms3)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                
                XCTAssertEqual((reason as NSError), error2)
                
                XCTAssertEqual(promise.state, APlusPromise.State.Rejected)
                XCTAssertTrue(promise.value == nil)
                XCTAssertEqual((promise.reason as NSError), error2)

                XCTAssertTrue(++counter < 2)

                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }

    func test_all_reject_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        var counter = 0
        
        let prms1 = APlusPromise(reason: error1)
        let prms3 = APlusPromise { (resolve, reject) -> Void in
            () ~> reject(reason: error2)
        }
        
        let promise = APlusPromise.all(prms1, value2, prms3)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual((reason as NSError), error1)
                
                XCTAssertEqual(promise.state, APlusPromise.State.Rejected)
                XCTAssertTrue(promise.value == nil)
                XCTAssertEqual((promise.reason as NSError), error1)

                XCTAssertTrue(++counter < 2)
                
                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Rejected)
        XCTAssertTrue(promise.value == nil)
        XCTAssertEqual((promise.reason as NSError), error1)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }

    func test_race_fulfill_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise(value: value1)
        let prms2 = APlusPromise(reason: error1)
        let promise = APlusPromise.race(prms1, value2, prms2)
        
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual(value as String, value1)
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Fulfilled)
        XCTAssertEqual(promise.value as String, value1)
        XCTAssertTrue(promise.reason == nil)

        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_race_fulfill_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise { (resolve, reject) -> Void in
            () ~> resolve(value: value1)
        }
        let prms2 = APlusPromise()
        let prms3 = APlusPromise()
        
        let promise = APlusPromise.race(prms1, prms2, prms3)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual(value as String, value1)
                
                expectation.fulfill()

                XCTAssertEqual(promise.state, APlusPromise.State.Fulfilled)
                XCTAssertEqual(promise.value as String, value1)
                XCTAssertTrue(promise.reason == nil)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }

    func test_race_reject_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise()
        let prms2 = APlusPromise(reason: error1)
        let promise = APlusPromise.race(prms1, prms2, value1)
        
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual(reason as NSError, error1)
                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Rejected)
        XCTAssertTrue(promise.value == nil)
        XCTAssertEqual(promise.reason as NSError, error1)
        
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_race_reject_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise()
        let prms2 = APlusPromise { (resolve, reject) -> Void in
            () ~> reject(reason: error1)
        }
        let prms3 = APlusPromise()
        let promise = APlusPromise.race(prms1, prms2, prms3)
        
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual(reason as NSError, error1)
                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    // spec 2.2.6 2.2.6.1
    func test_then_sync()
    {
        let expectationSync0 = expectationWithDescription("\(__FUNCTION__)0")
        let expectationSync1 = expectationWithDescription("\(__FUNCTION__)1")
        var counter = 0
        
        let syncPromise = APlusPromise { (resolve, reject) -> Void in
            resolve(value: value1)
        }
        syncPromise.then(onFulfilled:
            { (value) -> Any? in
                XCTAssertEqual((value as String), value1)
                XCTAssertEqual(counter++, 0)
                expectationSync0.fulfill()
                return nil
            }
        )
        syncPromise.then(onFulfilled:
            { (value) -> Any? in
                XCTAssertEqual((value as String), value1)
                XCTAssertEqual(counter++, 1)
                expectationSync1.fulfill()
                return nil
            }
        )
        syncPromise.then()  //  Test pass nil as callback

        
        XCTAssertEqual(syncPromise.state, APlusPromise.State.Fulfilled)
        XCTAssertEqual((syncPromise.value as String), value1)
        XCTAssertTrue(syncPromise.reason == nil)
        
        
        waitForExpectationsWithTimeout(7) { println($0)}
    }
    
    // spec 2.2.6 2.2.6.1
    func test_then_async()
    {
        let expectationAsync0 = expectationWithDescription("\(__FUNCTION__)0")
        let expectationAsync1 = expectationWithDescription("\(__FUNCTION__)1")
        var counter = 0

        let asyncPromise = APlusPromise { (resolve, reject) -> Void in
            () ~> resolve(value: value1)
        }
        asyncPromise.then(
            onFulfilled:
            { (value) -> Any? in
                XCTAssertEqual((value as String), value1)
                XCTAssertEqual(counter++, 0)
                expectationAsync0.fulfill()
                return nil
            }
        )
        asyncPromise.then(
            onFulfilled:
            { (value) -> Any? in
                XCTAssertEqual((value as String), value1)
                XCTAssertEqual(counter++, 1)
                expectationAsync1.fulfill()
                return nil
            }
        )
        asyncPromise.then()  //  Test pass nil as callback

        XCTAssertEqual(asyncPromise.state, APlusPromise.State.Pending)
        XCTAssertTrue(asyncPromise.value == nil)
        XCTAssertTrue(asyncPromise.reason == nil)

        
        waitForExpectationsWithTimeout(7) { println($0)}
    }
    
    // spec 2.2.6 2.2.6.2
    func test_catch_sync()
    {
        let expectation0 = expectationWithDescription("\(__FUNCTION__)0")
        let expectation1 = expectationWithDescription("\(__FUNCTION__)1")
        var counter = 0
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            reject(reason: error1)
        }
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error1)
            XCTAssertEqual(counter++, 0)
            expectation0.fulfill()
            return nil
        }
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error1)
            XCTAssertEqual(counter++, 1)
            expectation1.fulfill()
            return nil
        }

        XCTAssertEqual(promise.state, APlusPromise.State.Rejected)
        XCTAssertTrue(promise.value == nil)
        XCTAssertEqual(promise.reason as NSError, error1)
        
        
        waitForExpectationsWithTimeout(7) { println($0)}
    }
    
    // spec 2.2.6 2.2.6.2
    func test_catch_async()
    {
        let expectation0 = expectationWithDescription("\(__FUNCTION__)0")
        let expectation1 = expectationWithDescription("\(__FUNCTION__)1")
        var counter = 0
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            () ~> reject(reason: error1)
        }
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error1)
            XCTAssertEqual(counter++, 0)
            expectation0.fulfill()
            return nil
        }
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error1)
            XCTAssertEqual(counter++, 1)
            expectation1.fulfill()
            return nil
        }
        
        XCTAssertEqual(promise.state, APlusPromise.State.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        
        waitForExpectationsWithTimeout(7) { println($0)}
    }
    
    // spec 2.3.1
    func test_chain_typeError_fulfill()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        var promiseRefer: APlusPromise? = nil
        
        let promise = APlusPromise
            { (resolve, reject) -> Void in
                () ~> resolve(value: value1)
            }.then(onFulfilled: { (value) -> Any? in
                return promiseRefer
            })
        promiseRefer = promise
        
        promise.catch { (reason) -> Any? in
            XCTAssertEqual((reason as NSError).domain, PromiseErrorDomain)
            XCTAssertEqual((reason as NSError).code, PromiseTypeError)
            expectation.fulfill()
            return nil
        }
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    // spec 2.3.1
    func test_chain_typeError_reject()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        var promiseRefer: APlusPromise? = nil
        
        let promise = APlusPromise
            { (resolve, reject) -> Void in
                () ~> reject(reason: value1)
            }
            .catch { (reason) -> Any? in
                return promiseRefer
        }
        promiseRefer = promise
        
        promise.catch { (reason) -> Any? in
            XCTAssertEqual((reason as NSError).domain, PromiseErrorDomain)
            XCTAssertEqual((reason as NSError).code, PromiseTypeError)
            expectation.fulfill()
            return nil
        }
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_chain()
    {
        let expectation0 = expectationWithDescription("\(__FUNCTION__)0")
        let expectation1 = expectationWithDescription("\(__FUNCTION__)1")
        let expectation2 = expectationWithDescription("\(__FUNCTION__)2")
        let expectation3 = expectationWithDescription("\(__FUNCTION__)3")
        let expectation4 = expectationWithDescription("\(__FUNCTION__)4")
        let expectation5 = expectationWithDescription("\(__FUNCTION__)5")
        let expectation6 = expectationWithDescription("\(__FUNCTION__)6")
        let expectation7 = expectationWithDescription("\(__FUNCTION__)7")

        let promise = APlusPromise { (resolve, reject) -> Void in
            () ~> resolve(value: value1)
        }.then(onFulfilled: { (value) -> Any? in
            XCTAssertEqual(value as String, value1)
            expectation0.fulfill()
            return value2
        }).then(onFulfilled: { (value) -> Any? in
            XCTAssertEqual(value as String, value2)
            expectation1.fulfill()
            return APlusPromise(value: value3)
        }).then(onFulfilled: { (value) -> Any? in
            XCTAssertEqual(value as String, value3)
            expectation2.fulfill()
            return APlusPromise(reason: error1)
        }).catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error1)
            expectation3.fulfill()
            return nil
        }.then(onFulfilled: { (value) -> Any? in
            XCTAssertTrue(value == nil)
            expectation4.fulfill()
            return nil
        }).then(onFulfilled: { (value) -> Any? in
            XCTAssertTrue(value == nil)
            expectation5.fulfill()
            return APlusPromise(reason: error2)
        }).catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error2)
            expectation6.fulfill()
            return APlusPromise(resolver: { (resolve, reject) -> Void in
                () ~> reject(reason: error3)
            })
        }.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error3)
            expectation7.fulfill()
            return nil
        }
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
*/
}
