//
//  APlusPromise.swift
//  IPromise
//
//  Created by William Remaerd on 9/25/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class APlusPromise: Thenable
{
    // MAKR: ivars
    
    public internal(set) var state: PromiseState = .Pending
    public internal(set) var value: Any?? = nil
    public internal(set) var reason: Any?? = nil

    public typealias FulfillClosure = (value: Any?) -> Void
    public typealias RejectClosure = (reason: Any?) -> Void
    lazy var fulfillCallbacks: [FulfillClosure] = []
    lazy var rejectCallbacks: [RejectClosure] = []

    // MARK: - Initializers
    
    init() {}
    
    required
    public init(value: Any?)
    {
        self.value = value
        self.state = .Fulfilled
    }
    
    required
    public init(reason: Any?)
    {
        self.reason = reason
        self.state = .Rejected
    }

    convenience
    public init(resolver: (resolve: FulfillClosure, reject: RejectClosure) -> Void)
    {
        self.init()
        let deferred = APlusDeferred(promise: self)
        resolver(
            resolve: deferred.resolve,
            reject: deferred.reject
        )
    }
    
    convenience
    public init<T: Thenable where T.ValueType == Optional<Any>, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(thenable: T)
    {
        self.init()
        let deferred = APlusDeferred(promise: self)
        thenable.then(
            onFulfilled: { (value) -> Any? in
                deferred.resolve(value)
                return nil
            },
            onRejected: { (reason) -> Any? in
                deferred.reject(reason)
                return nil
            },
            onProgress: { (progress) -> Float in
                return progress
            }
        )
    }
    
    // MARK: - Private APIs
    
    func bindCallbacks(#fulfillCallback: FulfillClosure, rejectCallback: RejectClosure)
    {
        self.fulfillCallbacks.append(fulfillCallback)
        self.rejectCallbacks.append(rejectCallback)
        
        switch self.state {
        case .Fulfilled:
            fulfillCallback(value: self.value!)
        case .Rejected:
            rejectCallback(reason: self.reason!)
        default:
            break
        }
    }

    // MARK: - Static APIs
    
    public class func defer() -> (APlusDeferred, APlusPromise)
    {
        let deferred = APlusDeferred();
        return (deferred, deferred.promise)
    }
    
    public class func resolve(value: Any?) -> APlusPromise
    {
        // TODO: - Downcast to Thenable
        
        switch value {
        case let aPlusPromise as APlusPromise:
            return aPlusPromise
        default:
            return self(value: value)
        }
    }
    
    public class func reject(reason: Any?) -> APlusPromise
    {
        return self(reason: reason)
    }
    
    // MARK: - Thenable
    
    typealias NextType = APlusPromise
    typealias ValueType = Any?
    typealias ReasonType = Any?
    typealias ReturnType = Any?

    public func then(
        onFulfilled: Optional<(value: Any?) -> Any?> = nil,
        onRejected: Optional<(reason: Any?) -> Any?> = nil,
        onProgress: Optional<(progress: Float) -> Float> = nil
        ) -> APlusPromise
    {
        let (nextDeferred, nextPromise) = APlusPromise.defer()
        
        let fulfillCallback: FulfillClosure = (onFulfilled != nil) ?
            { (value: Any?) -> Void in
                let nextValue: Any? = onFulfilled!(value: value)
                nextDeferred.resolve(nextValue)
            } :
            { (value: Any?) -> Void in nextDeferred.resolve(value) }
        
        let rejectCallback: RejectClosure = (onRejected != nil) ?
            { (reason: Any?) -> Void in
                let nextReason: Any? = onRejected!(reason: reason)
                nextDeferred.resolve(nextReason)
            } :
            { (reason: Any?) -> Void in nextDeferred.reject(reason) }
        
        self.bindCallbacks(fulfillCallback, rejectCallback)
        
        return nextPromise
    }

    public func catch(onRejected: (reason: Any?) -> Any?) -> APlusPromise
    {
        let (nextDeferred, nextPromise) = APlusPromise.defer()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                nextDeferred.resolve(value)
            },
            rejectCallback: { (reason) -> Void in
                nextDeferred.resolve(onRejected(reason: reason))
            }
        )
        
        return nextPromise
    }
}

public extension APlusPromise {
    
    public class func all(values: [Any?]) -> APlusPromise
    {
        let (allDeferred, allPromise) = APlusPromise.defer()
        let count = values.count
        var results: [Any?] = []
        
        for value in values
        {
            let promise = self.resolve(value)
            promise.then(
                onFulfilled: { (value) -> Any? in
                    results.append(value)
                    if results.count >= count {
                        allDeferred.resolve(results)
                    }
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    allDeferred.reject(reason)
                    return nil
                }
            )
        }
        
        return allPromise
    }
    
    public class func all(values: Any?...) -> APlusPromise
    {
        return self.all(values)
    }
    
    public class func race(values: [Any?]) -> APlusPromise
    {
        let (raceDeferred, racePromise) = APlusPromise.defer()
        
        for value in values
        {
            let promise = self.resolve(value)
            promise.then(
                onFulfilled: { (value) -> Any? in
                    raceDeferred.resolve(value)
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    raceDeferred.reject(reason)
                    return nil
                }
            )
        }
        
        return racePromise
    }
    
    public class func race(values: Any?...) -> APlusPromise
    {
        return self.race(values)
    }
}

public extension APlusPromise {
    convenience
    public init<V>(promise: Promise<V>)
    {
        self.init()
        let deferred = APlusDeferred(promise: self)
        deferred.resolve(promise: promise)
    }
}