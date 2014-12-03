//
//  CallbackSet.swift
//  IPromise
//
//  Created by William Remaerd on 11/20/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

struct CallbackSet<V>: Equatable {
    let identifier: String = NSProcessInfo.processInfo().globallyUniqueString
    
    let fulfillCallback: (value: V) -> Void
    let rejectCallback: (reason: NSError) -> Void
    let progressCallback: (progress: Float) -> Void
    
    init(
        fulfillCallback: (value: V) -> Void,
        rejectCallback: (reason: NSError) -> Void,
        progressCallback: (progress: Float) -> Void)
    {
        self.fulfillCallback = fulfillCallback
        self.rejectCallback = rejectCallback
        self.progressCallback = progressCallback
    }
    
    static func builder(promise: Promise<V>) -> CallbackSetBuilder<V> {
        return CallbackSetBuilder<V>(promise: promise)
    }
}

func ==<V, R>(lhs: CallbackSet<V>, rhs: CallbackSet<V>) -> Bool {
    return lhs.identifier == rhs.identifier
}

class CallbackSetBuilder<V> {
    
    private let promise: Promise<V>
    private var onRejected: Optional<(reason: NSError) -> Void>
    private var onProgress: Optional<(progress: Float) -> Void>
    private var onCanceled: Optional<() -> Promise<Void>>
    
    init(promise: Promise<V>) {
        self.promise = promise
    }
    
    func onRejected(closure: (reason: NSError) -> Void) -> CallbackSetBuilder<V> {
        self.onRejected = closure
        return self
    }
    
    func onProgress(closure: (progress: Float) -> Void) -> CallbackSetBuilder<V> {
        self.onProgress = closure
        return self
    }

    func onCanceled(closure: () -> Promise<Void>) -> CallbackSetBuilder<V> {
        self.onCanceled = closure
        return self
    }

    func build<N>(nextDeferred: Deferred<N>, onFulfilled: (value: V) -> Void) -> CallbackSet<V> {
        
        let rejectCallback: (reason: NSError) -> Void = (self.onRejected != nil) ?
            self.onRejected! :
            { (reason: NSError) -> Void in nextDeferred.reject(reason) }
        
        let progressCallback: (progress: Float) -> Void = (self.onProgress != nil) ?
            self.onProgress! :
            { (progress: Float) -> Void in nextDeferred.progress(progress) };
        
        let callbackSet: CallbackSet<V> = CallbackSet<V>(onFulfilled, rejectCallback, progressCallback)
        
        let promise = self.promise
        
        let onCanceled: () -> Promise<Void> = (self.onCanceled != nil) ?
            self.onCanceled! :
            { [unowned promise, callbackSet] () -> Promise<Void> in
                promise.cancelByRemovingCallbackSet(callbackSet)
        }
        
        nextDeferred.onCanceled(onCanceled)
        
        promise.bindCallbackSet(callbackSet)
        
        return callbackSet
    }
}