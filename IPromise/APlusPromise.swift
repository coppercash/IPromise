//
//  APlusPromise.swift
//  IPromise
//
//  Created by William Remaerd on 9/25/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class APlusPromise: Thenable
{
    // MAKR: ivars
    
    public internal(set) var state: PromiseState = .Pending
    public internal(set) var value: Any?? = nil
    public internal(set) var reason: Any?? = nil

    public typealias FulfillClosure = (value: Any?) -> Void
    public typealias RejectClosure = (reason: Any?) -> Void
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

    convenience
    public init(resolver: (resolve: FulfillClosure, reject: RejectClosure) -> Void)
    {
        self.init()
        resolver(
            resolve: self.resolve,
            reject: self.reject
        )
    }
    
    convenience
    public init<T: Thenable where T.ValueType == Optional<Any>, T.ReasonType == Optional<Any>, T.ReturnType == Optional<Any>>(thenable: T)
    {
        self.init()
        thenable.then(
            onFulfilled: { (value) -> Any? in
                self.resolve(value)
                return nil
            },
            onRejected: { (reason) -> Any? in
                self.reject(reason)
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

    // MARK: - Public APIs

    public func resolve(value: Any?) -> Void
    {
        if self.state != .Pending {
            return
        }
        
        if let promise = value as? APlusPromise {
            if promise === self {
                self.reject(NSError.promiseTypeError())
            }
            else {
                promise.then(
                    onFulfilled: { (value) -> Any? in
                        self.resolve(value)
                        return nil
                    },
                    onRejected: { (reason) -> Any? in
                        self.reject(reason)
                        return nil
                    }
                )
            }
            return
        }
        
        self.value = value
        self.state = .Fulfilled
        
        for callback in self.fulfillCallbacks {
            callback(value: value)
        }
    }

    public func reject(reason: Any?) -> Void
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
    
    public class func resolve(value: Any?) -> APlusPromise
    {
        // TODO: - Downcast to Thenable
        
        switch value {
        case let aPlusPromise as APlusPromise:
            return aPlusPromise
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
                        allPromise.resolve(results)
                    }
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    allPromise.reject(reason)
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
                    racePromise.resolve(value)
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    racePromise.reject(reason)
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
                    subPromise.resolve(value)
                }
            },
            rejectCallback: { (reason) -> Void in
                if let rejection = onRejected? {
                    subPromise.resolve(rejection(reason: reason))
                }
                else {
                    subPromise.reject(reason)
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
                subPromise.reject(reason)
            }
        );
        
        return subPromise
    }
    
    public func catch(onRejected: (reason: Any?) -> Any?) -> Self
    {
        let subPromise = self.dynamicType()
        
        self.bindCallbacks(
            fulfillCallback: { (value) -> Void in
                subPromise.resolve(value)
            },
            rejectCallback: { (reason) -> Void in
                subPromise.resolve(onRejected(reason: reason))
            }
        );
        
        return subPromise
    }
}

public extension APlusPromise {
    convenience
    public init<V>(promise: Promise<V>)
    {
        self.init()
        self.resolve(promise: promise)
    }

    func resolve<V>(#promise: Promise<V>) -> Void
    {
        if self.state != .Pending {
            return
        }

        promise.then(
            onFulfilled: { (value) -> Void in
                self.resolve(value)
            },
            onRejected: { (reason) -> Void in
                self.reject(reason)
            }
        )
    }
}