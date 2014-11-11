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
    public typealias ProgressClosure = (progress: Float) -> Void

    lazy var fulfillCallbacks: [FulfillClosure] = []
    lazy var rejectCallbacks: [RejectClosure] = []
    lazy var progressCallbacks: [ProgressClosure] = []

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
        deferred.resolve(thenable: thenable, fraction: 1.0)
    }
    
    // MARK: - Private APIs
    
    func bindCallbacks(
        #fulfillCallback: FulfillClosure,
        rejectCallback: RejectClosure,
        progressCallback: ProgressClosure
        ) -> Void
    {
        objc_sync_enter(self)

        self.fulfillCallbacks.append(fulfillCallback)
        self.rejectCallbacks.append(rejectCallback)
        self.progressCallbacks.append(progressCallback)
        
        switch self.state {
        case .Fulfilled:
            fulfillCallback(value: self.value!)
        case .Rejected:
            rejectCallback(reason: self.reason!)
        default:
            break
        }
        
        objc_sync_exit(self)
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
        let fraction: Float = (onProgress == nil) ? 0.0 : 1.0 - onProgress!(progress: 1.0)

        let fulfillCallback: FulfillClosure = (onFulfilled == nil) ?
            { (value: Any?) -> Void in nextDeferred.resolve(value) } :
            { (value: Any?) -> Void in
                let nextValue: Any? = onFulfilled!(value: value)
                if let nextPromise = nextValue as? AnyPromise {
                    nextDeferred.resolve(thenable: nextPromise, fraction: fraction)
                }
                else {
                    nextDeferred.resolve(nextValue)
                }
            }
        let rejectCallback: RejectClosure = (onRejected == nil) ?
            { (reason: Any?) -> Void in nextDeferred.reject(reason) } :
            { (reason: Any?) -> Void in
                let nextValue: Any? = onRejected!(reason: reason)
                if let nextPromise = nextValue as? AnyPromise {
                    nextDeferred.resolve(thenable: nextPromise, fraction: fraction)
                }
                else {
                    nextDeferred.resolve(nextValue)
                }
            }
        let progressCallback: ProgressClosure = (onProgress == nil) ?
            { (progress: Float) -> Void in nextDeferred.progress(progress) } :
            { (progress: Float) -> Void in
                let nextProgress = onProgress!(progress: progress)
                nextDeferred.progress(nextProgress)
        }
        self.bindCallbacks(fulfillCallback, rejectCallback, progressCallback)
        
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
            },
            progressCallback: { (progress) -> Void in
                nextDeferred.progress(progress)
            }
        )
        
        return nextPromise
    }
    
    public func progress(onProgress: (progress: Float) -> Float) -> AnyPromise
    {
        let (nextDeferred, nextPromise) = AnyPromise.defer()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                nextDeferred.resolve(value)
            },
            rejectCallback: { (reason) -> Void in
                nextDeferred.reject(reason)
            },
            progressCallback: { (progress) -> Void in
                let nextProgress = onProgress(progress: progress)
                nextDeferred.progress(nextProgress)
            }
        )
        
        return nextPromise
    }
}

public extension AnyPromise {
    
    public class func all(values: [Any?]) -> AnyPromise
    {
        var remain: Int = values.count
        var results: [Any??] = [Any??](count: remain, repeatedValue: nil)
        var progresses: [Float] = [Float](count: remain, repeatedValue: 0.0)
        let count = Float(remain)

        let (allDeferred, allPromise) = AnyPromise.defer()
        
        for (index, value) in enumerate(values)
        {
            let promise = self.resolve(value)
            promise.then(
                onFulfilled: { (value) -> Any? in
                    objc_sync_enter(allDeferred)
                    results[index] = value
                    remain -= 1
                    objc_sync_exit(allDeferred)
                    
                    if (remain > 0) { return nil }
                    
                    var allValue: [Any?] = []
                    for result: Any?? in results { allValue.append(result!) }
                    allDeferred.resolve(allValue)
                    
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    allDeferred.reject(reason)
                    return nil
                },
                onProgress: { (progress) -> Float in
                    objc_sync_enter(allDeferred)
                    progresses[index] = progress
                    let allProgress: Float = progresses.reduce(0.0, combine: +) / count
                    objc_sync_exit(allDeferred)
                    
                    allDeferred.progress(allProgress)
                    return -1
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
        var progresses: [Float] = [Float](count: values.count, repeatedValue: 0.0)

        let (raceDeferred, racePromise) = AnyPromise.defer()
        
        for (index, value) in enumerate(values)
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
                },
                onProgress: { (progress) -> Float in
                    objc_sync_enter(raceDeferred)
                    progresses[index] = progress
                    let maxProgress: Float = progresses.reduce(0.0, combine: max)
                    objc_sync_exit(raceDeferred)
                    
                    raceDeferred.progress(maxProgress)
                    return -1
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
        promise.then(
            onFulfilled: { (value) -> Void in
                deferred.resolve(value)
            },
            onRejected: { (reason) -> Void in
                deferred.reject(reason)
            },
            onProgress: { (progress: Float) -> Float in
                return -1
            }
        )
    }
}