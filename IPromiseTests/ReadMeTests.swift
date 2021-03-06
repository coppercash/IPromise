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
        
        let promise: Promise<Int> = answerToEverthing()
        
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
            Promise.all(promises) :
            Promise.all(promiseA, promiseB, promiseC)
        
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
    
    func test_thenable() {
        
        class ThenableObject: Thenable {
            
            typealias ValueType = NSData
            typealias ReasonType = NSError
            typealias ReturnType = Void
            typealias NextType = Void
            
            func then(
                #onFulfilled: Optional<(value: NSData) -> Void>,
                onRejected: Optional<(reason: NSError) -> Void>,
                onProgress: Optional<(progress: Float) -> Float>
                ) -> Void {
                    // Implement
            }
        }
        
        let thenableObject = ThenableObject()
        let promise = Promise(thenable: thenableObject)
    }
    
    func test_deferred() {
        
        func someAwsomeData() -> Promise<NSString> {
            let deferred = Deferred<NSString>()
            
            NSURLConnection.sendAsynchronousRequest(
                NSURLRequest(URL: NSURL(string: "http://so.me/awsome/api")!),
                queue: NSOperationQueue.mainQueue())
                { (response, data, error) -> Void in
                    if error == nil {
                        deferred.resolve(NSString(data: data, encoding: NSUTF8StringEncoding)!)
                    }
                    else {
                        deferred.reject(error)
                    }
            }
            
            return deferred.promise
        }
        
        let (deferred, promise) = Promise<String>.defer()
    }
    
    func test_progress() {
        let (deferred, promise) = Promise<Void>.defer()
        let (anotherDeferred, anotherPromise) = Promise<Void>.defer()
        
        promise.then(
            onFulfilled: nil,
            onRejected: nil,
            onProgress: { (progress) -> Float in
                println("The return value '\(progress)' is used to propagate, if it is between 0.0...1.0")
                return progress
        })
        
        promise.progress { (progress) -> Void in
            println("The return value '\(progress)' can also be omitted")
        }
        
        promise.then(
            onFulfilled: { () -> Promise<Void> in
                let (anotherDeferred, anotherPromise) = Promise<Void>.defer()
                return anotherPromise
            },
            onProgress: { (progress) -> Float in
                println("The value '\(0.5)' indicates the progress of `promise` and `anotherPromise` take same weight")
                return progress * 0.5
        })
    }
    
    func test_finally() {
        let (deferred, promise) = Promise<Void>.defer()
        
        promise
            .then(
                onFulfilled: { (value) -> Void in
                    println("Fulfill")
                },
                onRejected: { (reason) -> Void in
                    println("Reject")
                }
            )
            .then { (value) -> Void in
                println("Finally...")
        }
        
        deferred.reject(NSError())
    }
    
    func test_cancel() {
        let (deferred, promise) = Promise<String>.defer()
        
        deferred.onCanceled { () -> Promise<Void> in
            println("Do the cancel work and return a promise to notify when the work is finished")
            return Promise<Void>(value: ())
        }
        
        promise.cancel()
            .then(
                onFulfilled: { (value) -> Void in
                    println("Succeed to cancel")
                },
                onRejected: { (reason) -> Void in
                    println("Fail to cancel")
                }
        )
    }
}
