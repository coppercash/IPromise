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
    
    public typealias APlusResovler = (value: Any?) -> Void
    public typealias APlusRejector = (reason: Any?) -> Void
    
    public enum State {
        case Pending, Fulfilled, Rejected
    }

    // MAKR: ivars
    
    public private(set) var state: State
    public private(set) var value: Any?
    public private(set) var reason: Any?
    var thens: [(resolution: Resolution?, rejection: Rejection?, subPromise: APlusPromise)] = []
    
    // MARK: - Initializers
    
    public required
    init()
    {
        self.value = nil
        self.reason = nil
        self.state = .Pending
    }
    
    public required
    init(value: Any?)
    {
        self.value = value
        self.reason = nil
        self.state = .Fulfilled
    }
    
    public required
    init(reason: Any?)
    {
        self.value = nil
        self.reason = reason
        self.state = .Rejected
    }

    public required convenience
    init(resovler: (resolve: APlusResovler, reject: APlusRejector) -> Void)
    {
        self.init()
        resovler(
            resolve: self.onFulfilled,
            reject: self.onRejected
        )
    }
    
    public required convenience
    init(thenable: Thenable)
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
    
    func onFulfilled(value: Any?) -> Void
    {
        if self.state != .Pending {
            NSException.aPlusPromiseStateTransitionException().raise()
        }
        
        self.value = value
        self.state = .Fulfilled
        
        for then in self.thens
        {
            let subPromise = then.subPromise
            if let resolution = then.resolution?
            {
                let value = resolution(value: value)
                subPromise.resolve(value)
            }
            else
            {
                subPromise.onFulfilled(value)
            }
        }
    }
    
    func onRejected(reason: Any?) -> Void
    {
        if self.state != .Pending {
            NSException.aPlusPromiseStateTransitionException().raise()
        }
        
        self.reason = reason
        self.state = .Rejected
        
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
    }
    
    func resolve(value: Any?)
    {
        if self.state != .Pending {
            NSException.aPlusPromiseStateTransitionException().raise()
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
    
    public class func all(values: [Any?]) -> Self
    {
        let allPromise = self()
        let count = values.count
        var results: [Any?] = []

        for value in values
        {
            let promise = self.resolve(value)
            promise.then(
                onFulfilled: { (value) -> Any? in
                    if .Pending == allPromise.state {
                        results.append(value)
                        if results.count >= count {
                            allPromise.onFulfilled(results)
                        }
                    }
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    if .Pending == allPromise.state {
                        allPromise.onRejected(reason)
                    }
                    return nil
                }
            )
        }
        
        return allPromise
    }
    
    public class func race(values: [Any?]) -> Self
    {
        let racePromise = self()
        
        for value in values
        {
            let promise = self.resolve(value)
            promise.then(
                onFulfilled: { (value) -> Any? in
                    if .Pending == racePromise.state {
                        racePromise.onFulfilled(value)
                    }
                    return nil
                },
                onRejected: { (reason) -> Any? in
                    if .Pending == racePromise.state {
                        racePromise.onRejected(reason)
                    }
                    return nil
                }
            )
        }

        return self(value: nil)
    }
    
    public func catch(onRejected: Rejection) -> Thenable
    {
        return self.then(
            onFulfilled: nil,
            onRejected: onRejected
        )
    }

    // MARK: - Thenable
    
    public func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil) -> Thenable
    {
        var subPromise: APlusPromise
        
        switch self.state {
        case .Pending:
            subPromise = self.dynamicType()
        case .Fulfilled:
            subPromise = self.dynamicType(value: self.value)
        case .Rejected:
            subPromise = self.dynamicType(reason: self.reason)
        }
        
        let then: (resolution: Resolution?, rejection: Rejection?, subPromise: APlusPromise) = (onFulfilled, onRejected, subPromise)
        self.thens.append(then)
        
        return subPromise
    }
}

public let APlusPromiseTypeError = 1000
public extension NSError {
    class func aPlusPromiseTypeError() -> Self {
        return self(
            domain: "APlusPromiseErrorDomain",
            code: APlusPromiseTypeError,
            userInfo: [NSLocalizedDescriptionKey: "TypeError"]
        )
    }
}

public extension NSException {
    class func aPlusPromiseStateTransitionException() -> Self {
        return self(
            name: "APlusPromiseStateTransitionException",
            reason: "Promise has already been fulfilled or rejected. Transition to any other state is forbidden.",
            userInfo: nil
        )
    }
}