//
//  Promise.swift
//  IPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class Promise<V>: Thenable
{
    // MARK: - ivars
    
    public internal(set) var state: PromiseState = .Pending
    public internal(set) var value: V? = nil
    public internal(set) var reason: NSError? = nil
    
    public typealias FulfillClosure = (value: V) -> Void
    public typealias RejectClosure = (reason: NSError) -> Void
    public typealias ProgressClosure = (progress: Float) -> Void
    
    lazy var fulfillCallbacks: [FulfillClosure] = []
    lazy var rejectCallbacks: [RejectClosure] = []
    lazy var progressCallbacks: [ProgressClosure] = []
    
    // MARK: - Initializers
    
    init() {}
    
    required
    public init(value: V)
    {
        self.value = value
        self.state = .Fulfilled
    }
    
    required
    public init(reason: NSError)
    {
        self.reason = reason
        self.state = .Rejected
    }
    
    convenience
    public init(resolver: (resolve: FulfillClosure, reject: RejectClosure) -> Void)
    {
        self.init()
        
        let deferred = Deferred<V>(promise: self)
        resolver(
            resolve: deferred.resolve,
            reject: deferred.reject
        )
    }
    
    convenience
    public init<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(thenable: T)
    {
        self.init()
        
        let deferred = Deferred<V>(promise: self)
        deferred.resolve(thenable: thenable)
    }
    
    // MARK: - Private APIs
    
    func bindCallbacks(#fulfillCallback: FulfillClosure, rejectCallback: RejectClosure) -> Void
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

    func bindProgressCallback(callback: ProgressClosure) -> Void {
        self.progressCallbacks.append(callback)
    }
    
    // MARK: - Static APIs
    
    public class func defer() -> (Deferred<V>, Promise<V>)
    {
        let deferred = Deferred<V>()
        return (deferred, deferred.promise)
    }
    
    public class func resolve<V>(value: Any) -> Promise<V>
    {
        switch value {
        case let promise as Promise<V>:
            return promise
        case let value as V:
            return Promise<V>(value: value)
        default:
            let error = NSError.promiseValueTypeError(expectType: "V", value: value)
            println(error)
            abort()
        }
    }
    
    public class func reject<V>(reason: NSError) -> Promise<V>
    {
        return Promise<V>(reason: reason)
    }
    
    // MARK: - Thenable
    
    public typealias NextType = Promise<Void>
    public typealias ValueType = V
    public typealias ReasonType = NSError
    public typealias ReturnType = Void
    
    public func then(
        onFulfilled: Optional<(value: V) -> Void> = nil,
        onRejected: Optional<(reason: NSError) -> Void> = nil
        ) -> Promise<Void>
    {
        let (nextDeferred, nextPromise) = Promise<Void>.defer()
        
        let fulfillCallback: FulfillClosure = (onFulfilled != nil) ?
            { (value: V) -> Void in
                onFulfilled!(value: value)
                nextDeferred.resolve()
            } :
            { (value: V) -> Void in nextDeferred.resolve() }
        
        let rejectCallback: RejectClosure = (onRejected != nil) ?
            { (reason: NSError) -> Void in
                onRejected!(reason: reason)
                nextDeferred.resolve()
            } :
            { (reason: NSError) -> Void in nextDeferred.reject(reason) }
        
        self.bindCallbacks(fulfillCallback, rejectCallback)
        
        return nextPromise
    }
    
    // MARK: - Progress
    
    public func progress(onProgress: (progress: Float) -> Void) -> Promise<V>
    {
        self.bindProgressCallback { (progress) -> Void in
            onProgress(progress: progress)
        }
        return self
    }
}

public extension Promise {
    
    public func then(
        onFulfilled: (value: V) -> Void
        ) -> Promise<Void>
    {
        let (nextDeferred, nextPromise) = Promise<Void>.defer()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                onFulfilled(value: value)
                nextDeferred.resolve()
            },
            rejectCallback: { (reason) -> Void in
                nextDeferred.reject(reason)
            }
        )
        
        return nextPromise
    }
    
    public func catch(
        onRejected: (reason: NSError) -> Void
        ) -> Promise<Void>
    {
        let (nextDeferred, nextPromise) = Promise<Void>.defer()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                nextDeferred.resolve()
            },
            rejectCallback: { (reason) -> Void in
                onRejected(reason: reason)
                nextDeferred.resolve()
            }
        )
        
        return nextPromise
    }
    
    public func then<N: Any>(
        #onFulfilled: (value: V) -> N,
        onRejected: (reason: NSError) -> N
        ) -> Promise<N>
    {
        let (nextDeferred, nextPromise) = Promise<N>.defer()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                let nextValue = onFulfilled(value: value)
                nextDeferred.resolve(nextValue)
            },
            rejectCallback: { (reason) -> Void in
                let nextValue = onRejected(reason: reason)
                nextDeferred.resolve(nextValue)
            }
        )
        
        return nextPromise
    }
    
    public func then<N>(
        onFulfilled: (value: V) -> N
        ) -> Promise<N>
    {
        let (nextDeferred, nextPromise) = Promise<N>.defer()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                let nextValue = onFulfilled(value: value)
                nextDeferred.resolve(nextValue)
            },
            rejectCallback: { (reason) -> Void in
                nextDeferred.reject(reason)
            }
        )
        
        return nextPromise
    }
    
    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError, T.ReturnType == Void>(
        #onFulfilled: (value: V) -> T,
        onRejected: (reason: NSError) -> T
        ) -> Promise<N>
    {
        let (nextDeferred, nextPromise) = Promise<N>.defer()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                let nextThenable = onFulfilled(value: value)
                nextDeferred.resolve(thenable: nextThenable)
            },
            rejectCallback: { (reason) -> Void in
                let nextThenable = onRejected(reason: reason)
                nextDeferred.resolve(thenable: nextThenable)
            }
        )
        
        return nextPromise
    }
    
    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError, T.ReturnType == Void>(
        onFulfilled: (value: V) -> T
        ) -> Promise<N>
    {
        let (nextDeferred, nextPromise) = Promise<N>.defer()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                let nextThenable = onFulfilled(value: value)
                nextDeferred.resolve(thenable: nextThenable)
            },
            rejectCallback: { (reason) -> Void in
                nextDeferred.reject(reason)
            }
        )
        
        return nextPromise
    }
}

public extension Promise {
    
    public class func all<V>(promises: [Promise<V>]) -> Promise<[V]>
    {
        let count = promises.count
        var results: [V] = []
        
        let (allDeferred, allPromise) = Promise<[V]>.defer()
        
        for promise in promises
        {
            promise.then(
                onFulfilled: { (value) -> Void in
                    results.append(value)
                    if results.count >= count {
                        allDeferred.resolve(results)
                    }
                },
                onRejected: { (reason) -> Void in
                    allDeferred.reject(reason)
                }
            )
        }
        
        return allPromise
    }
    
    public class func all<V>(promises: Promise<V>...) -> Promise<[V]>
    {
        return self.all(promises)
    }
    
    public class func race<V>(promises: [Promise<V>]) -> Promise<V>
    {
        let (raceDeferred, racePromise) = Promise<V>.defer()
        
        for promise in promises
        {
            promise.then(
                onFulfilled: { (value) -> Void in
                    raceDeferred.resolve(value)
                },
                onRejected: { (reason) -> Void in
                    raceDeferred.reject(reason)
                }
            )
        }
        
        return racePromise
    }
    
    public class func race<V>(promises: Promise<V>...) -> Promise<V>
    {
        return self.race(promises)
    }
}

public extension Promise {
    
    convenience
    public init<T: Thenable where T.ValueType == V, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(vagueThenable: T)
    {
        self.init()
        let deferred = Deferred<V>(promise: self)
        deferred.resolve(vagueThenable: vagueThenable)
    }
}