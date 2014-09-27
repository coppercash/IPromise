//
//  Promise.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public class Promise<V>: APlusPromise
{
    public typealias Resovler = (value: V) -> Void
    public typealias Rejector = APlusRejector

    // MARK: - Initializers

    public required
    init(resovler: (resolve: Resovler, reject: Rejector) -> Void)
    {
        super.init(resovler: resovler)
    }

    public required convenience
    init(value: V)
    {
        self.init(resovler: { (resolve: Resovler, reject: Rejector) -> Void in
            resolve(value: value)
        })
    }
    
    
    // MARK: - Inherited Initializers
    
    public required
    init(resovler: (resolve: APlusResovler, reject: APlusRejector) -> Void)
    {
        super.init(resovler: resovler)
    }

    public required convenience
    init(thenable: Thenable)
    {
        self.init({ (resolve: APlusResovler, reject: APlusRejector) -> Void in
            
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

    public required convenience
    init(value: Any?)
    {
        self.init(resovler: { (resolve: APlusResovler, reject: APlusRejector) -> Void in
            resolve(value: value)
        })
    }

    
    // MARK: - Public APIs

    public
    func then(onFulfilled: (value: V) -> Any?) -> Thenable
    {
        return self.then(
            onFulfilled: { (value) -> Any? in
                onFulfilled(value: (value as V))
            },
            onRejected: nil)
    }
}