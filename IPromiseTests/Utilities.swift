//
//  Utilities.swift
//  IPromise
//
//  Created by William Remaerd on 10/11/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

func ~> (lhs: NSTimeInterval, rhs: @autoclosure () -> Void)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        NSThread.sleepForTimeInterval(lhs)
        dispatch_sync(dispatch_get_main_queue(), rhs)
    })
}

let STRING_VALUE_0 = "STRING_VALUE_0"
let STRING_VALUE_1 = "STRING_VALUE_1"
let STRING_VALUE_2 = "STRING_VALUE_2"
let STRING_VALUE_3 = "STRING_VALUE_3"

let ERROR_0 = NSError.errorWithDomain(" ", code: 0, userInfo: nil)
let ERROR_1 = NSError.errorWithDomain(" ", code: 1, userInfo: nil)
let ERROR_2 = NSError.errorWithDomain(" ", code: 2, userInfo: nil)
let ERROR_3 = NSError.errorWithDomain(" ", code: 3, userInfo: nil)

let VOID_SUMMARY = "()"