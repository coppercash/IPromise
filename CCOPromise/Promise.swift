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
    
    public typealias NextType = Promise<Any?>
    public typealias ValueType = V
    public typealias ReasonType = NSError
    
    public typealias FulfillClosure = (value: V) -> Any?
    public typealias RejectClosure = (reason: NSError?) -> Any?
    
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
    public init<T: Thenable where T.ValueType == V, T.ReasonType == NSError>(thenable: T)
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
    
    func resolve<T: Thenable where T.ValueType == V, T.ReasonType == NSError>(#thenable: T)
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
    
    public func then(
        onFulfilled: Optional<(value: V) -> Any?> = nil,
        onRejected: Optional<(reason: NSError) -> Any?> = nil
        ) -> Promise<Any?>
    {
        let subPromise = Promise<Any?>()
        
        switch self.state {
        case .Fulfilled:
            if let resolution = onFulfilled? {
                subPromise.resolve(some: resolution(value: self.value!))
            }
            else {
                subPromise.onFulfilled(self.value!)
            }
        case .Rejected:
            if let rejection = onRejected? {
                subPromise.resolve(some: rejection(reason: self.reason!))
            }
            else {
                subPromise.onRejected(self.reason!)
            }
        default:
            break
        }
        
        return subPromise
    }
    
    // MARK: - Thenable enhance
    
    public func then(
        onFulfilled: Optional<(value: V) -> Void> = nil,
        onRejected: Optional<(reason: NSError) -> Void> = nil
        ) -> Self
    {
        let subPromise = self.dynamicType()
        
        switch self.state {
        case .Fulfilled:
            let value: V = self.value!
            onFulfilled?(value: value)
            subPromise.onFulfilled(value)
        case .Rejected:
            let reason: NSError = self.reason!
            onRejected?(reason: reason)
            subPromise.onRejected(reason)
        default:
            break
        }
        
        return subPromise
    }
    
    public func then(
        onFulfilled: (value: V) -> Void
        ) -> Self
    {
        let subPromise = self.dynamicType()
        
        switch self.state {
        case .Fulfilled:
            let value: V = self.value!
            onFulfilled(value: value)
            subPromise.onFulfilled(value)
        case .Rejected:
            subPromise.onRejected(self.reason!)
        default:
            break
        }
        
        return subPromise
    }
    
    public func then<N>(
        #onFulfilled: (value: V) -> N,
        onRejected: (reason: NSError) -> N
        ) -> Promise<N>
    {
        let subPromise = Promise<N>()
        
        switch self.state {
        case .Fulfilled:
            subPromise.resolve(value: onFulfilled(value: self.value!))
        case .Rejected:
            subPromise.resolve(value: onRejected(reason: self.reason!))
        default:
            break
        }
        
        return subPromise
    }
    
    public func then<N>(
        onFulfilled: (value: V) -> N
        ) -> Promise<N>
    {
        let subPromise = Promise<N>()
        
        switch self.state {
        case .Fulfilled:
            subPromise.resolve(value: onFulfilled(value: self.value!))
        case .Rejected:
            subPromise.onRejected(self.reason!)
        default:
            break
        }
        
        return subPromise
    }
    /*
    public func then<N>(
    #onFulfilled: (value: V) -> Promise<N>,
    onRejected: (reason: NSError) -> Promise<N>
    ) -> Promise<N>
    {
    let subPromise = Promise<N>()
    
    switch self.state {
    case .Fulfilled:
    subPromise.resolve(thenable: onFulfilled(value: self.value!))
    case .Rejected:
    subPromise.resolve(thenable: onRejected(reason: self.reason!))
    default:
    break
    }
    
    return subPromise
    }
    
    public func then<N>(
    onFulfilled: (value: V) -> Promise<N>
    ) -> Promise<N>
    {
    let subPromise = Promise<N>()
    
    switch self.state {
    case .Fulfilled:
    subPromise.resolve(thenable: onFulfilled(value: self.value!))
    case .Rejected:
    subPromise.onRejected(self.reason!)
    default:
    break
    }
    
    return subPromise
    }
    */
    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError>(
        onFulfilled: (value: V) -> T,
        onRejected: (reason: NSError) -> T
        ) -> Promise<N>
    {
        let subPromise = Promise<N>()
        
        switch self.state {
        case .Fulfilled:
            subPromise.resolve(thenable: onFulfilled(value: self.value!))
        case .Rejected:
            subPromise.resolve(thenable: onRejected(reason: self.reason!))
        default:
            break
        }
        
        return subPromise
    }
    
    public func then<N, T: Thenable where T.ValueType == N, T.ReasonType == NSError>(
        onFulfilled: (value: V) -> T
        ) -> Promise<N>
    {
        let subPromise = Promise<N>()
        
        switch self.state {
        case .Fulfilled:
            subPromise.resolve(thenable: onFulfilled(value: self.value!))
        case .Rejected:
            subPromise.onRejected(self.reason!)
        default:
            break
        }
        
        return subPromise
    }
    
    public func catch(
        onRejected: (reason: NSError) -> Void
        ) -> Self
    {
        return self.then(onFulfilled: nil, onRejected: onRejected)
    }
}