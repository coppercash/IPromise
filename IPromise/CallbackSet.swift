//
//  CallbackSet.swift
//  IPromise
//
//  Created by William Remaerd on 11/20/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

struct CallbackSet<V, R> {
    let fulfillCallback: (value: V) -> Void
    let rejectCallback: (reason: R) -> Void
    let progressCallback: (progress: Float) -> Void
}