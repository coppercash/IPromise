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

    public typealias NextType = Promise
    public typealias ValueType = V
    public typealias ReasonType = NSError
    public typealias ReturnType = Void

    public typealias FulfillClosure = (value: V) -> Any?
    public typealias RejectClosure = (reason: NSError?) -> Any?
    public typealias Resovler = (value: V) -> Void
    public typealias Rejector = (reason: NSError) -> Void
    
    typealias ThenGroupType = (
        resolution: FulfillClosure?,
        rejection: RejectClosure?,
        subPromise: Promise
    )
    
    // MARK: - ivars
    
    public var state: PromiseState = .Pending
    public var value: V? = nil
    public var reason: NSError? = nil
    
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
    public init<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(voidThenable: T)
    {
        self.init()
        self.resolve(voidThenable: voidThenable)
    }
    
    convenience
    public init<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Optional<Any>>(thenable: T)
    {
        self.init()
        self.resolve(thenable: thenable)
    }

    
    // MARK: - Private APIs
    
    func onFulfilled(value: V) -> Void
    {
        if self.state != .Pending {
            return
        }
        
        self.value = value
        self.state = .Fulfilled
        
        /*
        for then in self.thens
        {
            let subPromise = then.subPromise
            if let resolution = then.resolution?
            {
                let output = resolution(value: value)
                subPromise.resolve(output)
            }
            else
            {
                subPromise.onFulfilled(value)
            }
        }
*/
    }
    
    func onRejected(reason: NSError) -> Void
    {
        if self.state != .Pending {
            return
        }
        
        self.reason = reason
        self.state = .Rejected
        /*
        for then in self.thens
        {
            let subPromise = then.subPromise
            if let rejection = then.rejection?
            {
                let value = rejection(reason: reason)
                subPromise.resolve(value)
            }
            else
            {
                subPromise.onRejected(value)
            }
        }
*/
    }
    
    // TODO: Think if remove this
    func resolve(#some: Any?)
    {
        if self.state != .Pending {
            return
        }

        switch some {
        case let promise as Promise<V>:
            self.resolve(voidThenable: promise)
        case let value as V:
            self.resolve(value: value)
        default:
            self.onFulfilled(some! as V)
        }
    }
    
    func resolve(#value: V)
    {
        if self.state != .Pending {
            return
        }
        
        self.onFulfilled(value)
    }
/*
    func resolve(#promise: Promise)
    {
        if self.state != .Pending {
            return
        }

        if promise === self {
            self.onRejected(NSError.aPlusPromiseTypeError())    // TODO: Replace aPlusPromiseTypeError
        }
        else {
            promise.then(
                onFulfilled: { (value) -> Void in
                    self.onFulfilled(value)
                },
                onRejected: { (reason) -> Void in
                    self.onRejected(reason)
                }
            )
        }
    }
    */
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Void>(#voidThenable: T)
    {
        if self.state != .Pending {
            return
        }

        if (voidThenable as? Promise<V> === self) {
            self.onRejected(NSError.aPlusPromiseTypeError())    // TODO: Replace aPlusPromiseTypeError
        }
        else {
            voidThenable.then(
                onFulfilled: { (value: V) -> Void in
                    self.onFulfilled(value)
                },
                onRejected: { (reason: NSError) -> Void in
                    self.onRejected(reason)
                }
            )
        }
    }
    
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Optional<Any>>(#thenable: T)
    {
        if self.state != .Pending {
            return
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

    // MARK: - Thenable

    public func then<N>(
        onFulfilled: Optional<(value: V) -> Promise<N>> = nil,
        onRejected: Optional<(reason: NSError) -> Promise<N>> = nil
        ) -> Promise<N> {
            
            let subPromise = Promise<N>()
            
            
            return subPromise
    }
    /*
    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError, T.ReturnType == T>(
        onFulfilled: Optional<(value: V) -> T> = nil,
        onRejected: Optional<(reason: NSError) -> T> = nil
        ) -> T {
            
            let subPromise = Promise<N>()
            
            
            return subPromise
    }
    */
    
    // MARK: - Thenable enhance
    
    public func then<N>(
        onFulfilled: Optional<(value: V) -> N> = nil,
        onRejected: Optional<(reason: NSError) -> N> = nil
        ) -> Promise<N>
    {
        let subPromise = Promise<N>()
        
        switch self.state {
        case .Fulfilled:
            if let resolution = onFulfilled? {
                subPromise.resolve(value: resolution(value: self.value!))
            }
            else {
                subPromise.onFulfilled(self.value! as N)
            }
        case .Rejected:
            if let rejection = onRejected? {
                subPromise.resolve(value: rejection(reason: self.reason!))
            }
            else {
                subPromise.onRejected(self.reason!)
            }
        default:
            break
        }

        return subPromise
    }
    
    public func then(
        onFulfilled: Optional<(value: V) -> Void> = nil,
        onRejected: Optional<(reason: NSError) -> Void> = nil
        ) -> Promise<V> {
            return Promise<V>()
    }
}