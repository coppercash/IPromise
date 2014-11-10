//
//  AnyPromise.swift
//  IPromise
//
//  Created by William Remaerd on 9/25/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class AnyPromise: Thenable
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
        let deferred = AnyDeferred(promise: self)
        resolver(
            resolve: deferred.resolve,
            reject: deferred.reject
        )
    }
    
    convenience
    public init<T: Thenable where T.ValueType == Optional<Any>, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(thenable: T)
    {
        self.init()
        let deferred = AnyDeferred(promise: self)
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
    
    public class func defer() -> (AnyDeferred, AnyPromise)
    {
        let deferred = AnyDeferred()
        return (deferred, deferred.promise)
    }
    
    public class func resolve(value: Any?) -> AnyPromise
    {
        // TODO: - Downcast to Thenable
        
        switch value {
        case let promise as AnyPromise:
            return promise
        default:
            return self(value: value)
        }
    }
    
    public class func reject(reason: Any?) -> AnyPromise
    {
        return self(reason: reason)
    }
    
    // MARK: - Thenable
    
    typealias NextType = AnyPromise
    typealias ValueType = Any?
    typealias ReasonType = Any?
    typealias ReturnType = Any?

    public func then(
        onFulfilled: Optional<(value: Any?) -> Any?> = nil,
        onRejected: Optional<(reason: Any?) -> Any?> = nil,
        onProgress: Optional<(progress: Float) -> Float> = nil
        ) -> AnyPromise
    {
        let (nextDeferred, nextPromise) = AnyPromise.defer()
        
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

    public func catch(onRejected: (reason: Any?) -> Any?) -> AnyPromise
    {
        let (nextDeferred, nextPromise) = AnyPromise.defer()
        
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

public extension AnyPromise {
    
    public class func all(values: [Any?]) -> AnyPromise
    {
        let (allDeferred, allPromise) = AnyPromise.defer()
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
    
    public class func all(values: Any?...) -> AnyPromise
    {
        return self.all(values)
    }
    
    public class func race(values: [Any?]) -> AnyPromise
    {
        let (raceDeferred, racePromise) = AnyPromise.defer()
        
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
    
    public class func race(values: Any?...) -> AnyPromise
    {
        return self.race(values)
    }
}

public extension AnyPromise {
    convenience
    public init<V>(promise: Promise<V>)
    {
        self.init()
        let deferred = AnyDeferred(promise: self)
        deferred.resolve(promise: promise)
    }
}