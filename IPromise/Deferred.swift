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
    
    var cancelEvent: Optional<CancelEvent> = nil;
    
    required
    public convenience init() {
        self.init(promise: Promise<V>())
    }
    
    init(promise: Promise<V>) {
        self.promise = promise
        promise.deferred = self
    }
    
    public func resolve(value: V) -> Void {
        self.promise.resolve(value)
    }
    
    public func reject(reason: NSError) -> Void {
        self.promise.reject(reason)
    }
    
    public func progress(progress: Float) -> Void {
        self.promise.progress(progress)
    }
}

public extension Deferred {
    
    public func onCanceled(cancelation: () -> Void) -> Bool {
        return onCanceled { () -> Promise<Void> in
            cancelation()
            return Promise<Void>(value: ())
        }
    }
    
    public func onCanceled(cancelation: () -> Promise<Void>) -> Bool {
        if self.cancelEvent != nil {
            return false
        }
        else {
            let cancelEvent: CancelEvent = CancelEvent(callback: cancelation)
            self.cancelEvent = cancelEvent
            if let reason = self.promise.reason? {
                if reason.isCanceled() {
                    cancelEvent.invoke()
                }
            }
            return true
        }
    }
    
    internal func cancel(#invoke: Bool) -> Promise<Void> {
        if let cancelEvent = self.cancelEvent {
            if invoke {
                cancelEvent.invoke()
            }
            return cancelEvent.buffer.promise
        }
        else {
            return Promise<Void>(reason: NSError()) // TODO
        }
    }
}

extension Deferred {
    
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>
        (#thenable: T, fraction: Float) -> Void
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
                return -1
            }
        )
    }
}
