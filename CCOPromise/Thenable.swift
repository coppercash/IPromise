//
//  Thenable.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

public protocol Thenable
{
    typealias ThenType
    typealias ValueType
    typealias ReasonType
    typealias ReturnType
    
    func then(#onFulfilled: ((value: ValueType) -> ReturnType)?, onRejected: ((reason: ReasonType) -> ReturnType)?) -> ThenType
}