//
//  Promise.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class Promise<V>: APlusPromise
{
    // MARK: - Type

    typealias ReturnType = Promise
    typealias ValueType = V
    typealias ReasonType = NSError?

    public typealias Resolution = (value: V) -> Any?
    public typealias Rejection = (reason: NSError?) -> Any?
    public typealias Resovler = (value: V) -> Void
    public typealias Rejector = (reason: NSError?) -> Void

    public var value: V
    
    // MARK: - Initializers

    required
    public init(resovler: (resolve: Resovler, reject: Rejector) -> Void)
    {
        super.init()
        resovler(
            resolve: self.onFulfilled,
            reject: self.onRejected
        )
    }

    required
    public init(value: V)
    {
        super.init(value: value)
    }
    
    
    // MARK: - Inherited Initializers
    
    required
    public init()
    {
        super.init()
    }
    
    required
    public init(value: Any?)
    {
        super.init(value: value)
    }
    
    required
    public init(reason: Any?)
    {
        super.init(reason: reason)
    }

    required
    public init(resovler: (resolve: APlusResovler, reject: APlusRejector) -> Void)
    {
        super.init()
        resovler(
            resolve: self.onFulfilled,
            reject: self.onRejected
        )
    }

    required convenience
    public init<T: Thenable>(thenable: T)
    {
        self.init()
        thenable.then(
            onFulfilled: { (value) -> Any? in
                self.onFulfilled(value)
            },
            onRejected: { (reason) -> Any? in
                self.onRejected(reason)
            }
        )
    }

    
    // MARK: - Public APIs
    /*
    public func then<N>(onFulfilled: (value: V) -> N) -> Promise<N>
    {
        return self.then(
            onFulfilled: (onFulfilled as Resolution),
            onRejected: nil
        ) as Promise<N>
    }
    */
    
    public func catch(onRejected: Rejection) -> Promise<Any?>
    {
        return self.then(
            onFulfilled: nil,
            onRejected: onRejected
        )
    }

    
    // MARK: - Thenable

    
    public func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil) -> Promise<Any?>
    {
        return super.then(onFulfilled: onFulfilled, onRejected: onRejected) as Promise<Any?>
    }
}