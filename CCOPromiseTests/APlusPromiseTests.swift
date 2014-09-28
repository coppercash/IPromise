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

infix operator ~> {}
func ~> (lhs: @autoclosure () -> Any, rhs: @autoclosure () -> ())
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        lhs();
        dispatch_sync(dispatch_get_main_queue(), rhs)
    })
}


class APlusPromiseTests: XCTestCase
{
    func test_init()
    {
        let pendingPrms = APlusPromise()
        XCTAssertNotNil(pendingPrms)
        XCTAssertEqual(pendingPrms.state, APlusPromise.State.Pending)
        XCTAssertTrue(pendingPrms.value == nil)
        XCTAssertTrue(pendingPrms.reason == nil)

        (pendingPrms.value as APlusPromise?) == nil
        
        let fulfulledPrms = APlusPromise(value: "A value")
        XCTAssertNotNil(fulfulledPrms)
        XCTAssertEqual(fulfulledPrms.state, APlusPromise.State.Fulfilled)
        XCTAssertEqual((fulfulledPrms.value as String), "A value")
        XCTAssertTrue(fulfulledPrms.reason == nil)

        let error = NSError()
        let rejectedPrms = APlusPromise(reason: error)
        XCTAssertNotNil(rejectedPrms)
        XCTAssertEqual(rejectedPrms.state, APlusPromise.State.Rejected)
        XCTAssertTrue(rejectedPrms.value == nil)
        XCTAssertEqual((rejectedPrms.reason as NSError), error)
    }
    
    func test_initWithAction()
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
                XCTAssertEqual((value as String), value1)
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true, "")
                return nil
            }
        )
        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertEqual(actionPrms.state, APlusPromise.State.Fulfilled)
            XCTAssertTrue((actionPrms.value as String) == value1)
            XCTAssertTrue(actionPrms.reason == nil)
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
                XCTAssertEqual((reason as NSError), error1)
                expectation.fulfill()
                return nil
            }
        )
        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertEqual(actionPrms.state, APlusPromise.State.Rejected)
            XCTAssertTrue(actionPrms.value == nil)
            XCTAssertEqual((actionPrms.reason as NSError), error1)
        };
    }

    func test_initThenable()
    {
        let thenObject = APlusPromise()
        let thenPrms = APlusPromise(thenable: thenObject)
        XCTAssertNotNil(thenPrms)
        XCTAssertEqual(thenPrms.state, APlusPromise.State.Pending)
        XCTAssertTrue(thenPrms.value == nil)
        XCTAssertTrue(thenPrms.reason == nil)
    }
    
    func test_initThenableFulfill()
    {
        var resolver: APlusPromise.APlusResovler? = nil
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
        XCTAssertTrue((thenPrms.value as String) == value1)
        XCTAssertTrue(thenPrms.reason == nil)
    }

    func test_initThenableReject()
    {
        var resolver: APlusPromise.APlusResovler? = nil
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
        let expectation = expectationWithDescription("allFulfillAsync")
        
        let prms1 = APlusPromise(value: nil)
        let prms3 = APlusPromise { (resolve, reject) -> Void in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    resolve(value: value1)
                })
            })
        }
        
        let promise = APlusPromise.all([prms1, value2, prms3])
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
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(1, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, APlusPromise.State.Fulfilled)
            XCTAssertTrue(promise.reason == nil)
            
            let results = promise.value as [Any?]
            XCTAssertTrue((results[0] as Any?) == nil)
            XCTAssertEqual((results[1] as String), value2)
            XCTAssertEqual((results[2] as String), value1)
        })
    }
    
    func test_all_fulfill_sync()
    {
        let expectation = expectationWithDescription("allFulfillSync")
        
        let prms1 = APlusPromise(value: value1)
        let promise = APlusPromise.all([nil, value2, prms1])

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
        
        waitForExpectationsWithTimeout(1) { println($0) }
    }
    
    func test_all_reject_async()
    {
        let expectation = expectationWithDescription("allRejectAsync")
        var times = 0
        
        let prms1 = APlusPromise(value: value1)
        let prms3 = APlusPromise { (resolve, reject) -> Void in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    reject(reason: error2)
                })
            })
        }
        
        let promise = APlusPromise.all([prms1, value2, prms3])
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual((reason as NSError), error2)
                expectation.fulfill()
                XCTAssertTrue(++times < 2)
                return nil
            }
        )
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(1, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, APlusPromise.State.Rejected)
            XCTAssertTrue(promise.value == nil)
            XCTAssertEqual((promise.reason as NSError), error2)
        })
    }

    func test_all_reject_sync()
    {
        let expectation = expectationWithDescription("allRejectSync")
        var times = 0
        
        let prms1 = APlusPromise(reason: error1)
        let prms3 = APlusPromise { (resolve, reject) -> Void in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    reject(reason: error2)
                })
            })
        }
        
        let promise = APlusPromise.all([prms1, value2, prms3])
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual((reason as NSError), error1)
                expectation.fulfill()
                XCTAssertTrue(++times < 2)
                return nil
            }
        )
        
        XCTAssertNotNil(promise)
        XCTAssertEqual(promise.state, APlusPromise.State.Rejected)
        XCTAssertTrue(promise.value == nil)
        XCTAssertEqual((promise.reason as NSError), error1)
        
        waitForExpectationsWithTimeout(1, handler: { (error) -> Void in
            XCTAssertEqual(promise.state, APlusPromise.State.Rejected)
            XCTAssertTrue(promise.value == nil)
            XCTAssertEqual((promise.reason as NSError), error1)
        })
    }

    func test_race_fulfill_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise(value: value1)
        let prms2 = APlusPromise(reason: error1)
        let promise = APlusPromise.race([prms1, value2, prms2])
        
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

        
        waitForExpectationsWithTimeout(1) { println($0) }
    }
    
    func test_race_fulfill_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise { (resolve, reject) -> Void in
            () ~> resolve(value: value1)
        }
        let prms2 = APlusPromise()
        let prms3 = APlusPromise()
        
        let promise = APlusPromise.race([prms1, prms2, prms3])
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
        
        waitForExpectationsWithTimeout(1) { println($0) }
    }

    func test_race_reject_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise()
        let prms2 = APlusPromise(reason: error1)
        let promise = APlusPromise.race([prms1, prms2, value1])
        
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
        
        
        waitForExpectationsWithTimeout(1) { println($0) }
    }
    
    func test_race_reject_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise()
        let prms2 = APlusPromise { (resolve, reject) -> Void in
            () ~> reject(reason: error1)
        }
        let prms3 = APlusPromise()
        let promise = APlusPromise.race([prms1, prms2, prms3])
        
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
        
        
        waitForExpectationsWithTimeout(1) { println($0) }
    }
    
    // spec 2.2.6 2.2.6.1
    func test_then_sync()
    {
        let expectationSync0 = expectationWithDescription("thenSync0")
        let expectationSync1 = expectationWithDescription("thenSync1")
        var syncTime = 0
        
        let syncPromise = APlusPromise { (resolve, reject) -> Void in
            resolve(value: value1)
        }
        syncPromise.then(onFulfilled:
            { (value) -> Any? in
                XCTAssertEqual((value as String), value1)
                XCTAssertEqual(syncTime++, 0)
                expectationSync0.fulfill()
                return nil
            }
        )
        syncPromise.then(onFulfilled:
            { (value) -> Any? in
                XCTAssertEqual((value as String), value1)
                XCTAssertEqual(syncTime++, 1)
                expectationSync1.fulfill()
                return nil
            }
        )
        syncPromise.then()  //  Test pass nil as callback

        
        XCTAssertEqual(syncPromise.state, APlusPromise.State.Fulfilled)
        XCTAssertEqual((syncPromise.value as String), value1)
        XCTAssertTrue(syncPromise.reason == nil)
        
        
        waitForExpectationsWithTimeout(1) { println($0)}
    }
    
    // spec 2.2.6 2.2.6.1
    func test_then_async()
    {
        let expectationAsync0 = expectationWithDescription("thenAsync0")
        let expectationAsync1 = expectationWithDescription("thenAsync1")
        var asyncTime = 0

        let asyncPromise = APlusPromise { (resolve, reject) -> Void in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    resolve(value: value1)
                })
            })
        }
        asyncPromise.then(
            onFulfilled:
            { (value) -> Any? in
                XCTAssertEqual((value as String), value1)
                XCTAssertEqual(asyncTime++, 0)
                expectationAsync0.fulfill()
                return nil
            }
        )
        asyncPromise.then(
            onFulfilled:
            { (value) -> Any? in
                XCTAssertEqual((value as String), value1)
                XCTAssertEqual(asyncTime++, 1)
                expectationAsync1.fulfill()
                return nil
            }
        )
        asyncPromise.then()  //  Test pass nil as callback

        XCTAssertEqual(asyncPromise.state, APlusPromise.State.Pending)
        XCTAssertTrue(asyncPromise.value == nil)
        XCTAssertTrue(asyncPromise.reason == nil)

        
        waitForExpectationsWithTimeout(1) { println($0)}
    }
    
    // spec 2.2.6 2.2.6.2
    func test_catch_sync()
    {
        let expectation0 = expectationWithDescription("\(__FUNCTION__)0")
        let expectation1 = expectationWithDescription("\(__FUNCTION__)1")
        var time = 0
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            reject(reason: error1)
        }
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error1)
            XCTAssertEqual(time++, 0)
            expectation0.fulfill()
            return nil
        }
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error1)
            XCTAssertEqual(time++, 1)
            expectation1.fulfill()
            return nil
        }

        XCTAssertEqual(promise.state, APlusPromise.State.Rejected)
        XCTAssertTrue(promise.value == nil)
        XCTAssertEqual(promise.reason as NSError, error1)
        
        
        waitForExpectationsWithTimeout(1) { println($0)}
    }
    
    // spec 2.2.6 2.2.6.2
    func test_catch_async()
    {
        let expectation0 = expectationWithDescription("\(__FUNCTION__)0")
        let expectation1 = expectationWithDescription("\(__FUNCTION__)1")
        var time = 0
        
        let promise = APlusPromise { (resolve, reject) -> Void in
            () ~> reject(reason: error1)
        }
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error1)
            XCTAssertEqual(time++, 0)
            expectation0.fulfill()
            return nil
        }
        promise.catch { (reason) -> Any? in
            XCTAssertEqual(reason as NSError, error1)
            XCTAssertEqual(time++, 1)
            expectation1.fulfill()
            return nil
        }
        
        XCTAssertEqual(promise.state, APlusPromise.State.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        
        waitForExpectationsWithTimeout(1) { println($0)}
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
            XCTAssertEqual(reason as NSError, NSError.aPlusPromiseTypeError())
            expectation.fulfill()
            return nil
        }
        
        waitForExpectationsWithTimeout(1) { println($0) }
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
            XCTAssertEqual(reason as NSError, NSError.aPlusPromiseTypeError())
            expectation.fulfill()
            return nil
        }
        
        waitForExpectationsWithTimeout(1) { println($0) }
    }
}
