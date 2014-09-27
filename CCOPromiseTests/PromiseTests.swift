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
    required init(resovler: (
        resolve: APlusPromise.APlusResovler,
        reject: APlusPromise.APlusRejector
        ) -> Void)
    {
        
    }
    
    required init(resovler: (
        resolve: APlusPromise.APlusResovler,
        reject: APlusPromise.APlusRejector,
        futureAction: FutureAction
        ) -> Void)
    {
        
    }
}

class FuturePromise<V>: FutureAPlusPromise
{
    required init(resovler: (
        resolve: APlusPromise.APlusResovler,
        reject: APlusPromise.APlusRejector,
        futureAction: FutureAction
        ) -> Void) {
        super.init(resovler: resovler)
    }
    
    @availability(*, deprecated=2.0.0)
    required init(resovler: (
        resolve: APlusPromise.APlusResovler,
        reject: APlusPromise.APlusRejector
        ) -> Void) {
        super.init(resovler: resovler)
    }
}

class PromiseTests: XCTestCase
{
    func test_expansibility()
    {
        let promise: Promise<String> = Promise { (resolve, reject) -> Void in

        }
        
        let futurePromise: FuturePromise<String> = FuturePromise { (resolve, reject) -> Void in
            
        }
    }
    
    func test_generic()
    {
        let actionPromise = Promise<String> { (resolve, reject) -> Void in
            resolve(value: 3)
        }
        
        actionPromise.then { (value: String) -> Any? in
            
            return nil
        }

    }
}
