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
    // MARK: - Initializers

    public required init(resovler: (resolve: Resovler, reject: Rejector) -> Void)
    {
        super.init(resovler: resovler)
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

    public required convenience init(value: V)
    {
        self.init({ (resolve: Resovler, reject: Rejector) -> Void in
            resolve(value: value)
        })
    }

    func then(onFulfilled: Resolution) -> Self
    {
        return self
    }
}