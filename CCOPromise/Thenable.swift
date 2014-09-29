//
//  Thenable.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation
/*
public typealias Resolution = (value: Any?) -> Any?
public typealias Rejection = (reason: Any?) -> Any?
*/
public protocol Thenable
{
    typealias ReturnType
    typealias ValueType
    typealias ReasonType
    
    func then(#onFulfilled: ((value: ValueType) -> Any?)?, onRejected: ((reason: ReasonType) -> Any?)?) -> ReturnType
}