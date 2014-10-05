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
    public typealias ReturnType = Promise

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
    public init<T: Thenable where T.ValueType == V, T.ReasonType == NSError, T.ReturnType == Optional<Any>>(thenable: T)
    {
        self.init()
        
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
    
    func resolve(value: V)
    {
        if self.state != .Pending {
            return
        }
        
        switch value {
        case let promise as APlusPromise:
            if promise === self {
                self.onRejected(NSError.aPlusPromiseTypeError())
            }
            else {
                promise.then(
                    onFulfilled: { (value) -> Any? in
                        self.onFulfilled(value)
                        return nil
                    },
                    onRejected: { (reason) -> Any? in
                        self.onRejected(reason)
                        return nil
                    }
                )
            }
        default:
            self.onFulfilled(value)
        }
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
            let output = onFulfilled?(value: self.value!)
            
                subPromise.resolve(output!)
        case .Rejected:
            if let onRejected = onRejected {
                subPromise.resolve(onRejected(reason: self.reason!))
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