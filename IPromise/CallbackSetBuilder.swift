//
//  CallbackSetBuilder.swift
//  IPromise
//
//  Created by William Remaerd on 12/7/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

class CallbackSetBuilder<V, N> {
    
    private let promise: Promise<V>
    private let deferred: Deferred<N>
    var progress: Optional<(progress: Float) -> Float> = nil;
    
    required
    init(promise: Promise<V>, deferred: Deferred<N>) {
        self.promise = promise
        self.deferred = deferred
    }
    
    private
    func buildReject(promise: Promise<V>, deferred: Deferred<N>) -> CallbackSet<V>.Reject {
        return { (reason: NSError) -> Void in deferred.reject(reason) }
    }
    
    private
    func buildProgress(promise: Promise<V>, deferred: Deferred<N>) -> CallbackSet<V>.Progress {
        if let onProgress = self.progress? {
            return { (progress) -> Void in
                let nextProgress = onProgress(progress: progress)
                deferred.progress(nextProgress)
            }
        }
        else {
            return { (progress: Float) -> Void in deferred.progress(progress) }
        }
    }
    
    private
    func buildCancel(promise: Promise<V>, deferred: Deferred<N>, callbackSet: CallbackSet<V>) -> CancelEvent.Callback {
        return { [weak promise] () -> Promise<Void>? in
            return promise?.cancelByRemovingCallbackSet(callbackSet)
        }
    }
    
    func build(fulfill: (value: V) -> Void) -> CallbackSet<V> {
        
        let promise = self.promise
        let deferred = self.deferred
        
        let callbackSet: CallbackSet<V> = CallbackSet<V>(
            fulfill,
            buildReject(promise, deferred: deferred),
            buildProgress(promise, deferred: deferred)
        )
        
        deferred.onCanceled(buildCancel(promise, deferred: deferred, callbackSet: callbackSet))
        
        return callbackSet
    }
}

class CallbackSetVoidBuilder<V>: CallbackSetBuilder<V, Void> {
    
    var fulfill: Optional<(value: V) -> Void> = nil;
    var reject: Optional<(reason: NSError) -> Void> = nil;
    
    required
    init(promise: Promise<V>, deferred: Deferred<Void>) {
        super.init(promise: promise, deferred: deferred)
    }
    
    override
    private func buildReject(promise: Promise<V>, deferred: Deferred<Void>) -> CallbackSet<V>.Reject {
        if let onRejected = self.reject? {
            return { (reason: NSError) -> Void in
                onRejected(reason: reason)
                deferred.resolve()
            }
        }
        else {
            return super.buildReject(promise, deferred: deferred)
        }
    }
    
    func build() -> CallbackSet<V> {
        
        let deferred = self.deferred
        
        if let onFulfilled = self.fulfill? {
            return build { (value: V) -> Void in
                onFulfilled(value: value)
                deferred.resolve()
            }
        }
        else {
            return build { (value: V) -> Void in deferred.resolve() }
        }
    }
}

class CallbackSetValueBuilder<V, N>: CallbackSetBuilder<V, N> {
    
    var reject: Optional<(reason: NSError) -> N> = nil;
    
    required
    init(promise: Promise<V>, deferred: Deferred<N>) {
        super.init(promise: promise, deferred: deferred)
    }
    
    override
    private func buildReject(promise: Promise<V>, deferred: Deferred<N>) -> CallbackSet<V>.Reject {
        if let onRejected = self.reject? {
            return { (reason: NSError) -> Void in
                let nextValue = onRejected(reason: reason)
                deferred.resolve(nextValue)
            }
        }
        else {
            return super.buildReject(promise, deferred: deferred)
        }
    }
}

class CallbackSetThenableBuilder<V, N, T: Thenable where T.ValueType == N, T.ReasonType == NSError, T.ReturnType == Void>: CallbackSetBuilder<V, N> {
    
    var reject: Optional<(reason: NSError) -> T> = nil
    var fraction: Float = 0.0
    
    required
    init(promise: Promise<V>, deferred: Deferred<N>) {
        super.init(promise: promise, deferred: deferred)
    }
    
    private override
    func buildReject(promise: Promise<V>, deferred: Deferred<N>) -> CallbackSet<V>.Reject {
        if let onRejected = self.reject? {
            let fraction = self.fraction
            return { (reason: NSError) -> Void in
                let nextThenable = onRejected(reason: reason)
                deferred.resolve(thenable: nextThenable, fraction: fraction)
            }
        }
        else {
            return super.buildReject(promise, deferred: deferred)
        }
    }
    
    private override
    func buildCancel(promise: Promise<V>, deferred: Deferred<N>, callbackSet: CallbackSet<V>) -> CancelEvent.Callback {
        return { [weak promise, unowned deferred] () -> Promise<Void>? in
            deferred.cancelResolvingPromise()
            return promise?.cancelByRemovingCallbackSet(callbackSet)
        }
    }
    
    override
    func build(fulfill: (value: V) -> Void) -> CallbackSet<V> {
        if let onProgress = self.progress {
            self.fraction = 1.0 - onProgress(progress: 1.0)
        }
        return super.build(fulfill)
    }
}

class CallbackSetProgressBuilder<V>: CallbackSetBuilder<V, V>  {
    required
    init(promise: Promise<V>, deferred: Deferred<V>) {
        super.init(promise: promise, deferred: deferred)
    }
    
    func build() -> CallbackSet<V> {
        
        let deferred = self.deferred
        
        return build({ (value) -> Void in
            deferred.resolve(value)
        })
    }
}