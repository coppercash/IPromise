//
//  APlusPromise.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/25/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public typealias Resovler = (value: Any?) -> Void
public typealias Rejector = (reason: NSError?) -> Void

public class APlusPromise: Thenable
{
    var value: Any?
    var reason: NSError?
    
    // MARK: - Initializers
    
    public required init(resovler: (resolve: Resovler, reject: Rejector) -> Void)
    {
        resovler(
            resolve: self.resolve,
            reject: self.reject
        )
    }
    
    public required convenience init(thenable: Thenable)
    {
        self.init({ (resolve: Resovler, reject: Rejector) -> Void in
            
            let onFulfilled = { (value: Any?) -> Any? in
                resolve(value: value)
                return nil
            }
            
            let onRejected = { (reason: NSError?) -> Any? in
                reject(reason: reason)
                return nil
            }
            
            thenable.then(
                onFulfilled: onFulfilled,
                onRejected: onRejected
            )
        })
    }
    
    public required convenience init(value: Any?)
    {
        self.init({ (resolve: Resovler, reject: Rejector) -> Void in
            resolve(value: value)
        })
    }
    
    public required convenience init(reason: NSError?)
    {
        self.init({ (resolve: Resovler, reject: Rejector) -> Void in
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
    
    public class func reject(reason: NSError?) -> Self
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
    
    public func then(#onFulfilled: Resolution?, onRejected: Rejection?) -> Thenable
    {
        return self;
    }
    
    public func catch(onRejected: Rejection) -> Thenable
    {
        return self;
    }
    
    // MARK: -
    
    func resolve(value: Any?) -> Void
    {
        
    }
    
    func reject(reason: NSError?) -> Void
    {
        
    }
    
    enum State
    {
        case Pending, Fulfilled, Rejected
    }
}