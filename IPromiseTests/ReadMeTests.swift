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
            }.then { (value: Bool) -> Promise<String> in
                return value ?
                    Promise(value: "I knew it!") :
                    Promise(reason: NSError())
            }.then { (value: String) -> Void in
                println(value.stringByAppendingString(" Oh yeah!"))
            }
    }

    func test_TypeFree() {
        
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
        );
        
        let fromTypeFree: Promise<Any?> = Promise(vagueThenable: typeFreePromise)
        let fromTypeSafe: APlusPromise = APlusPromise(promise: fromTypeFree)
    }
    
    func test_aggregate() {
        
    }
    
    func test_chain() {
        
    }
    
}
