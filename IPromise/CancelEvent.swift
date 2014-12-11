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
    
    private var invoked: Bool = false
    private let callback: Callback
    private let buffer: Deferred<Void> = Deferred<Void>()
    
    init(callback: Callback) {
        self.callback = callback
    }
    
    func resolve() {
        if self.invoked == false {
            let cancelPromise = self.callback()
            self.buffer.resolve(thenable: cancelPromise, fraction: 1)
            self.invoked = true
        }
    }
    
    func reject(state: State) {
        self.buffer.reject(NSError.promiseWrongStateError(state: state, to: "cancel"))
    }
    
    var bufferPromise: Promise<Void> {
        return buffer.promise
    }
}