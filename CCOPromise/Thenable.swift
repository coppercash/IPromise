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
    typealias ReturnType
    
    func then(#onFulfilled: Optional<(value: ValueType) -> ReturnType>, onRejected: Optional<(reason: ReasonType) -> ReturnType>) -> NextType
}