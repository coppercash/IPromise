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
            userInfo: [NSLocalizedDescriptionKey: "TypeError",]
        )
    }
    
    class func promiseReasonWrapperError(reason: Any?) -> Self {
        var reasonValue: AnyObject? = nil
        if let validReason = reason? {
            if let reasonObject = validReason as? NSObject {
                reasonValue = reasonObject
            }
            else {
                reasonValue = "\(validReason)"
            }
        }
        else {
            reasonValue = NSNull()
        }
        
        return self(
            domain: PromiseErrorDomain,
            code: PromiseResultTypeError,
            userInfo: [NSLocalizedDescriptionKey: "ReasonWrapperError", ("reason" as NSString): reasonValue!,]
        )
    }
}