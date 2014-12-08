//
//  CancelEvent.swift
//  IPromise
//
//  Created by William Remaerd on 11/30/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

class CancelEvent {
    typealias Callback = () -> Promise<Void>?
    
    private var invoked: Bool = false
    var callback: Callback
    let buffer: Deferred<Void> = Deferred<Void>()
    
    init(callback: Callback) {
        self.callback = callback
    }
    
    func invoke() {
        if self.invoked == false {
            if let promise = callback()? {
                self.buffer.resolve(thenable: promise, fraction: 1)
            }
            else {
                self.buffer.resolve()
            }
            self.invoked = true
        }
    }
}