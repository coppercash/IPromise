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
    
    typealias NextType = APlusPromise
    typealias ValueType = Any?
    typealias ReasonType = Any?
    
    public typealias APlusResolution = (value: Any?) -> Any?
    public typealias APlusRejection = (reason: Any?) -> Any?
    public typealias APlusResovler = (value: Any?) -> Void
    public typealias APlusRejector = (reason: Any?) -> Void
    
    typealias ThenGroupType = (
        resolution: APlusResolution?,
        rejection: APlusRejection?,
        subPromise: APlusPromise
    )
    
    public enum State: Printable {
        case Pending, Fulfilled, Rejected
        
        public var description: String {
            switch self {
            case .Pending:
                return "Pending"
            case .Fulfilled:
                return "Fulfilled"
            case .Rejected:
                return "Rejected"
                }
        }
    }

    // MAKR: ivars
    
    public internal(set) var state: State
    public internal(set) var value: Any?
    public internal(set) var reason: Any?
    var thens: [ThenGroupType] = []
    
    // MARK: - Initializers
    
    required
    public init()
    {
        self.value = nil
        self.reason = nil
        self.state = .Pending
    }
    
    required
    public init(value: Any?)
    {
        self.value = value
        self.reason = nil
        self.state = .Fulfilled
    }
    
    required
    public init(reason: Any?)
    {
        self.value = nil
        self.reason = reason
        self.state = .Rejected
    }

    required convenience
    public init(resovler: (resolve: APlusResovler, reject: APlusRejector) -> Void)
    {
        self.init()
        resovler(
            resolve: self.onFulfilled,
            reject: self.onRejected
        )
    }
    
    required convenience
    public init<T: Thenable where T.ValueType == Optional<Any>, T.ReasonType == Optional<Any>>(thenable: T)
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
            return
        }
        
        self.value = value
        self.state = .Fulfilled
        
        for then in self.thens
        {
            let subPromise = then.subPromise
            if let resolution = then.resolution? {
                subPromise.resolve(resolution(value: value))
            }
            else {
                subPromise.onFulfilled(value)
            }
        }
    }
    
    func onRejected(reason: Any?) -> Void
    {
        if self.state != .Pending {
            return
        }
        
        self.reason = reason
        self.state = .Rejected
        
        for then in self.thens
        {
            let subPromise = then.subPromise
            if let rejection = then.rejection? {
                subPromise.resolve(rejection(reason: reason))
            }
            else {
                subPromise.onRejected(value)
            }
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
    
    public class func race(values: Any?...) -> Self
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

        return racePromise
    }
    
    public func catch(onRejected: APlusRejection) -> Self
    {
        return self.then(
            onFulfilled: nil,
            onRejected: onRejected
        )
    }

    // MARK: - Thenable
    
    public func then(onFulfilled: APlusResolution? = nil, onRejected: APlusRejection? = nil) -> Self
    {
        let subPromise = self.dynamicType()
        
        let then: ThenGroupType = (onFulfilled, onRejected, subPromise)
        self.thens.append(then)
        
        switch self.state {
        case .Fulfilled:
            if let resolution = onFulfilled? {
                subPromise.resolve(resolution(value: self.value))
            }
            else {
                subPromise.onFulfilled(self.value)
            }
        case .Rejected:
            if let rejection = onRejected? {
                subPromise.resolve(rejection(reason: self.reason))
            }
            else {
                subPromise.onRejected(self.reason)
            }
        default:
            break
        }
        
        return subPromise
    }
}
/* Remove
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
*/
/* Remove
internal extension NSException {
    class func aPlusPromiseStateTransitionException() -> Self {
        return self(
            name: "APlusPromiseStateTransitionException",
            reason: "Promise has already been fulfilled or rejected. Transition to any other state is forbidden.",
            userInfo: nil
        )
    }
}
*/