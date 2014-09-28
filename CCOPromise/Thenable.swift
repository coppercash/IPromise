//
//  Thenable.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public typealias Resolution = (value: Any?) -> Any?
public typealias Rejection = (reason: Any?) -> Any?

public protocol Thenable
{
    func then(#onFulfilled: Resolution?, onRejected: Rejection?) -> Thenable
}