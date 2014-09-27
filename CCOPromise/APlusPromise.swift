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
    var state: State = .Pending
    var value: Any? = nil
    var reason: Any? = nil
    lazy var resolutions: [Resolution] = []
    lazy var rejections: [Rejection] = []
    
    // MARK: - Initializers
    
    public required
    init(resovler: (resolve: APlusResovler, reject: APlusRejector) -> Void)
    {
        resovler(
            resolve: self.resolve,
            reject: self.reject
        )
    }
    
    public required convenience
    init(thenable: Thenable)
    {
        self.init({ (resolve: APlusResovler, reject: APlusRejector) -> Void in
            
            let onFulfilled = { (value: Any?) -> Any? in
                resolve(value: value)
                return nil
            }
            
            let onRejected = { (reason: Any?) -> Any? in
                reject(reason: reason)
                return nil
            }
            
            thenable.then(
                onFulfilled: onFulfilled,
                onRejected: onRejected
            )
        })
    }
    
    public required convenience
    init(value: Any?)
    {
        self.init({ (resolve: APlusResovler, reject: APlusRejector) -> Void in
            resolve(value: value)
        })
    }
    
    public required convenience
    init(reason: Any?)
    {
        self.init({ (resolve: APlusResovler, reject: APlusRejector) -> Void in
            reject(reason: reason)
        })
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
        return self(value: nil)
    }
    
    public class func race(values: [Any?]) -> Self
    {
        return self(value: nil)
    }
    
    // MARK: - Thenable
    
    public func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil) -> Thenable
    {
        return self;
    }
    
    public func catch(onRejected: Rejection) -> Thenable
    {
        return self.then(
            onFulfilled: nil,
            onRejected: onRejected
        );
    }
    
    // MARK: -
    
    func resolve(value: Any?) -> Void
    {
        if self.state != .Pending {
            abort()
        }
        
        self.value = value
        self.state = .Fulfilled
        
        for resolution in self.resolutions {
            resolution(value: value)
        }
    }
    
    func reject(reason: Any?) -> Void
    {
        if self.state != .Pending {
            abort()
        }

        self.reason = reason
        self.state = .Rejected
        
        for rejection in self.rejections {
            rejection(reason: reason)
        }
    }
    
    // MARK: -

    public typealias APlusResovler = (value: Any?) -> Void
    public typealias APlusRejector = (reason: Any?) -> Void

    enum State
    {
        case Pending, Fulfilled, Rejected
    }
}