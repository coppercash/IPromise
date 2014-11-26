//
//  CallbackSet.swift
//  IPromise
//
//  Created by William Remaerd on 11/20/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

struct CallbackSet<V, R>: Equatable {
    let identifier: String = NSProcessInfo.processInfo().globallyUniqueString
    let fulfillCallback: (value: V) -> Void
    let rejectCallback: (reason: R) -> Void
    let progressCallback: (progress: Float) -> Void
    
    init(
        fulfillCallback: (value: V) -> Void,
        rejectCallback: (reason: R) -> Void,
        progressCallback: (progress: Float) -> Void)
    {
        self.fulfillCallback = fulfillCallback
        self.rejectCallback = rejectCallback
        self.progressCallback = progressCallback
    }
}

func ==<V, R>(lhs: CallbackSet<V, R>, rhs: CallbackSet<V, R>) -> Bool {
    return lhs.identifier == rhs.identifier
}