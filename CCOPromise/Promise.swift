//
//  Promise.swift
//  CCOPromise
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
    lazy var fulfillCallbacks: [FulfillClosure] = []
    lazy var rejectCallbacks: [RejectClosure] = []
    
    // MARK: - Initializers
    
    required
    public init() {}
    
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
    
    required convenience
    public init(resolver: (resolve: FulfillClosure, reject: RejectClosure) -> Void)
    {
        self.init()
        resolver(
            resolve: self.resolve,
            reject: self.reject
        )
    }
    
    convenience
    public init<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(thenable: T)
    {
        self.init()
        self.resolve(thenable: thenable)
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
    
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(#thenable: T) -> Void
    {
        if self.state != .Pending {
            return
        }
        
        if (thenable as? Promise<V>) === self {
            self.reject(NSError.promiseTypeError())
        }
        else {
            thenable.then(
                onFulfilled: { (value: V) -> Void in
                    self.resolve(value)
                },
                onRejected: { (reason: NSError) -> Void in
                    self.reject(reason)
                }
            );
        }
        
    }

    // MARK: - Public APIs
    
    func resolve(value: V) -> Void
    {
        if self.state != .Pending {
            return
        }
        
        self.value = value
        self.state = .Fulfilled
        
        for callback in self.fulfillCallbacks {
            callback(value: value)
        }
    }
    
    public func reject(reason: NSError) -> Void
    {
        if self.state != .Pending {
            return
        }
        
        self.reason = reason
        self.state = .Rejected
        
        for callback in self.rejectCallbacks {
            callback(reason: reason)
        }
    }
    
    public func toAnyPromise() -> APlusPromise {
        let promise = APlusPromise()
        self.then(
            onFulfilled: { (value) -> Void in
                promise.resolve(value)
            },
            onRejected: { (reason) -> Void in
                promise.reject(reason)
            }
        )
        return promise;
    }
    
    // MARK: - Static APIs
    
    public class func resolve<V>(value: Any) -> Promise<V>
    {
        switch value {
        case let value as V:
            return Promise<V>(value: value)
        case let promise as Promise<V>:
            return promise
        default:
            NSLog("Expect value of V or Promise<V>, but find \(reflect(value).summary).")
            return value as Promise<V>  // abort()
        }
    }
    
    public class func reject<V>(reason: NSError) -> Promise<V>
    {
        return Promise<V>(reason: reason)
    }
    
    public class func all<V>(values: Any...) -> Promise<[V]>
    {
        let allPromise = Promise<[V]>()
        let count = values.count
        var results: [V] = []
        
        for value in values
        {
            let promise: Promise<V> = self.resolve(value)
            promise.then(
                onFulfilled: { (value) -> Void in
                    results.append(value)
                    if results.count >= count {
                        allPromise.resolve(results)
                    }
                },
                onRejected: { (reason) -> Void in
                    allPromise.reject(reason)
                }
            )
        }
        
        return allPromise
    }
    
    public class func race<V>(values: Any...) -> Promise<V>
    {
        let racePromise = Promise<V>()
        
        for value in values
        {
            let promise: Promise<V> = self.resolve(value)
            promise.then(
                onFulfilled: { (value) -> Void in
                    racePromise.resolve(value)
                },
                onRejected: { (reason) -> Void in
                    racePromise.reject(reason)
                }
            )
        }
        
        return racePromise
    }
    
    // MARK: - Thenable
    
    public typealias NextType = Promise<Any?>
    public typealias ValueType = V
    public typealias ReasonType = NSError
    public typealias ReturnType = Void
    
    public func then(
        #onFulfilled: Optional<(value: V) -> Void>,
        onRejected: Optional<(reason: NSError) -> Void>
        ) -> Promise<Any?>
    {
        let subPromise = Promise<Any?>()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                if let resolution = onFulfilled? {
                    resolution(value: value)
                    subPromise.resolve(nil)
                }
                else {
                    subPromise.resolve(value)
                }
            },
            rejectCallback: { (reason) -> Void in
                if let rejection = onRejected? {
                    rejection(reason: reason)
                    subPromise.resolve( nil)
                }
                else {
                    subPromise.reject(reason)
                }
            }
        );
        
        return subPromise
    }

    // MARK: - Thenable enhance
    
    public func then(
        onFulfilled: (value: V) -> Void
        ) -> Promise<Any?>
    {
        let subPromise = Promise<Any?>()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                onFulfilled(value: value)
                subPromise.resolve(nil)
            },
            rejectCallback: { (reason) -> Void in
                subPromise.reject(reason)
            }
        );
        
        return subPromise
    }
    
    public func catch(
        onRejected: (reason: NSError) -> Void
        ) -> Promise<Any?>
    {
        let subPromise = Promise<Any?>()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                subPromise.resolve(value)
            },
            rejectCallback: { (reason) -> Void in
                onRejected(reason: reason)
                subPromise.resolve(nil)
            }
        );

        return subPromise
    }
    
    public func then<N: Any>(
        #onFulfilled: (value: V) -> N,
        onRejected: (reason: NSError) -> N
        ) -> Promise<N>
    {
        let subPromise = Promise<N>()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                subPromise.resolve(onFulfilled(value: value))
            },
            rejectCallback: { (reason) -> Void in
                subPromise.resolve(onRejected(reason: reason))
            }
        );
        
        return subPromise
    }
    
    public func then<N>(
        onFulfilled: (value: V) -> N
        ) -> Promise<N>
    {
        let subPromise = Promise<N>()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                subPromise.resolve(onFulfilled(value: value))
            },
            rejectCallback: { (reason) -> Void in
                subPromise.reject(reason)
            }
        );

        return subPromise
    }

    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError, T.ReturnType == Void>(
        #onFulfilled: (value: V) -> T,
        onRejected: (reason: NSError) -> T
        ) -> Promise<N>
    {
        let subPromise = Promise<N>()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                subPromise.resolve(thenable: onFulfilled(value: value))
            },
            rejectCallback: { (reason) -> Void in
                subPromise.resolve(thenable: onRejected(reason: reason))
            }
        );
        
        return subPromise
    }
    
    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError, T.ReturnType == Void>(
        onFulfilled: (value: V) -> T
        ) -> Promise<N>
    {
        let subPromise = Promise<N>()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                subPromise.resolve(thenable: onFulfilled(value: value))
            },
            rejectCallback: { (reason) -> Void in
                subPromise.reject(reason)
            }
        );
        
        return subPromise
    }
}

public extension Promise {
    convenience
    public init<T: Thenable where T.ValueType == V, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(anyThenable: T)
    {
        self.init()
        self.resolve(anyThenable: anyThenable)
    }
    
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(#anyThenable: T) -> Void
    {
        if self.state != .Pending {
            return
        }
        
        anyThenable.then(
            onFulfilled: { (value: V) -> Any? in
                self.resolve(value)
                return nil
            },
            onRejected: { (reason: Any?) -> Any? in
                if let reasonObject = reason as? NSError {
                    self.reject(reasonObject)
                }
                else {
                    self.reject(NSError.promiseReasonWrapperError(reason))
                }
                return nil
            }
        );
    }
}