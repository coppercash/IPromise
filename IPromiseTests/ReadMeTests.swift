//
//  ReadMeTests.swift
//  IPromise
//
//  Created by William Remaerd on 10/17/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import UIKit
import XCTest
import IPromise

class ReadMeTests: XCTestCase {

    func test_typeSafe() {

        func answerToEverthing() -> Promise<Int> {
            return Promise(value: 42)
        }
        
        let promise: Promise<Int> = answerToEverthing();
        
        promise
            .then { (value: Int) -> Bool in
                return value == 42
            }
            .then { (value: Bool) -> Promise<String> in
                return value ?
                    Promise(value: "I knew it!") :
                    Promise(reason: NSError())
            }
            .then { (value: String) -> Void in
                println(value.stringByAppendingString(" Oh yeah!"))
        }
    }

    func test_typeFree() {
        
        func answerToUniverse() -> APlusPromise {
            return APlusPromise(value: 42);
        }
        
        let typeFreePromise: APlusPromise = answerToUniverse()
        
        typeFreePromise.then(
            onFulfilled: { (value: Any?) -> Any? in
                let isItStill42 = (value as Int) == 42
                return nil;
            },
            onRejected: { (reason: Any?) -> Any? in
                return nil;
            }
        )
        
        let fromTypeFree: Promise<Any?> = Promise(vagueThenable: typeFreePromise)
        let fromTypeSafe: APlusPromise = APlusPromise(promise: fromTypeFree)
    }
    
    func test_aggregate() {
        
        let promiseA = Promise(value: 1)
        let promiseB = Promise(value: 1)
        let promiseC = Promise(value: 1)
        let arrayOrVariadic = promiseA === promiseB
        
        let promises: [Promise<Int>] = [
            promiseA,
            promiseB,
            promiseC,
        ]
        
        let promise = arrayOrVariadic ?
            Promise<[Int]>.all(promises) :
            Promise<[Int]>.all(promiseA, promiseB, promiseC);
        
        promise.then { (value) -> Void in
            for number: Int in value {
                println(number)
            }
        }
    }
    
    func test_chain() {
        
        Promise { (resolve, reject) -> Void in
            resolve(value: "Something complex")
            }
            .then(
                onFulfilled: { (value: String) -> Void in
                    return
                },
                onRejected: { (reason: NSError) -> Void in
                    return
            })
            .then(
                onFulfilled: { (value: Void) -> Int in
                    return 1
                },
                onRejected: { (reason: NSError) -> Int in
                    return 0
            })
            .then { (value) -> Promise<String> in
                let error = NSError(domain: "BadError", code: 1000, userInfo: nil)
                return Promise<String>(reason: error)
            }
            .catch { (reason) -> Void in
                println(reason)
        }
    }
}