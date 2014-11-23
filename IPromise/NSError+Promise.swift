//
//  NSError+Promise.swift
//  IPromise
//
//  Created by William Remaerd on 10/8/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public let PromiseErrorDomain = "PromiseErrorDomain"
public let PromiseTypeError = 1000
public let PromiseReasonWrapperError = 1001
public let PromiseValueTypeError = 1002
public let PromiseCancelError = 1002

public let PromiseErrorReasonKey = "reason"

extension NSError {
    
    class func promiseTypeError() -> Self {
        return self(
            domain: PromiseErrorDomain,
            code: PromiseTypeError,
            userInfo: [NSLocalizedDescriptionKey: "TypeError",]
        )
    }
    
    class func promiseValueTypeError(#expectType: Any, value: Any) -> Self {
        return self(
            domain: PromiseErrorDomain,
            code: PromiseValueTypeError,
            userInfo: [NSLocalizedDescriptionKey: "Expect value of \(expectType) or Promise<\(expectType)>, but found \(reflect(value).summary)",]
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
            code: PromiseReasonWrapperError,
            userInfo: [NSLocalizedDescriptionKey: PromiseErrorReasonKey, ("reason" as NSString): reasonValue!,]
        )
    }

    class func promiseCancelError() -> Self {
        return self(
            domain: PromiseErrorDomain,
            code: PromiseCancelError,
            userInfo: [NSLocalizedDescriptionKey: "CancelError",]
        )
    }
    
    public func isCanceled() -> Bool {
        return self.domain == PromiseErrorDomain && self.code == PromiseCancelError
    }
}