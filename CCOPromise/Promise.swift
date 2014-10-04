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

    public typealias ThenType = Promise
    public typealias ValueType = V
    public typealias ReasonType = NSError?
    public typealias ReturnType = Promise

    public typealias Resolution = (value: V) -> Any?
    public typealias Rejection = (reason: NSError?) -> Any?
    public typealias Resovler = (value: V) -> Void
    public typealias Rejector = (reason: NSError?) -> Void

    public var value: V?
    
    // MARK: - Initializers
    public init()
    {
        //self.value = nil
    }
    
    public init(value: V)
    {
    }
    
    convenience
    public init<V, T: Thenable where T.ValueType == V, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(thenable: T)
    {
        self.init()
        thenable.then(
            onFulfilled: { (value) -> Any? in

                return nil
            },
            onRejected: { (reason) -> Any? in

                return nil
            }
        )
    }
    
/*
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
*/
    
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
    /*
    public func catch(onRejected: Rejection) -> Promise<Any?>
    {
        return self.then(
            onFulfilled: nil,
            onRejected: onRejected
        )
    }
*/
    
    // MARK: - Thenable

    public func then<T>(
        onFulfilled: Optional<(value: V) -> Promise<T>> = nil,
        onRejected: Optional<(reason: NSError?) -> Promise<T>> = nil
        ) -> Promise<T> {
        return Promise<T>()
    }
    
    public func then<T>(
        onFulfilled: Optional<(value: V) -> T> = nil,
        onRejected: Optional<(reason: NSError?) -> T> = nil
        ) -> Promise<T> {
        return Promise<T>()
    }
    
    public func then<V>(
        onFulfilled: Optional<(value: V) -> Void> = nil,
        onRejected: Optional<(reason: NSError?) -> Void> = nil
        ) -> Promise<V> {
            return Promise<V>()
    }

    /*
    public func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil) -> Promise<Any?>
    {
        return super.then(onFulfilled: onFulfilled, onRejected: onRejected) as Promise<Any?>
    }
*/
}