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
    
    
    // MARK: - Thenable

    public func then<N>(
        onFulfilled: Optional<(value: V) -> Promise<N>> = nil,
        onRejected: Optional<(reason: NSError) -> Promise<N>> = nil
        ) -> Promise<N> {
            
            /*
            var subPromise: Promise
            let state = self.state
            let value = self.value
            let reason = self.reason
            
            switch state {
            case .Pending:
                subPromise = self.dynamicType()
            case .Fulfilled:
                subPromise = self.dynamicType(value: value!)
            case .Rejected:
                subPromise = self.dynamicType(reason: reason!)
            }
            
            let then: ThenGroupType = (onFulfilled, onRejected, subPromise)
            self.thens.append(then)
            
            switch state {
            case .Fulfilled:
                break
                //subPromise.resolve(onFulfilled?(value: value))
            case .Rejected:
                break
                //subPromise.resolve(onRejected?(reason: reason))
            default:
                break
            }
            
            return subPromise
            */
            
            
        return Promise<N>()
    }
    
    // MARK: - Thenable enhance
    
    public func then<N>(
        onFulfilled: Optional<(value: V) -> N> = nil,
        onRejected: Optional<(reason: NSError) -> N> = nil
        ) -> Promise<N> {
        return Promise<N>()
    }
    
    public func then(
        onFulfilled: Optional<(value: V) -> Void> = nil,
        onRejected: Optional<(reason: NSError) -> Void> = nil
        ) -> Promise<V> {
            return Promise<V>()
    }
}