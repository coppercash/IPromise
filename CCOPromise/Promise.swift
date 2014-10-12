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
    // MARK: - Type
    
    public typealias FulfillClosure = (value: V) -> Void
    public typealias RejectClosure = (reason: NSError) -> Void
    
    // MARK: - ivars
    
    public internal(set) var state: PromiseState = .Pending
    public internal(set) var value: V? = nil
    public internal(set) var reason: NSError? = nil
    
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
    
    convenience
    public init<T: Thenable where T.ValueType == V, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(anyThenable: T)
    {
        self.init()
        self.resolve(anyThenable: anyThenable)
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
    
    // MARK: - Static APIs
    
    public class func resolve(value: Any?) -> Promise<Any?>
    {
        // TODO: Downcast to thenable and follow it
        // TODO: Downcast to Promise and return it directly
        
        if let validValue = value {
            if let anyOptPromise = validValue as? Promise<Any?> {
                return anyOptPromise
            }
            else if let aPlusPromise = validValue as? APlusPromise {
                return Promise<Any?>(anyThenable: aPlusPromise)
            }
        }
    
        return Promise<Any?>(value: value)
    }
    
    public class func reject(reason: NSError) -> Promise<Any?>
    {
        return Promise<Any?>(reason: reason)
    }
    
    public class func all(values: Any?...) -> Promise<Any?>
    {
        let allPromise = Promise<Any?>()
        let count = values.count
        var results: [Any?] = []
        
        for value in values
        {
            let promise = self.resolve(value)
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
    
    public class func race(values: Any?...) -> Promise<Any?>
    {
        let racePromise = Promise<Any?>()
        
        for value in values
        {
            let promise = self.resolve(value)
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