//
//  CancelEvent.swift
//  IPromise
//
//  Created by William Remaerd on 11/30/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

class CancelEvent {
    typealias Callback = () -> Promise<Void>
    
    internal var invoked: Bool = false
    internal let callback: Callback
    
    init(callback: Callback) {
        self.callback = callback
    }

    internal
    func invoke() -> Promise<Void> {
        self.invoked = true
        return callback()
    }
}