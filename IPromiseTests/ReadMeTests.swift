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
        
        func answerToEverything() -> Promise<Int> {
            return Promise(value: 42);
        }
        
        answerToEverything()
            .then(
                onFulfilled: { (value: Int) -> Bool in
                    return value == 42
                },
                onRejected: { (reason: NSError) -> Bool in
                    return false
            })
            .then { (value: Bool) -> Promise<String> in
                return value ?
                    Promise(value: "I knew it!") :
                    Promise(reason: NSError())
            }
            .then { (value: String) -> String in
                return value.stringByAppendingString(" Oh yeah!")
            }
            .catch { (reason: NSError) -> Void in
                println("This won't be invoked, coz the answer must be 42")
        }
    }

}
