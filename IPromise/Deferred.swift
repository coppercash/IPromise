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
    
    var cancelation: Optional<() -> Promise<Void>> = nil
    var cancelPromise: Optional<Promise<Void>> = nil
    
    /*
    let identifier: String = NSProcessInfo.processInfo().globallyUniqueString
    private lazy var callbackSets: [String: CallbackSet<V, NSError>] = [:]
    */
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
    
    public func onCanceled(cancelation: () -> Void) {
        onCanceled { () -> Promise<Void> in
            cancelation()
            return Promise<Void>(value: ())
        }
    }
    
    public func onCanceled(cancelation: () -> Promise<Void>) {
        self.cancelation = cancelation
    }
    
    func cancel(cached: Bool) -> Promise<Void> {
        
    }
    
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
/*
extension Deferred {
    func bindCallbackSet<D>(deferred: Deferred<D>, callbackSet: CallbackSet<V, NSError>) {
        objc_sync_enter(self)

        self.callbackSets[deferred.identifier] = callbackSet
        
        let promise = self.promise
        switch promise.state {
        case .Fulfilled:
            callbackSet.fulfillCallback(value: promise.value!)
        case .Rejected:
            callbackSet.rejectCallback(reason: promise.reason!)
        default:
            break
        }
        
        objc_sync_exit(self)
    }
}
*/
/*
extension Deferred: Hashable, Equatable {
    public var hashValue: Int {
        return identifier.hashValue
    }
}

public func ==<V>(lhs: Deferred<V>, rhs: Deferred<V>) -> Bool {
    return lhs.identifier == rhs.identifier
}
*/