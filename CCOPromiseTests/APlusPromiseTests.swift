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
            XCTAssertEqual((reason as NSError).domain, PromiseErrorDomain)
            XCTAssertEqual((reason as NSError).code, PromiseTypeError)

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
            XCTAssertEqual((reason as NSError).domain, PromiseErrorDomain)
            XCTAssertEqual((reason as NSError).code, PromiseTypeError)
            
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
    
    // MARK: - init(thenable:)
    
    func test_init_thenable_fulfill() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = APlusPromise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }
        
        let promise = APlusPromise(thenable: superPromise)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual(value as String, STRING_VALUE_0)
                expt.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        XCTAssertEqual(promise.state, PromiseState.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Fulfilled)
            XCTAssertEqual(promise.value as String, STRING_VALUE_0)
            XCTAssertTrue(promise.reason == nil)
        })
    }
    
    func test_init_thenable_reject() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_0)
        }
        
        let promise = APlusPromise(thenable: superPromise)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual(reason as NSError, ERROR_0)
                expt.fulfill()
                return nil
            }
        )
        
        XCTAssertEqual(promise.state, PromiseState.Pending)
        XCTAssertTrue(promise.value == nil)
        XCTAssertTrue(promise.reason == nil)

        waitForExpectationsWithTimeout(7, handler: { (e) -> Void in
            XCTAssertEqual(promise.state, PromiseState.Rejected)
            XCTAssertTrue(promise.value == nil)
            XCTAssertEqual(promise.reason as NSError, ERROR_0)
        })
    }
    
    // MARK: - resolve(_)
    
    func test_resolve() {
        let q0 = APlusPromise()
        let a0: APlusPromise = APlusPromise.resolve(q0)
        XCTAssertTrue(q0 === a0)
        
        let a1 = APlusPromise.resolve(STRING_VALUE_0)
        XCTAssertEqual(a1.state, PromiseState.Fulfilled)
        XCTAssertEqual(a1.value as String, STRING_VALUE_0)
        XCTAssertTrue(a1.reason == nil)
        
        let a2 = APlusPromise.resolve(nil)
        XCTAssertEqual(a2.state, PromiseState.Fulfilled)
        XCTAssertTrue(a2.value! == nil)
        XCTAssertTrue(a2.reason == nil)
    }
    
    // MARK: - reject(_)
    
    func test_reject() {
        let a0 = APlusPromise.reject(ERROR_0)
        XCTAssertEqual(a0.state, PromiseState.Rejected)
        XCTAssertTrue(a0.value == nil)
        XCTAssertEqual(a0.reason as NSError, ERROR_0)
    }
    
    // MARK: - all
    
    func test_all_fullfill_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms0 = APlusPromise(value: nil)
        let prms2 = APlusPromise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_2)
        }
        
        let promise = APlusPromise.all(prms0, STRING_VALUE_1, prms2)
        promise.then(
            onFulfilled: { (value) -> Any? in
                
                let results = value as [Any?]
                
                XCTAssertTrue((results[0] as Any?) == nil)
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
    
    func test_all_fulfill_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise(value: STRING_VALUE_0)
        let promise = APlusPromise.all(nil, STRING_VALUE_1, prms1)
        
        promise.then(
            onFulfilled: { (value) -> Any? in
                
                let results = value as [Any?]
                XCTAssertTrue((results[0] as Any?) == nil)
                XCTAssertEqual((results[1] as String), STRING_VALUE_1)
                XCTAssertEqual((results[2] as String), STRING_VALUE_0)
                
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        let results = promise.value as [Any?]
        XCTAssertTrue((results[0] as Any?) == nil)
        XCTAssertEqual((results[1] as String), STRING_VALUE_1)
        XCTAssertEqual((results[2] as String), STRING_VALUE_0)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    func test_all_reject_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        var counter = 0
        
        let prms1 = APlusPromise(value: STRING_VALUE_0)
        let prms3 = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_3)
        }
        
        let promise = APlusPromise.all(prms1, STRING_VALUE_1, prms3)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                
                XCTAssertEqual(reason as NSError, ERROR_3)
                XCTAssertTrue(++counter < 2)
                
                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }

    func test_all_reject_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        var counter = 0
        
        let prms1 = APlusPromise(reason: ERROR_1)
        let prms3 = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_3)
        }
        
        let promise = APlusPromise.all(prms1, STRING_VALUE_2, prms3)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertFalse(true)
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertEqual(reason as NSError, ERROR_1)
                
                XCTAssertTrue(++counter < 2)
                
                expectation.fulfill()
                return nil
            }
        )
        
        XCTAssertEqual(promise.reason as NSError, ERROR_1)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    // MARK: - race

    func test_race_fulfill_sync()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise(value: STRING_VALUE_1)
        let prms2 = APlusPromise(reason: ERROR_2)
        let promise = APlusPromise.race(prms1, STRING_VALUE_2, prms2)
        
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual(value as String, STRING_VALUE_1)
                expectation.fulfill()
                return nil
            },
            onRejected: { (reason) -> Any? in
                XCTAssertFalse(true)
                return nil
            }
        )
        
        XCTAssertEqual(promise.value as String, STRING_VALUE_1)

        waitForExpectationsWithTimeout(7) { println($0) }
    }

    func test_race_fulfill_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_1)
        }
        let prms2 = APlusPromise()
        let prms3 = APlusPromise()
        
        let promise = APlusPromise.race(prms1, prms2, prms3)
        promise.then(
            onFulfilled: { (value) -> Any? in
                XCTAssertEqual(value as String, STRING_VALUE_1)
                
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
        
        let prms1 = APlusPromise()
        let prms2 = APlusPromise(reason: ERROR_2)
        let promise = APlusPromise.race(prms1, prms2, STRING_VALUE_3)
        
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
        
        XCTAssertEqual(promise.reason as NSError, ERROR_2)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }

    func test_race_reject_async()
    {
        let expectation = expectationWithDescription(__FUNCTION__)
        
        let prms1 = APlusPromise()
        let prms2 = APlusPromise { (resolve, reject) -> Void in
            0 ~> reject(reason: ERROR_2)
        }
        let prms3 = APlusPromise()
        let promise = APlusPromise.race(prms1, prms2, prms3)
        
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
        
        XCTAssertTrue(promise.reason == nil)
        
        waitForExpectationsWithTimeout(7) { println($0) }
    }
    
    // MARK: - init(promise:)
    
    func test_init_promise() {
        let expt = expectationWithDescription(__FUNCTION__)
        
        let superPromise = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }
        let promise = APlusPromise(promise: superPromise)
        promise.then { (value) -> Any? in
            XCTAssertEqual(value as String, STRING_VALUE_0)
            expt.fulfill()
            return nil
        }
        
        XCTAssertTrue(promise.value == nil)
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
}
