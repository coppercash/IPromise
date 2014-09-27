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

class FuturePromise<V>: FutureAPlusPromise
{
    required init(resovler: (resolve: Resovler, reject: Rejector, futureAction: FutureAction) -> Void) {
        super.init(resovler: resovler)
    }
    
    @availability(*, deprecated=2.0.0)
    required init(resovler: (resolve: Resovler, reject: Rejector) -> Void) {
        super.init(resovler: resovler)
    }
}

class PromiseTests: XCTestCase
{
    func test_expansibility()
    {
        let promise = Promise<Any> { (resolve, reject) -> Void in
            
        }
        
        let futurePromise = FuturePromise<Any> { (resolve, reject) -> Void in
            
        }
    }
    
    func test_generic()
    {

    }
}
