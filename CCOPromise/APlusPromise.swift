//
//  APlusPromise.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/25/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class APlusPromise: Thenable
{
    // MARK: - Type

    public typealias FulfillClosure = (value: Any?) -> Void
    public typealias RejectClosure = (reason: Any?) -> Void

    // MAKR: ivars
    
    public internal(set) var state: PromiseState = .Pending
    public internal(set) var value: Any?? = nil
    public internal(set) var reason: Any?? = nil

    lazy var fulfillCallbacks: [FulfillClosure] = []
    lazy var rejectCallbacks: [RejectClosure] = []

    // MARK: - Initializers
    
    required
    public init() {}
    
    required
    public init(value: Any?)
    {
        self.value = value
        self.state = .Fulfilled
    }
    
    required
    public init(reason: Any?)
    {
        self.reason = reason
        self.state = .Rejected
    }

    required convenience
    public init(resolver: (resolve: FulfillClosure, reject: RejectClosure) -> Void)
    {
        self.init()
        resolver(
            resolve: self.onFulfilled,
            reject: self.onRejected
        )
    }
    
    convenience
    public init<T: Thenable where T.ValueType == Optional<Any>, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(thenable: T)
    {
        self.init()
        thenable.then(
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

    func onFulfilled(value: Any?) -> Void
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
    
    func onRejected(reason: Any?) -> Void
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
    
    func resolve(value: Any?)
    {
        if self.state != .Pending {
            return
        }
        
        switch value {
        case let promise as APlusPromise:
            if promise === self {
                self.onRejected(NSError.promiseTypeError())
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

    // MARK: - Public APIs

    public class func resolve(value: Any?) -> APlusPromise
    {
        switch value {
        case let promise as APlusPromise:
            return promise
        default:
            return self(value: value)
        }
    }
    
    public class func reject(reason: Any?) -> Self
    {
        return self(reason: reason)
    }
    
    public class func all(values: Any?...) -> Self
    {
        let allPromise = self()
        let count = values.count
        var results: [Any?] = []

        for value in values
        {
            let promise = self.resolve(value)
            promise.then(
                onFulfilled: { (value) -> Any? in
                    results.append(value)
                    if results.count >= count {
                        allPromise.onFulfilled(results)
                    }
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    allPromise.onRejected(reason)
                    return nil
                }
            )
        }
        
        return allPromise
    }
    
    public class func race(values: Any?...) -> Self
    {
        let racePromise = self()
        
        for value in values
        {
            let promise = self.resolve(value)
            promise.then(
                onFulfilled: { (value) -> Any? in
                    racePromise.onFulfilled(value)
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    racePromise.onRejected(reason)
                    return nil
                }
            )
        }

        return racePromise
    }
    
    // MARK: - Thenable
    
    typealias NextType = APlusPromise
    typealias ValueType = Any?
    typealias ReasonType = Any?
    typealias ReturnType = Any?

    public func then(onFulfilled: Optional<(value: Any?) -> Any?> = nil, onRejected: Optional<(reason: Any?) -> Any?> = nil) -> Self
    {
        let subPromise = self.dynamicType()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                if let resolution = onFulfilled? {
                    subPromise.resolve(resolution(value: value))
                }
                else {
                    subPromise.onFulfilled(value)
                }
            },
            rejectCallback: { (reason) -> Void in
                if let rejection = onRejected? {
                    subPromise.resolve(rejection(reason: reason))
                }
                else {
                    subPromise.onRejected(reason)
                }
            }
        );
        
        return subPromise
    }
    
    public func then(onFulfilled: (value: Any?) -> Any?) -> Self
    {
        let subPromise = self.dynamicType()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                subPromise.resolve(onFulfilled(value: value))
            },
            rejectCallback: { (reason) -> Void in
                subPromise.onRejected(reason)
            }
        );
        
        return subPromise
    }
    
    public func catch(onRejected: (reason: Any?) -> Any?) -> Self
    {
        let subPromise = self.dynamicType()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                subPromise.onFulfilled(value)
            },
            rejectCallback: { (reason) -> Void in
                subPromise.resolve(onRejected(reason: reason))
            }
        );
        
        return subPromise
    }
}