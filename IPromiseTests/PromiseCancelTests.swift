//
//  PromiseCancelTests.swift
//  IPromise
//
//  Created by William Remaerd on 12/10/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import UIKit
import XCTest
import IPromise

class PromiseCancelTests: XCTestCase {

    /*
    The cancel of a promise will succeed if it is failed with 'CancelError' as reason
    */
    func test_cancel_state() {
        var expts: [XCTestExpectation] = []
        for index in 0...5 {
            expts.append(expectationWithDescription("\(__FUNCTION__)_\(index)"))
        }
        
        let fulfilledPromise = Promise<String>(value: STRING_VALUE_0)
        fulfilledPromise.cancel().then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                XCTAssertEqual(PromiseWrongStateError, reason.code)
                expts[0].fulfill()
        })
        
        let rejectedPromise = Promise<String>(reason: ERROR_0)
        rejectedPromise.cancel().then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                XCTAssertEqual(PromiseWrongStateError, reason.code)
                expts[1].fulfill()
        })
        
        let (canceledDeferred, canceledPromise) = Promise<String>.defer()
        canceledPromise.catch { (reason) -> Void in
            XCTAssertEqual(PromiseCancelError, reason.code)
            expts[4].fulfill()
        }
        canceledPromise.cancel().then(
            onFulfilled: { (value) -> Void in
                expts[2].fulfill()
            },
            onRejected: { (reason) -> Void in
                XCTAssertFalse(true)
        })
        
        let (canceledTwiceDeferred, canceledTwicePromise) = Promise<String>.defer()
        canceledTwiceDeferred.onCanceled { () -> Void in
            
        }
        canceledTwicePromise.cancel()
        canceledTwicePromise.cancel().then(
            onFulfilled: { (value) -> Void in
                expts[3].fulfill()
            },
            onRejected: { (reason) -> Void in
                XCTAssertFalse(true)
        })
        canceledTwicePromise.catch { (reason) -> Void in
            XCTAssertEqual(PromiseCancelError, reason.code)
            expts[5].fulfill()
        }
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    /*
    The promise returned from method `Promise#cancel` will be rejected if there is promise fulfilled or rejected in chain.
    */
    func test_cancel_fail_stateChange() {
        let expts = expectationsFor(indexes: [Int](0...1), descPrefix: __FUNCTION__)
        var sequencer = 0
        
        let deferred = Deferred<String>()
        deferred.onCanceled { () -> Promise<Void> in
            let deferred = Deferred<Void>()
            7 ~> deferred.resolve()
            return deferred.promise
        }
       
        0.1 ~> {
            expts[sequencer].fulfill()
            XCTAssertEqual(0, sequencer++)
            deferred.resolve(STRING_VALUE_0)
            }()
        
        deferred.promise.cancel().then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                expts[sequencer].fulfill()
                XCTAssertEqual(1, sequencer++)
                XCTAssertEqual(PromiseWrongStateError, reason.code)
            }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    /*
    If the tail promise of a then-chain canceled and no branch on the chain, the head deferred gets notificatiion.
    And no callback in the middle gets notificatiion.
    */
    func test_cancel_chain() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let (headDeferred, headPromise) = Promise<Void>.defer()
        
        headDeferred.onCanceled { () -> Void in
            expt.fulfill()
            return
        }
        
        // Each kind of then method once to ensure every one works
        
        let tailPromise = headPromise
            .then(
                onFulfilled: { (value) -> Promise<Void> in
                    XCTAssertFalse(true)
                    return Promise<Void>(value: ())
                },
                onRejected: { (reason) -> Promise<Void> in
                    XCTAssertFalse(true)
                    return Promise<Void>(value: ())
                }
            )
            .then(
                onFulfilled: { (value) -> String in
                    XCTAssertFalse(true)
                    return STRING_VALUE_0
                },
                onRejected: { (reason) -> String in
                    XCTAssertFalse(true)
                    return STRING_VALUE_1
                }
            )
            .then(
                onFulfilled: { (value) -> Void in
                    XCTAssertFalse(true)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertFalse(true)
                }
            )
            .catch (ignored: {(reason) -> Void in
                XCTAssertFalse(true)
            })
        
        tailPromise.cancel()
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    /*
    The promise returned from method `Promise#cancel` will be fulfilled after onCanceled block being invoked if no promise returned from it
    */
    func test_cancel_onCanceled_returnVoid() {
        var expts: [XCTestExpectation] = []
        for index in 0..<2 {
            expts.append(expectationWithDescription("\(__FUNCTION__)_\(index)"))
        }
        var sequencer = 0
        
        let (deferred, promise) = Promise<Void>.defer()
        
        deferred.onCanceled { () -> Void in
            XCTAssertEqual(0, sequencer)
            expts[sequencer].fulfill()
            sequencer++
        }
        
        promise.cancel().then(onFulfilled: { (value) -> Void in
            XCTAssertEqual(1, sequencer)
            expts[sequencer].fulfill()
            sequencer++
        })
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    /*
    The promise returned from method `Promise#cancel` will be fulfilled or rejected base on the the onCanceled block of the deferred object.
    */
    func test_cancel_onCanceled_returnPromise_fulfill() {
        var expts: [XCTestExpectation] = []
        for index in 0..<2 {
            expts.append(expectationWithDescription("\(__FUNCTION__)_\(index)"))
        }
        var sequencer = 0
        
        let (deferred, promise) = Promise<Void>.defer()
        
        deferred.onCanceled { () -> Promise<Void> in
            let (deferred, promise) = Promise<Void>.defer()
            
            0.1 ~> {
                XCTAssertEqual(0, sequencer)
                expts[sequencer].fulfill()
                sequencer++
                deferred.resolve()
                }()
            
            return promise
        }
        
        promise.cancel().then(
            onFulfilled: { (value) -> Void in
                XCTAssertEqual(1, sequencer)
                expts[sequencer].fulfill()
                sequencer++
            },
            onRejected: { (reason) -> Void in
                XCTAssertFalse(true)
            }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    func test_cancel_onCanceled_returnPromise_reject() {
        var expts = expectationsFor(indexes:[Int](0...1), descPrefix: __FUNCTION__)
        var sequencer = 0
        
        let (deferred, promise) = Promise<Void>.defer()
        
        deferred.onCanceled { () -> Promise<Void> in
            let (deferred, promise) = Promise<Void>.defer()
            
            0.1 ~> {
                expts[sequencer].fulfill()
                XCTAssertEqual(0, sequencer++)
                deferred.reject(ERROR_0)
                }()
            
            return promise
        }
        
        promise.cancel().then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                XCTAssertEqual(ERROR_0, reason)
                
                expts[sequencer].fulfill()
                XCTAssertEqual(1, sequencer++)

                sequencer++
            }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    /*
    The promise is canceled only if all its sub-promises canceled
    */
    func test_cancel_onCanceled_branch() {
        var expts: [XCTestExpectation] = expectationsFor(indexes: [Int](0...2), descPrefix: __FUNCTION__)
        var sequencer = 0
        
        let (deferred, promise) = Promise<Void>.defer()
        
        deferred.onCanceled { () -> Void in
            expts[sequencer].fulfill()
            XCTAssertEqual(0, sequencer++)
        }
        
        let promise0 = promise.then(onFulfilled: { (value) -> String in
            return STRING_VALUE_0
        })
        
        let promise1 = promise.then(onFulfilled: { (value) -> Void in
        })
        
        promise0.cancel().then(onFulfilled: { (value) -> Void in
            expts[sequencer].fulfill()
            XCTAssertEqual(1, sequencer++)
        })
        
        promise1.cancel().then(onFulfilled: { (value) -> Void in
            expts[sequencer].fulfill()
            XCTAssertEqual(2, sequencer++)
        })
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    /*
    If cancel a promise which's result depends on another promise returned in then closures, the depended promise is canceled too
    */
    func test_cancel_leaf() {
        var expts: [Int: XCTestExpectation] = expectationsFor(keys: [Int](0...1), descPrefix: __FUNCTION__)
        
        let promise = Promise<String>(value: STRING_VALUE_1)
        promise
            .then(onFulfilled: { (value) -> Promise<Void> in
                let (d_leaf, p_leaf) = Promise<Void>.defer()
                7 ~> d_leaf.resolve()
                d_leaf.onCanceled({ () -> Promise<Void> in
                    expts[0]!.fulfill()
                    let (d_cancel, p_cancel) = Promise<Void>.defer()
                    0.1 ~> d_cancel.resolve()
                    return p_cancel
                })
                return p_leaf
            })
            .cancel()
            .then(onRejected: { (value) -> Void in
                expts[1]!.fulfill()
            })
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    /*
    A promise will not be canceled unless all its sub-promises have been canceled
    */
    func test_cancel_multipleChildren() {
        let (d_0, p_0) = Promise<String>.defer()
        d_0.onCanceled { () -> Void in
            XCTAssertFalse(true)
            return
        }
        
        let p_00 = p_0.catch { (reason) -> Void in
            XCTAssertFalse(true)
            return
        }
        
        let p_01 = p_0.catch { (reason) -> Void in
            XCTAssertFalse(true)
            return
        }
        
        p_00.cancel().then(
            onFulfilled: { (value) -> Void in
                XCTAssertFalse(true)
            },
            onRejected: { (reason) -> Void in
                XCTAssertEqual(PromiseWrongStateError, reason.code)
        })
        
        d_0.resolve(STRING_VALUE_0)
    }
    
    /*
    A forked promise can not be canceled
    */
    func test_cancel_fork() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let deferred = Deferred<Void>()
        
        deferred.promise
            .fork()
            .cancel()
            .then(
                onFulfilled: { (value) -> Void in
                    XCTAssertFalse(true)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertEqual(PromiseCancelForkedPromiseError, reason.code)
                    XCTAssertEqual(PromiseErrorDomain, reason.domain)
                    expt.fulfill()
                }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }

    /*
    A 'all' promise will be canceled if one of its sub-promises get canceled, but all sub-promises will get a notification in `onCanceled`.
    */
    func test_cancel_all_success() {
        let expts = expectationsFor(indexes: [Int](0...3), descPrefix: __FUNCTION__)
        var sequencer = 0
        
        let d0 = Deferred<String>();
        d0.onCanceled { () -> Promise<Void> in
            expts[sequencer].fulfill()
            XCTAssertEqual(0, sequencer++)
            let deferred = Deferred<Void>()
            7 ~> deferred.resolve()
            return deferred.promise
        }
        
        let d1 = Deferred<String>();
        d1.onCanceled { () -> Promise<Void> in
            expts[sequencer].fulfill()
            XCTAssertEqual(1, sequencer++)
            let deferred = Deferred<Void>()
            7 ~> deferred.resolve()
            return deferred.promise
        }
        
        let d2 = Deferred<String>();
        d2.onCanceled { () -> Promise<Void> in
            let deferred = Deferred<Void>()
            0.1 ~> {
                expts[sequencer].fulfill()
                XCTAssertEqual(2, sequencer++)
                deferred.resolve()
            }()
            return deferred.promise
        }
        
        let promise = Promise.all(d0.promise, d1.promise, d2.promise)
        
        promise.cancel()
            .then(
                onFulfilled: { (value) -> Void in
                    expts[sequencer].fulfill()
                    XCTAssertEqual(3, sequencer++)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertFalse(true)
                }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    func test_cancel_all_fail() {
        let expts = expectationsFor(indexes: [Int](0...2), descPrefix: __FUNCTION__)
        var sequencer = 0
        
        let d0 = Deferred<String>();
        d0.onCanceled { () -> Promise<Void> in
            XCTAssertEqual(0, sequencer)
            expts[sequencer++].fulfill()
            let deferred = Deferred<Void>()
            7 ~> deferred.resolve()
            return deferred.promise
        }
        
        let d1 = Deferred<String>();
        d1.onCanceled { () -> Promise<Void> in
            let deferred = Deferred<Void>()
            0.1 ~> {
                XCTAssertEqual(1, sequencer)
                expts[sequencer++].fulfill()
                deferred.reject(ERROR_0)
                }()
            return deferred.promise
        }
        
        let promise = Promise.all(d0.promise, d1.promise)
        
        promise.cancel()
            .then(
                onFulfilled: { (value) -> Void in
                    XCTAssertFalse(true)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertEqual(ERROR_0, reason)
                    XCTAssertEqual(2, sequencer)
                    expts[sequencer++].fulfill()
                }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    /*
    A 'race' promise will be canceled if one of its sub-promises get canceled, but all sub-promises will get a notification in `onCanceled`.
    */
    func test_cancel_race_success() {
        let expts = expectationsFor(indexes: [Int](0...3), descPrefix: __FUNCTION__)
        var sequencer = 0
        
        let d0 = Deferred<String>();
        d0.onCanceled { () -> Promise<Void> in
            expts[sequencer].fulfill()
            XCTAssertEqual(0, sequencer++)
            let deferred = Deferred<Void>()
            7 ~> deferred.resolve()
            return deferred.promise
        }
        
        let d1 = Deferred<String>();
        d1.onCanceled { () -> Promise<Void> in
            expts[sequencer].fulfill()
            XCTAssertEqual(1, sequencer++)
            let deferred = Deferred<Void>()
            7 ~> deferred.resolve()
            return deferred.promise
        }
        
        let d2 = Deferred<String>();
        d2.onCanceled { () -> Promise<Void> in
            let deferred = Deferred<Void>()
            0.1 ~> {
                expts[sequencer].fulfill()
                XCTAssertEqual(2, sequencer++)
                deferred.resolve()
                }()
            return deferred.promise
        }
        
        let promise = Promise.race(d0.promise, d1.promise, d2.promise)
        
        promise.cancel()
            .then(
                onFulfilled: { (value) -> Void in
                    expts[sequencer].fulfill()
                    XCTAssertEqual(3, sequencer++)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertFalse(true)
                }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    func test_cancel_race_fail() {
        let expts = expectationsFor(indexes: [Int](0...2), descPrefix: __FUNCTION__)
        var sequencer = 0
        
        let d0 = Deferred<String>();
        d0.onCanceled { () -> Promise<Void> in
            XCTAssertEqual(0, sequencer)
            expts[sequencer++].fulfill()
            let deferred = Deferred<Void>()
            7 ~> deferred.resolve()
            return deferred.promise
        }
        
        let d1 = Deferred<String>();
        d1.onCanceled { () -> Promise<Void> in
            let deferred = Deferred<Void>()
            0.1 ~> {
                XCTAssertEqual(1, sequencer)
                expts[sequencer++].fulfill()
                deferred.reject(ERROR_0)
                }()
            return deferred.promise
        }
        
        let promise = Promise.race(d0.promise, d1.promise)
        
        promise.cancel()
            .then(
                onFulfilled: { (value) -> Void in
                    XCTAssertFalse(true)
                },
                onRejected: { (reason) -> Void in
                    XCTAssertEqual(ERROR_0, reason)
                    XCTAssertEqual(2, sequencer)
                    expts[sequencer++].fulfill()
                }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }

}
