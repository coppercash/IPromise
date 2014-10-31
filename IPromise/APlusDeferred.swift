//
//  APlusDeferred.swift
//  IPromise
//
//  Created by William Remaerd on 10/31/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class APlusDeferred {
    
    public let promise: APlusPromise
    
    required
    public convenience init() {
        self.init(promise: APlusPromise())
    }
    
    init(promise: APlusPromise) {
        self.promise = promise
    }
    
    public func resolve(value: Any?) -> Void
    {
        if promise.state != .Pending {
            return
        }
        
        if let aplusPromise = value as? APlusPromise {
            if aplusPromise === promise {
                self.reject(NSError.promiseTypeError())
            }
            else {
                aplusPromise.then(
                    onFulfilled: { (value) -> Any? in
                        self.resolve(value)
                        return nil
                    },
                    onRejected: { (reason) -> Any? in
                        self.reject(reason)
                        return nil
                    }
                )
            }
            return
        }
        
        promise.value = value
        promise.state = .Fulfilled
        
        for callback in promise.fulfillCallbacks {
            callback(value: value)
        }
    }
    
    public func reject(reason: Any?) -> Void
    {
        if promise.state != .Pending {
            return
        }
        
        promise.reason = reason
        promise.state = .Rejected
        
        for callback in promise.rejectCallbacks {
            callback(reason: reason)
        }
    }
}

public extension APlusDeferred {
    
    func resolve<V>(#promise: Promise<V>) -> Void
    {
        if self.promise.state != .Pending {
            return
        }
        
        promise.then(
            onFulfilled: { (value) -> Void in
                self.resolve(value)
            },
            onRejected: { (reason) -> Void in
                self.reject(reason)
            }
        )
    }
}