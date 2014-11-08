//
//  Deferred.swift
//  IPromise
//
//  Created by William Remaerd on 10/30/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class Deferred<V> {
    
    public let promise: Promise<V>
    
    required
    public convenience init() {
        self.init(promise: Promise<V>())
    }
    
    init(promise: Promise<V>) {
        self.promise = promise
    }
    
    public func resolve(value: V) -> Void
    {
        if promise.state != .Pending {
            return
        }
        
        promise.value = value
        promise.state = .Fulfilled
        
        for callback in promise.fulfillCallbacks {
            callback(value: value)
        }
    }
    
    public func reject(reason: NSError) -> Void
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
    
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(#thenable: T) -> Void
    {
        if promise.state != .Pending {
            return
        }
        
        if (thenable as? Promise<V>) === promise {
            self.reject(NSError.promiseTypeError())
        }
        else {
            thenable.then(
                onFulfilled: { (value: V) -> Void in
                    self.resolve(value)
                },
                onRejected: { (reason: NSError) -> Void in
                    self.reject(reason)
                },
                onProgress: { (progress: Float) -> Float in
                    return progress;
                }
            )
        }
    }
    
    public func progress(progress: Float) -> Void
    {
        if promise.state != .Pending {
            return
        }
        
        for callback in promise.progressCallbacks {
            callback(progress: progress)
        }
    }
}

public extension Deferred {
    
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(#vagueThenable: T) -> Void
    {
        if promise.state != .Pending {
            return
        }
        
        vagueThenable.then(
            onFulfilled: { (value: V) -> Any? in
                self.resolve(value)
                return nil
            },
            onRejected: { (reason: Any?) -> Any? in
                if let reasonObject = reason as? NSError {
                    self.reject(reasonObject)
                }
                else {
                    self.reject(NSError.promiseReasonWrapperError(reason))
                }
                return nil
            },
            onProgress: { (progress: Float) -> Float in
                return progress
            }
        )
    }
}