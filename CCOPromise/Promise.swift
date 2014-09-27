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
        super.init()
        resovler(
            resolve: self.onFulfilled,
            reject: self.onRejected
        )
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
    init()
    {
        super.init()
    }
    
    public required
    init(value: Any?)
    {
        super.init(value: value)
    }
    
    public required
    init(reason: Any?)
    {
        super.init(reason: reason)
    }

    public required
    init(resovler: (resolve: APlusResovler, reject: APlusRejector) -> Void)
    {
        super.init()
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
            },
            onRejected: { (reason) -> Any? in
                self.onRejected(reason)
            }
        )
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