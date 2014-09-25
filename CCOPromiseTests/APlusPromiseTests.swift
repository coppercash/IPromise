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

typealias FutureAction = (Float) -> Void

class FutureAPlusPromise
{
    @availability(*, deprecated=2.0)
    required init(resovler: (resolve: Resovler, reject: Rejector) -> Void)
    {
        
    }
    
    required init(resovler: (resolve: Resovler, reject: Rejector, futureAction: FutureAction) -> Void)
    {
        
    }
}

class FuturePromise: FutureAPlusPromise
{
    
}

class APlusPromiseTests: XCTestCase
{
    func test_expansibility()
    {
        let aPromise = Promise { (resolve, reject) -> Void in
            
        };
        
        let aFuturePromise = FuturePromise { (resolve, reject) -> Void in
            
        };
    }
}
