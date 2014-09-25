//
//  APlusPromise.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/25/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public typealias Resovler = (value: Any?) -> Void
public typealias Rejector = (value: Any?) -> Void

public class APlusPromise: Thenable
{
    public required init(resovler: (resolve: Resovler, reject: Rejector) -> Void)
    {
        
    }
    
    public required init(thenable: Thenable)
    {
        
    }
    
    public required init(value: Any?)
    {
        
    }
    
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
    
    public func then(onFulfilled: Resolution) -> Self
    {
        return self;
    }
    
    public func catch(onRejected: Rejection) -> Self
    {
        return self;
    }
}