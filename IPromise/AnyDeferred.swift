//
//  AnyDeferred.swift
//  IPromise
//
//  Created by William Remaerd on 10/31/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class AnyDeferred {
    
    public let promise: AnyPromise
    
    required
    public convenience init() {
        self.init(promise: AnyPromise())
    }
    
    init(promise: AnyPromise) {
        self.promise = promise
    }
    
    public func resolve(value: Any?) -> Void
    {
        if let anyPromise = value as? AnyPromise {
            resolve(thenable: anyPromise, fraction: 1.0)
            return
        }
        
        objc_sync_enter(promise)
        let fulfilled = promise.state.fulfill()
        objc_sync_exit(promise)
        if !fulfilled { return }
        
        promise.value = value
        
        for callback in promise.fulfillCallbacks {
            callback(value: value)
        }
    }
    
    public func reject(reason: Any?) -> Void
    {
        objc_sync_enter(promise)
        let rejected = promise.state.reject()
        objc_sync_exit(promise)
        if !rejected { return }
        
        promise.reason = reason
        for callback in promise.rejectCallbacks {
            callback(reason: reason)
        }
    }
    
    public func resolve<T: Thenable where T.ValueType == Optional<Any>, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(
        #thenable: T,
        fraction: Float
        )
    {
        if (thenable as? AnyPromise) === promise {
            self.reject(NSError.promiseTypeError())
        }
        else {
            thenable.then(
                onFulfilled: { (value) -> Any? in
                    self.resolve(value)
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    self.reject(reason)
                    return nil
                },
                onProgress: { (progress) -> Float in
                    self.progress((1 - fraction) + progress * fraction)
                    return progress
                }
            )
        }
    }
    
    public func progress(progress: Float) -> Void
    {
        objc_sync_enter(promise)
        
        if promise.state == .Pending && (0.0 <= progress && progress <= 1.0) {
            for callback in promise.progressCallbacks {
                callback(progress: progress)
            }
        }
        
        objc_sync_exit(promise)
    }
}