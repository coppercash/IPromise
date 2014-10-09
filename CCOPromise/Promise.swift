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
    
    typealias FulfillClosure = (value: V) -> Void
    typealias RejectClosure = (reason: NSError) -> Void
    
    // MARK: - ivars
    
    public var state: PromiseState = .Pending
    public var value: V? = nil
    public var reason: NSError? = nil
    
    var fulfillCallbacks: [FulfillClosure] = []
    var rejectCallbacks: [RejectClosure] = []
    
    
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
    public init(resovler: (
        resolve: (value: V) -> Void,
        reject: (reason: NSError) -> Void
        ) -> Void)
    {
        self.init()
        resovler(
            resolve: self.onFulfilled,
            reject: self.onRejected
        )
    }
    
    convenience
    public init<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(thenable: T)
    {
        self.init()
        self.resolve(thenable: thenable)
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
    
    func onFulfilled(value: V) -> Void
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
    
    func onRejected(reason: NSError) -> Void
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
    
    func resolve(#some: Any?)
    {
        if self.state != .Pending {
            return
        }
        
        // TODO: Cast to thenable
        
        switch some {
        case let promise as Promise<V>:
            self.resolve(thenable: promise)
        case let value as V:
            self.resolve(value: value)
        default:
            self.onRejected(NSError.promiseResultTypeError())
        }
    }
    
    func resolve(#value: V)
    {
        if self.state != .Pending {
            return
        }
        
        self.onFulfilled(value)
    }
    
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(#thenable: T)
    {
        if self.state != .Pending {
            return
        }
        
        if (thenable as? Promise<V>) === self {
            self.onRejected(NSError.promiseTypeError())
        }
        else {
            thenable.then(
                onFulfilled: { (value) -> Void in
                    self.onFulfilled(value)
                },
                onRejected: { (reason) -> Void in
                    self.onRejected(reason)
                }
            );
        }
        
    }

    /*
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Optional<Any>>(#thenable: T)
    {
        if self.state != .Pending {
            return
        }
        
        if let promise = thenable as? Promise<V> {
            if promise === self {
                self.onRejected(NSError.promiseTypeError())
            }
        }
        
        thenable.then(
            onFulfilled: { (value: V) -> Any? in
                self.onFulfilled(value)
                return nil
            },
            onRejected: { (reason: NSError) -> Any? in
                self.onRejected(reason)
                return nil
            }
        )
    }
    */
    
    
    func resolve(#promise: Promise<V>) {
        if self.state != .Pending {
            return
        }
        
        // TODO: Check Return cycle
        
        if promise === self {
            self.onRejected(NSError.promiseTypeError())
        }
        else {
            promise.then(
                onFulfilled: { (value) -> Void in
                    self.onFulfilled(value)
                },
                onRejected: { (reason) -> Void in
                    self.onRejected(reason)
                }
            );
        }
    }
    
    // MARK: - Public APIs
    
    public class func resolve(value: Any?) -> Promise<Any?>
    {
        // TODO: Cast to thenable
        
        switch value {
        case let promise as Promise<Any?>:
            return promise
        default:
            return Promise<Any?>(value: value)
        }
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
                    if .Pending == allPromise.state {
                        results.append(value)
                        if results.count >= count {
                            allPromise.onFulfilled(results)
                        }
                    }
                }, onRejected: { (reason) -> Void in
                    if .Pending == allPromise.state {
                        allPromise.onRejected(reason)
                    }
            })
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
                    if .Pending == racePromise.state {
                        racePromise.onFulfilled(value)
                    }
                },
                onRejected: { (reason) -> Void in
                    if .Pending == racePromise.state {
                        racePromise.onRejected(reason)
                    }
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
                    subPromise.resolve(value: nil)
                }
                else {
                    subPromise.onFulfilled(value)
                }
            },
            rejectCallback: { (reason) -> Void in
                
                if let rejection = onRejected? {
                    rejection(reason: reason)
                    subPromise.resolve(value: nil)
                }
                else {
                    subPromise.onRejected(reason)
                }
            }
        );
        
        return subPromise
    }

    
    /*
    public func then(
        onFulfilled: Optional<(value: V) -> Any?> = nil,
        onRejected: Optional<(reason: NSError) -> Any?> = nil
        ) -> Promise<Any?>
    {
        let subPromise = Promise<Any?>()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                if let resolution = onFulfilled? {
                    subPromise.resolve(some: resolution(value: value))
                }
                else {
                    subPromise.onFulfilled(value)
                }
            },
            rejectCallback: { (reason) -> Void in
                if let rejection = onRejected? {
                    subPromise.resolve(some: rejection(reason: reason))
                }
                else {
                    subPromise.onRejected(reason)
                }
            }
        );
        
        return subPromise
    }
    */
    // MARK: - Thenable enhance
    
    public func then(
        onFulfilled: (value: V) -> Void
        ) -> Promise<Any?>
    {
        let subPromise = Promise<Any?>()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                onFulfilled(value: value)
                subPromise.resolve(value: nil)
            },
            rejectCallback: { (reason) -> Void in
                subPromise.onRejected(reason)
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
                subPromise.onFulfilled(value)
            },
            rejectCallback: { (reason) -> Void in
                onRejected(reason: reason)
                subPromise.resolve(value: nil)
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
                subPromise.resolve(value: onFulfilled(value: value))
            },
            rejectCallback: { (reason) -> Void in
                subPromise.resolve(value: onRejected(reason: reason))
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
                subPromise.resolve(value: onFulfilled(value: value))
            },
            rejectCallback: { (reason) -> Void in
                subPromise.onRejected(reason)
            }
        );

        return subPromise
    }

    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError, T.ReturnType == Void>(
        onFulfilled: (value: V) -> T,
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
                subPromise.onRejected(reason)
            }
        );
        
        return subPromise
    }
}