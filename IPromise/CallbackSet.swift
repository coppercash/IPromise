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
    
    let fulfill: (value: V) -> Void
    let reject: (reason: NSError) -> Void
    let progress: (progress: Float) -> Void
    
    init(
        fulfill: (value: V) -> Void,
        reject: (reason: NSError) -> Void,
        progress: (progress: Float) -> Void)
    {
        self.fulfill = fulfill
        self.reject = reject
        self.progress = progress
    }
    
    static func builder(promise: Promise<V>) -> CallbackSetBuilder<V> {
        return CallbackSetBuilder<V>(promise: promise)
    }
}

func ==<V>(lhs: CallbackSet<V>, rhs: CallbackSet<V>) -> Bool {
    return lhs.identifier == rhs.identifier
}

class CallbackSetBuilder<V> {
    
    private let promise: Promise<V>
    private var reject: Optional<(reason: NSError) -> Void>
    private var progress: Optional<(progress: Float) -> Void>
    private var cancel: Optional<() -> Promise<Void>>
    
    init(promise: Promise<V>) {
        self.promise = promise
    }
    
    func reject(callback: (reason: NSError) -> Void) -> CallbackSetBuilder<V> {
        self.reject = callback
        return self
    }

    func progress(callback: (progress: Float) -> Void) -> CallbackSetBuilder<V> {
        self.progress = callback
        return self
    }

    func cancel(callback: () -> Promise<Void>) -> CallbackSetBuilder<V> {
        self.cancel = callback
        return self
    }

    func build<N>(nextDeferred: Deferred<N>, fulfill: (value: V) -> Void) -> CallbackSet<V> {
        
        let reject: (reason: NSError) -> Void = (self.reject != nil) ?
            self.reject! :
            { (reason: NSError) -> Void in nextDeferred.reject(reason) }
        
        let progress: (progress: Float) -> Void = (self.progress != nil) ?
            self.progress! :
            { (progress: Float) -> Void in nextDeferred.progress(progress) }
        
        let callbackSet: CallbackSet<V> = CallbackSet<V>(fulfill, reject, progress)
        
        let promise = self.promise
        
        let cancel: () -> Promise<Void> = (self.cancel != nil) ?
            self.cancel! :
            { [unowned promise, callbackSet] () -> Promise<Void> in
                promise.cancelByRemovingCallbackSet(callbackSet)
        }
        
        nextDeferred.onCanceled(cancel)
        
        promise.bindCallbackSet(callbackSet)
        
        return callbackSet
    }
    
    func build(nextDeferred: Deferred<V>) -> CallbackSet<V> {
        return build(nextDeferred, fulfill: { (value) -> Void in
            nextDeferred.resolve(value)
        })
    }
}