//
//  Thenable.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public typealias Resolution = (result: Any?) -> Any?
public typealias Rejection = (reason: NSError?) -> Any?

public protocol Thenable
{
    func then(#onFulfilled: Resolution?, onRejected: Rejection?) -> Thenable
    func catch(onRejected: Rejection) -> Thenable
}