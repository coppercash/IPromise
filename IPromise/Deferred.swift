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
    
    private var cancelEvent: Optional<CancelEvent> = nil
    private var resolvingPromise: Optional<Promise<V>> = nil
    
    public required convenience
    init() {
        self.init(promise: Promise<V>())
    }
    
    init(promise: Promise<V>) {
        self.promise = promise
        promise.deferred = self
    }
    
    public
    func resolve(value: V) -> Void {
        self.promise.resolve(value)
        self.clean(State.Fulfilled)
    }
    
    public
    func reject(reason: NSError) -> Void {
        self.promise.reject(reason)
        self.clean(State.Rejected)
    }
    
    public
    func progress(progress: Float) -> Void {
        self.promise.progress(progress)
    }
    
    private
    func clean(toState: State) {
        self.cancelEvent = nil
        self.resolvingPromise = nil
        self.promise.deferred = nil
    }
}

public extension Deferred {
    
    public
    func onCanceled(cancelation: () -> Void) -> Bool {
        return onCanceled { () -> Promise<Void> in
            cancelation()
            return Promise<Void>(value: ())
        }
    }
    
    public
    func onCanceled(cancelation: () -> Promise<Void>) -> Bool {
        if self.cancelEvent != nil {
            return false
        }
        else {
            let cancelEvent: CancelEvent = CancelEvent(callback: cancelation)
            self.cancelEvent = cancelEvent
            if self.promise.isCanceled() {
                cancelEvent.invoke()
            }
            return true
        }
    }
    
    public
    func cancelResolvingPromise() -> Promise<Void> {
        if let promise = self.resolvingPromise? {
            return promise.cancel()
        }
        else {
            return Promise<Void>(value: ())
        }
    }

    internal
    func cancel() -> Promise<Void> {
        if let cancelEvent = self.cancelEvent {
            let cancelPromise = cancelEvent.invoke()
            cancelPromise.then { (value) -> Void in
                self.reject(NSError.promiseCancelError())
            }
            return cancelPromise
        }
        else {
            reject(NSError.promiseCancelError())
            return Promise<Void>(value: ())
        }
    }
}

extension Deferred {
    
    internal
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>
        (#thenable: T, fraction: Float) -> Void
    {
        if (thenable as? Promise<V>) === promise {
            self.reject(NSError.promiseTypeError())
            return
        }
        
        if let promise = thenable as? Promise<V> {
            self.resolvingPromise = promise
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
