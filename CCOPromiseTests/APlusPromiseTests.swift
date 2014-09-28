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
    func test_init()
    {
        let pendingPrms = APlusPromise()
        pendingPrms.state
        XCTAssertNotNil(pendingPrms, " ")
        
        let fulfulledPrms = APlusPromise(value: "A value")
        XCTAssertNotNil(fulfulledPrms, " ")
        
        let rejectedPrms = APlusPromise(reason: NSError())
        XCTAssertNotNil(rejectedPrms, " ")
    }
}
