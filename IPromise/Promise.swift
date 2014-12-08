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
    
    public internal(set) var state: State = .Pending
    public internal(set) var value: V? = nil
    public internal(set) var reason: NSError? = nil
    
    weak var deferred: Deferred<V>?
    lazy var callbackSets: [CallbackSet<V>] = []
    
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
    
    public class func resolve(value: Any) -> Promise<V> {
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
    
    public class func reject(reason: NSError) -> Promise<V> {
        return Promise<V>(reason: reason)
    }
    
    // MARK: -
    
    func resolve(value: V) -> Void
    {
        objc_sync_enter(self)
        
        if self.state.fulfill() {
            self.value = value
            for callbackSet in self.callbackSets {
                callbackSet.fulfill(value: value)
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
                callbackSet.reject(reason: reason)
            }
        }
        
        objc_sync_exit(self)
    }
    
    func progress(progress: Float) -> Void
    {
        objc_sync_enter(self)
        
        if self.state == .Pending && (0.0 <= progress && progress <= 1.0) {
            for callbackSet in self.callbackSets {
                callbackSet.progress(progress: progress)
            }
        }
        
        objc_sync_exit(self)
    }
    
    // MARK: - Callbacks
    
    func bindCallbackSet(callbackSet: CallbackSet<V>) -> Void {
        objc_sync_enter(self)
        
        self.callbackSets.append(callbackSet)
        
        switch self.state {
        case .Fulfilled:
            callbackSet.fulfill(value: self.value!)
        case .Rejected:
            callbackSet.reject(reason: self.reason!)
        default:
            break
        }
        
        objc_sync_exit(self)
    }
    
    func unbindCallbackSet(callbackSet: CallbackSet<V>) -> Int {
        var count = Int.max
        
        objc_sync_enter(self)
        
        if let index = find(self.callbackSets, callbackSet)? {
            self.callbackSets.removeAtIndex(index)
        }
        
        count = self.callbackSets.count
        
        objc_sync_exit(self)
        
        return count
    }
    
    // MARK: - Thenable
    
    public typealias NextType = Promise<Void>
    public typealias ValueType = V
    public typealias ReasonType = NSError
    public typealias ReturnType = Void
        
    public func then(
        onFulfilled: Optional<(value: V) -> Void> = nil,
        onRejected: Optional<(reason: NSError) -> Void> = nil,
        onProgress: Optional<(progress: Float) -> Float> = nil
        ) -> Promise<Void>
    {
        let deferred = Deferred<Void>()
        
        let fulfill: CallbackSet<V>.Fulfill = (onFulfilled == nil) ?
            { (value: V) -> Void in deferred.resolve() } :
            { (value: V) -> Void in
                onFulfilled!(value: value)
                deferred.resolve()
        }
        let reject: CallbackSet<V>.Reject? = (onRejected == nil) ? nil :
            { (reason: NSError) -> Void in
                onRejected!(reason: reason)
                deferred.resolve()
        }
        let progress: CallbackSet<V>.Progress? = (onProgress == nil) ? nil :
            { (progress) -> Void in
                let nextProgress = onProgress!(progress: progress)
                deferred.progress(nextProgress)
        }
                
        bindCallbackSet(
            CallbackSet<V>(deferred, fulfill, reject, progress),
            unbindByDeferred: deferred
        )
        
        return deferred.promise
    }

    public func catch(
        #ignored: (reason: NSError) -> Void
        ) -> Promise<Void>
    {
        let nextDeferred = Deferred<Void>()

        let builder = CallbackSetVoidBuilder(promise: self, deferred: nextDeferred)
        builder.reject = ignored
        
        self.bindCallbackSet(builder.build())
        
        return nextDeferred.promise
    }
}

public extension Promise {
    
    public func then<N>(
        #onFulfilled: (value: V) -> N,
        onRejected: Optional<(reason: NSError) -> N> = nil,
        onProgress: Optional<(progress: Float) -> Float> = nil
        ) -> Promise<N>
    {
        let nextDeferred = Deferred<N>()
        
        let builder = CallbackSetValueBuilder(promise: self, deferred: nextDeferred)
        builder.reject = onRejected
        builder.progress = onProgress
        
        self.bindCallbackSet(builder.build({ (value) -> Void in
            let nextValue = onFulfilled(value: value)
            nextDeferred.resolve(nextValue)
        }))
        
        return nextDeferred.promise
    }
    
    public func catch(
        onRejected: (reason: NSError) -> V
        ) -> Promise<V>
    {
        let nextDeferred = Deferred<V>()
        
        let builder = CallbackSetValueBuilder(promise: self, deferred: nextDeferred)
        builder.reject = onRejected
        
        self.bindCallbackSet(builder.build({ (value) -> Void in
            nextDeferred.resolve(value)
        }))
        
        return nextDeferred.promise
    }
}

public extension Promise {
    
    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError, T.ReturnType == Void>(
        #onFulfilled: (value: V) -> T,
        onRejected: Optional<(reason: NSError) -> T> = nil,
        onProgress: Optional<(progress: Float) -> Float> = nil
        ) -> Promise<N>
    {
        let fraction: Float = (onProgress == nil) ? 0.0 : 1.0 - onProgress!(progress: 1.0)
        
        let nextDeferred = Deferred<N>()
        
        let builder = CallbackSetThenableBuilder<V, N, T>(promise: self, deferred: nextDeferred)
        builder.reject = onRejected
        builder.progress = onProgress

        self.bindCallbackSet(builder.build({ (value) -> Void in
            let nextThenable = onFulfilled(value: value)
            nextDeferred.resolve(thenable: nextThenable, fraction: fraction)
        }))
        
        return nextDeferred.promise
    }
    
    public func catch<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(
        onRejected: (reason: NSError) -> T
        ) -> Promise<V>
    {
        let nextDeferred = Deferred<V>()
        
        let builder = CallbackSetThenableBuilder<V, V, T>(promise: self, deferred: nextDeferred)
        builder.reject = onRejected
        
        self.bindCallbackSet(builder.build({ (value) -> Void in
            nextDeferred.resolve(value)
        }))
        
        return nextDeferred.promise
    }
}

public extension Promise {
    
    public func progress(onProgress: (progress: Float) -> Float) -> Promise<V>
    {
        let nextDeferred = Deferred<V>()
        
        let builder = CallbackSetProgressBuilder(promise: self, deferred: nextDeferred)
        builder.progress = onProgress
        
        self.bindCallbackSet(builder.build())
        
        return nextDeferred.promise
    }
    
    public func progress(onProgress: (progress: Float) -> Void) -> Promise<V>
    {
        let nextDeferred = Deferred<V>()
        
        let builder = CallbackSetProgressBuilder(promise: self, deferred: nextDeferred)

        self.bindCallbackSet(builder.build())
        
        return nextDeferred.promise
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
    
    public func cancel() -> Promise<Void> {
        let cancelErr = NSError.promiseCancelError()
        
        if .Pending == self.state {
            return invokeCancelEvent(canceled: true)
        }
        else if .Rejected == self.state && cancelErr == self.reason  {
            return Promise<Void>(value: ())
        }
        else {
            return Promise<Void>(reason: NSError.promiseWrongStateError(state: self.state, to: "cancel"))
        }
    }
    
    internal func cancelByRemovingCallbackSet(callbackSet: CallbackSet<V>) -> Promise<Void> {
        return (unbindCallbackSet(callbackSet) == 0) ? cancel() : invokeCancelEvent(canceled: false)
    }
    
    internal func invokeCancelEvent(#canceled: Bool) -> Promise<Void> {
        if let deferred = self.deferred? {
            return deferred.cancel(invoke: canceled)
        }
        else {
            return Promise<Void>(value: ())
        }
    }
    
    private func bindCallbackSet<N>(callbackSet: CallbackSet<V>, unbindByDeferred deferred: Deferred<N>) -> Void {
        bindCallbackSet(callbackSet)
        deferred.onCanceled { [weak self] () -> Promise<Void>? in
            return self?.cancelByRemovingCallbackSet(callbackSet)
        }
    }
}