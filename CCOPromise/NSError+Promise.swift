//
//  NSError+Promise.swift
//  CCOPromise
//
//  Created by William Remaerd on 10/8/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public let PromiseErrorDomain = "PromiseErrorDomain"
public let PromiseTypeError = 1000
public let PromiseResultTypeError = 1001


extension NSError {
    
    class func promiseTypeError() -> Self {
        return self(
            domain: PromiseErrorDomain,
            code: PromiseTypeError,
            userInfo: [NSLocalizedDescriptionKey: "TypeError"]
        )
    }
    
    class func promiseResultTypeError() -> Self {
        return self(
            domain: PromiseErrorDomain,
            code: PromiseResultTypeError,
            userInfo: [NSLocalizedDescriptionKey: "ResultTypeError"]
        )
    }
}