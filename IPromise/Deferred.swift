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
        objc_sync_enter(promise)
        let fulfilled = promise.state.fulfill()
        objc_sync_exit(promise)
        if !fulfilled { return }
        
        promise.value = value
        for callback in promise.fulfillCallbacks {
            callback(value: value)
        }
    }
    
    public func reject(reason: NSError) -> Void
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
    
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(
        #thenable: T,
        fraction: Float
        ) -> Void
    {
        if (thenable as? Promise<V>) === promise {
            self.reject(NSError.promiseTypeError())
            return
        }

        thenable.then(
            onFulfilled: { (value: V) -> Void in
                self.resolve(value)
            },
            onRejected: { (reason: NSError) -> Void in
                self.reject(reason)
            },
            onProgress: { (progress: Float) -> Float in
                self.progress((1 - fraction) + progress * fraction)
                return progress
            }
        )
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