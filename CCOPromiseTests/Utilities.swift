//
//  Utilities.swift
//  CCOPromise
//
//  Created by William Remaerd on 10/11/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

infix operator ~> {}
func ~> (lhs: @autoclosure () -> Any, rhs: @autoclosure () -> ())
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        lhs();
        dispatch_sync(dispatch_get_main_queue(), rhs)
    })
}
