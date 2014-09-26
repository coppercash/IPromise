//
//  APlusPromise.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/25/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public typealias Resovler = (result: Any?) -> Void
public typealias Rejector = (reason: NSError?) -> Void

public class APlusPromise: Thenable
{
    // MARK: - Initializers
    
    public required init(resovler: (resolve: Resovler, reject: Rejector) -> Void)
    {
        resovler(
            resolve: self.resolve,
            reject: self.reject
        )
    }
    
    public convenience required init(thenable: Thenable)
    {
        let resovler = { (resolve: Resovler, reject: Rejector) -> Void in
            
            let onFulfilled = { (result: Any?) -> Any? in
                resolve(result: result)
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
        }
        
        self.init(resovler)
    }
    
    public convenience required init(value: Any?)
    {
        self.init({ (resolve: Resovler, reject: Rejector) -> Void in
            resolve(result: value)
        })
    }
    
    public convenience required init(reason: NSError?)
    {
        self.init({ (resolve: Resovler, reject: Rejector) -> Void in
            reject(reason: reason)
        })
    }
    
    // MARK: - Public APIs

    public class func resolve(value: Any?) -> Self
    {
        return self(value: nil)
    }
    
    public class func reject(reason: Any?) -> Self
    {
        return self(value: nil)
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
    
    public func then(#onFulfilled: Resolution?, onRejected: Rejection?) -> Self
    {
        return self;
    }
    
    public func catch(onRejected: Rejection) -> Self
    {
        return self;
    }
    
    // MARK: -
    
    func resolve(result: Any?) -> Void
    {
        
    }
    
    func reject(reason: Any?) -> Void
    {
        
    }
    
    enum State
    {
        case Pending, Fulfilled, Rejected
    }
}