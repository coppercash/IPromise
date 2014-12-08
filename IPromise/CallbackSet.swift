//
//  CallbackSet.swift
//  IPromise
//
//  Created by William Remaerd on 11/20/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

struct CallbackSet<V>: Equatable {
    
    typealias Fulfill = (value: V) -> Void
    typealias Reject = (reason: NSError) -> Void
    typealias Progress = (progress: Float) -> Void
    
    let identifier: String = NSProcessInfo.processInfo().globallyUniqueString
    
    let fulfill: Fulfill
    let reject: Reject
    let progress: Progress
    
    init(
        fulfill: Fulfill,
        reject: Reject,
        progress: Progress
        ) {
            self.fulfill = fulfill
            self.reject = reject
            self.progress = progress
    }
    
}

func ==<V>(lhs: CallbackSet<V>, rhs: CallbackSet<V>) -> Bool {
    return lhs.identifier == rhs.identifier
}