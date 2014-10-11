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

let STRING_VALUE_0 = "StringValue0"

let ERROR_0 = NSError.errorWithDomain(" ", code: 0, userInfo: nil)

class PromiseTests: XCTestCase
{
    // MARK: - 2.1.1
    func test_state_pendingToFulfill(){
        let expt = expectationWithDescription(__FUNCTION__)

        let toFulfill = Promise { (resolve, reject) -> Void in
            0 ~> resolve(value: STRING_VALUE_0)
        }.then { (value) -> Void in
            expt.fulfill()
        }
        
        XCTAssertEqual(toFulfill.state, PromiseState.Pending)
        
        waitForExpectationsWithTimeout(7, handler: { (error) -> Void in
            XCTAssertEqual(toFulfill.state, PromiseState.Fulfilled)
        })
    }
    
    
    
    // MARK: - 2.1.2
    
    // MARK: - 2.1.4
}
