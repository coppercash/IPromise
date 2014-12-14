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
public let PromiseCancelError = 1003
public let PromiseNoSuchEventError = 1004
public let PromiseWrongStateError = 1005
public let PromiseCancelForkedPromiseError = 1006

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
    
    class func promiseNoSuchEventError(#name: String) -> Self {
        return self(
            domain: PromiseErrorDomain,
            code: PromiseNoSuchEventError,
            userInfo: [NSLocalizedDescriptionKey: "No such event named '\(name)'.",]
        )
    }
    
    class func promiseWrongStateError(#state: State) -> Self {
        return self(
            domain: PromiseErrorDomain,
            code: PromiseWrongStateError,
            userInfo: [NSLocalizedDescriptionKey: "Promise has been already '\(state)'",]
        )
    }
    
    class func promiseCancelForkedPromiseError() -> Self {
        return self(
            domain: PromiseErrorDomain,
            code: PromiseCancelForkedPromiseError,
            userInfo: [NSLocalizedDescriptionKey: "A forked promise can not be canceled",]
        )
    }
}