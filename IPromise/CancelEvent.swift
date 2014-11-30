//
//  CancelEvent.swift
//  IPromise
//
//  Created by William Remaerd on 11/30/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import Foundation

class CancelEvent {
    private var invoked: Bool = false
    var callback: () -> Promise<Void>
    let buffer: Deferred<Void> = Deferred<Void>()
    
    init(callback: () -> Promise<Void>) {
        self.callback = callback
    }
    
    func invoke() {
        if self.invoked == false {
            self.buffer.resolve(thenable: callback(), fraction: 1)
            self.invoked = true
        }
    }
}