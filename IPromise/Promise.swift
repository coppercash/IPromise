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
    
    weak var deferred: Deferred<V>?
    lazy var callbackSets: [CallbackSet<V, NSError>] = []
    
    /*
    lazy var fulfillCallbacks: [FulfillClosure] = []
    lazy var rejectCallbacks: [RejectClosure] = []
    lazy var progressCallbacks: [ProgressClosure] = []
*/
    
    // MARK: - Initializers
    
    init() {
        self.state = .Pending
    }
    
    required
    public init(value: V) {
        self.value = value
        self.state = .Fulfilled
    }
    
    required
    public init(reason: NSError) {
        self.reason = reason
        self.state = .Rejected
    }
    
    convenience
    public init(resolver: (resolve: (value: V) -> Void, reject: (reason: NSError) -> Void) -> Void) {
        self.init()
        
        let deferred = Deferred<V>(promise: self)
        resolver(
            resolve: deferred.resolve,
            reject: deferred.reject
        )
    }
    
    convenience
    public init<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(thenable: T) {
        self.init()
        
        let deferred = Deferred<V>(promise: self)
        deferred.resolve(thenable: thenable, fraction: 1.0)
    }

    // MARK: - Static APIs
    
    public class func defer() -> (Deferred<V>, Promise<V>) {
        let deferred = Deferred<V>()
        return (deferred, deferred.promise)
    }
    
    public class func resolve<V>(value: Any) -> Promise<V> {
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
    
    public class func reject<V>(reason: NSError) -> Promise<V> {
        return Promise<V>(reason: reason)
    }
    
    // MARK: -
    
    func resolve(value: V) -> Void
    {
        objc_sync_enter(self)
        
        if self.state.fulfill() {
            self.value = value
            for callbackSet in self.callbackSets {
                callbackSet.fulfillCallback(value: value)
            }
        }
        
        objc_sync_exit(self)
    }
    
    func reject(reason: NSError) -> Void
    {
        objc_sync_enter(self)
        
        if self.state.reject() {
            self.reason = reason
            for callbackSet in self.callbackSets {
                callbackSet.rejectCallback(reason: reason)
            }
        }
        
        objc_sync_exit(self)
    }
    
    func progress(progress: Float) -> Void
    {
        objc_sync_enter(self)
        
        if self.state == .Pending && (0.0 <= progress && progress <= 1.0) {
            for callbackSet in self.callbackSets {
                callbackSet.progressCallback(progress: progress)
            }
        }
        
        objc_sync_exit(self)
    }
    
    // MARK: - Callbacks
    
    func bindCallbackSet(callbackSet: CallbackSet<V, NSError>) -> Void {
        objc_sync_enter(self)
        
        self.callbackSets.append(callbackSet)
        
        switch self.state {
        case .Fulfilled:
            callbackSet.fulfillCallback(value: self.value!)
        case .Rejected:
            callbackSet.rejectCallback(reason: self.reason!)
        default:
            break
        }
        
        objc_sync_exit(self)
    }
    
    func unbindCallbackSet(callbackSet: CallbackSet<V, NSError>) {
        objc_sync_enter(self)
        
        if let index = find(self.callbackSets, callbackSet)? {
            self.callbackSets.removeAtIndex(index)
        }
        if self.callbackSets.count == 0 {
            self.cancel()
        }
        
        objc_sync_exit(self)
    }
    
    // MARK: - Thenable
    
    public typealias NextType = Promise<Void>
    public typealias ValueType = V
    public typealias ReasonType = NSError
    public typealias ReturnType = Void
    
    typealias FulfillClosure = (value: V) -> Void
    typealias RejectClosure = (reason: NSError) -> Void
    typealias ProgressClosure = (progress: Float) -> Void
    
    public func then(
        onFulfilled: Optional<(value: V) -> Void> = nil,
        onRejected: Optional<(reason: NSError) -> Void> = nil,
        onProgress: Optional<(progress: Float) -> Float> = nil
        ) -> Promise<Void>
    {
        let (nextDeferred, nextPromise) = Promise<Void>.defer()
        
        let fulfillCallback: FulfillClosure = (onFulfilled == nil) ?
            { (value: V) -> Void in nextDeferred.resolve() } :
            { (value: V) -> Void in
                onFulfilled!(value: value)
                nextDeferred.resolve()
        }
        let rejectCallback: RejectClosure = (onRejected == nil) ?
            { (reason: NSError) -> Void in nextDeferred.reject(reason) } :
            { (reason: NSError) -> Void in
                onRejected!(reason: reason)
                nextDeferred.resolve()
        }
        let progressCallback: ProgressClosure = (onProgress == nil) ?
            { (progress: Float) -> Void in nextDeferred.progress(progress) } :
            { (progress: Float) -> Void in
                let nextProgress = onProgress!(progress: progress)
                nextDeferred.progress(nextProgress)
        }

        let callbackSet = CallbackSet<V, NSError>(fulfillCallback, rejectCallback, progressCallback)
        self.bindCallbackSet(callbackSet)
        
        
        nextDeferred.onCanceled { [unowned self, callbackSet] () -> Void in
            self.unbindCallbackSet(callbackSet)
        }
        
        return nextPromise
    }

    public func catch(
        #ignored: (reason: NSError) -> Void
        ) -> Promise<Void>
    {
        let (nextDeferred, nextPromise) = Promise<Void>.defer()
        
        let callbackSet = CallbackSet<V, NSError>(
            fulfillCallback: { (value) -> Void in
                nextDeferred.resolve()
            },
            rejectCallback: { (reason) -> Void in
                ignored(reason: reason)
                nextDeferred.resolve()
            },
            progressCallback: { (progress) -> Void in
                nextDeferred.progress(progress)
            }
        )
        
        self.bindCallbackSet(callbackSet)
        
        return nextPromise
    }

    
    // MARK: - Cancel

    public func cancel() -> Promise<Void> {
        reject(NSError.promiseCancelError())
        
        if let cancelation = self.deferred?.cancelation? {
            return cancelation()
        }
        else {
            return Promise<Void>(value: ())
        }
    }
}

public extension Promise {
    
    public func then<N>(
        #onFulfilled: (value: V) -> N,
        onRejected: Optional<(reason: NSError) -> N> = nil,
        onProgress: Optional<(progress: Float) -> Float> = nil
        ) -> Promise<N>
    {
        let (nextDeferred, nextPromise) = Promise<N>.defer()
        
        let fulfillCallback: FulfillClosure =
        { (value) -> Void in
            let nextValue = onFulfilled(value: value)
            nextDeferred.resolve(nextValue)
        }
        let rejectCallback: RejectClosure = (onRejected == nil) ?
            { (reason) -> Void in nextDeferred.reject(reason) } :
            { (reason) -> Void in
                let nextValue = onRejected!(reason: reason)
                nextDeferred.resolve(nextValue)
        }
        let progressCallback: ProgressClosure = (onProgress == nil) ?
            { (progress: Float) -> Void in nextDeferred.progress(progress) } :
            { (progress: Float) -> Void in
                let nextProgress = onProgress!(progress: progress)
                nextDeferred.progress(nextProgress)
        }
        
        let callbackSet = CallbackSet<V, NSError>(fulfillCallback, rejectCallback, progressCallback)
        self.bindCallbackSet(callbackSet)
        
        return nextPromise
    }
    
    public func catch(
        onRejected: (reason: NSError) -> V
        ) -> Promise<V>
    {
        let (nextDeferred, nextPromise) = Promise<V>.defer()
        
        let callbackSet = CallbackSet<V, NSError>(
            fulfillCallback: { (value) -> Void in
                nextDeferred.resolve(value)
            },
            rejectCallback: { (reason) -> Void in
                let nextValue = onRejected(reason: reason)
                nextDeferred.resolve(nextValue)
            },
            progressCallback: { (progress) -> Void in
                nextDeferred.progress(progress)
            }
        )
        
        self.bindCallbackSet(callbackSet)
        
        return nextPromise
    }
}

public extension Promise {
    
    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError, T.ReturnType == Void>(
        #onFulfilled: (value: V) -> T,
        onRejected: Optional<(reason: NSError) -> T> = nil,
        onProgress: Optional<(progress: Float) -> Float> = nil
        ) -> Promise<N>
    {
        let (nextDeferred, nextPromise) = Promise<N>.defer()
        let fraction: Float = (onProgress == nil) ? 0.0 : 1.0 - onProgress!(progress: 1.0)
        
        let fulfillCallback: FulfillClosure = { (value) -> Void in
            let nextThenable = onFulfilled(value: value)
            nextDeferred.resolve(thenable: nextThenable, fraction: fraction)
        }
        let rejectCallback: RejectClosure = (onRejected == nil) ?
            { (reason) -> Void in nextDeferred.reject(reason) } :
            { (reason) -> Void in
                let nextThenable = onRejected!(reason: reason)
                nextDeferred.resolve(thenable: nextThenable, fraction: fraction)
        }
        let progressCallback: ProgressClosure = (onProgress == nil) ?
            { (progress: Float) -> Void in nextDeferred.progress(progress) } :
            { (progress: Float) -> Void in
                let nextProgress = onProgress!(progress: progress)
                nextDeferred.progress(nextProgress)
        }
        let callbackSet = CallbackSet<V, NSError>(fulfillCallback, rejectCallback, progressCallback)
        self.bindCallbackSet(callbackSet)

        return nextPromise
    }
    
    public func catch(
        onRejected: (reason: NSError) -> Promise<V>
        ) -> Promise<V>
    {
        let (nextDeferred, nextPromise) = Promise<V>.defer()
        
        let callbackSet = CallbackSet<V, NSError>(
            fulfillCallback: { (value) -> Void in
                nextDeferred.resolve(value)
            },
            rejectCallback: { (reason) -> Void in
                let nextPromise = onRejected(reason: reason)
                nextDeferred.resolve(thenable: nextPromise, fraction: 0.0)
            },
            progressCallback: { (progress) -> Void in
                nextDeferred.progress(progress)
            }
        )
        self.bindCallbackSet(callbackSet)

        return nextPromise
    }
}

public extension Promise {
    public func progress(onProgress: (progress: Float) -> Float) -> Promise<V>
    {
        let (nextDeferred, nextPromise) = Promise<V>.defer()

        let callbackSet = CallbackSet<V, NSError>(
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
        self.bindCallbackSet(callbackSet)

        return nextPromise
    }
    
    public func progress(onProgress: (progress: Float) -> Void) -> Promise<V>
    {
        let (nextDeferred, nextPromise) = Promise<V>.defer()
        
        let callbackSet = CallbackSet<V, NSError>(
            fulfillCallback: { (value) -> Void in
                nextDeferred.resolve(value)
            },
            rejectCallback: { (reason) -> Void in
                nextDeferred.reject(reason)
            },
            progressCallback: { (progress) -> Void in
                nextDeferred.progress(progress)
            }
        )
        self.bindCallbackSet(callbackSet)

        return nextPromise
    }
}

public extension Promise {
    
    public class func all<V>(promises: [Promise<V>]) -> Promise<[V]>
    {
        var remain: Int = promises.count
        var results: [V?] = [V?](count: remain, repeatedValue: nil)
        var progresses: [Float] = [Float](count: remain, repeatedValue: 0.0)
        let count: Float = Float(remain)
        
        let (allDeferred, allPromise) = Promise<[V]>.defer()
        
        for (index, promise) in enumerate(promises)
        {
            promise.then(
                onFulfilled: { (value) -> Void in
                    objc_sync_enter(allDeferred)
                    results[index] = value
                    remain -= 1
                    objc_sync_exit(allDeferred)
                    
                    if (remain > 0) { return }
                    
                    var allValue: [V] = []
                    for result: V? in results { allValue.append(result!) }
                    allDeferred.resolve(allValue)
                },
                onRejected: { (reason) -> Void in
                    allDeferred.reject(reason)
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
    
    public class func all<V>(promises: Promise<V>...) -> Promise<[V]>
    {
        return self.all(promises)
    }
    
    public class func race<V>(promises: [Promise<V>]) -> Promise<V>
    {
        var progresses: [Float] = [Float](count: promises.count, repeatedValue: 0.0)
        
        let (raceDeferred, racePromise) = Promise<V>.defer()
        
        for (index, promise) in enumerate(promises)
        {
            promise.then(
                onFulfilled: { (value) -> Void in
                    raceDeferred.resolve(value)
                },
                onRejected: { (reason) -> Void in
                    raceDeferred.reject(reason)
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
        
        vagueThenable.then(
            onFulfilled: { (value: V) -> Any? in
                deferred.resolve(value)
                return nil
            },
            onRejected: { (reason: Any?) -> Any? in
                if let reasonObject = reason as? NSError {
                    deferred.reject(reasonObject)
                }
                else {
                    deferred.reject(NSError.promiseReasonWrapperError(reason))
                }
                return nil
            },
            onProgress: { (progress: Float) -> Float in
                return -1
            }
        )
    }
}