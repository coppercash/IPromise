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
    typealias NextType
    typealias ValueType
    typealias ReasonType
    
    func then(#onFulfilled: ((value: ValueType) -> Any?)?, onRejected: ((reason: ReasonType) -> Any?)?) -> NextType
}