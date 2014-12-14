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
    
    static func makeFulfill(
        deferred: Deferred<V>,
        useDefault: Bool = true,
        fulfill: Fulfill? = nil
        ) -> Fulfill {
        return !useDefault ? fulfill! : { (value: V) -> Void in deferred.resolve(value) }
    }
    
    static func makeReject<N>(
        deferred: Deferred<N>,
        useDefault: Bool = true,
        reject: Reject? = nil
        ) -> Reject {
        return !useDefault ? reject! : { (reason: NSError) -> Void in deferred.reject(reason) }
    }
    
    static func makeProgress<N>(
        deferred: Deferred<N>,
        onProgress: Optional<(progress: Float) -> Float> = nil,
        progress: Progress? = nil
        ) -> Progress {
            if let progress = progress {
                return progress
            }
            else {
                if let onProgress = onProgress {
                    return { (progress) -> Void in
                        let nextProgress = onProgress(progress: progress)
                        deferred.progress(nextProgress)
                    }
                }
                else {
                    return { (progress: Float) -> Void in deferred.progress(progress) }
                }
            }
    }
}

func ==<V>(lhs: CallbackSet<V>, rhs: CallbackSet<V>) -> Bool {
    return lhs.identifier == rhs.identifier
}

class CallbackSetBuilder<V, N> {
    
    private let deferred: Deferred<N>
    private var reject: CallbackSet<V>.Reject? = nil
    private var progress: CallbackSet<V>.Progress? = nil
    
    init(deferred: Deferred<N>) {
        self.deferred = deferred
    }
    
    func setReject(useDefault: Bool = true, reject: CallbackSet<V>.Reject? = nil) -> Self {
        self.reject = CallbackSet<V>.makeReject(self.deferred, useDefault: useDefault, reject: reject)
        return self
    }
    
    func setProgress(onProgress: Optional<(progress: Float) -> Float> = nil, progress: CallbackSet<V>.Progress? = nil) -> Self {
        self.progress = CallbackSet<V>.makeProgress(self.deferred, onProgress: onProgress, progress: progress)
        return self
    }
    
    func build(fulfill: CallbackSet<V>.Fulfill) -> CallbackSet<V> {
        if self.reject == nil {
            setReject()
        }
        if self.progress == nil {
            setProgress()
        }
        return CallbackSet<V>(fulfill, self.reject!, self.progress!)
    }
}

class CallbackSetThroughBuilder<V>: CallbackSetBuilder<V, V> {
    
    private var fulfill: CallbackSet<V>.Fulfill? = nil
    
    override
    init(deferred: Deferred<V>) {
        super.init(deferred: deferred)
    }
    
    func setFulfill(useDefault: Bool = true, fulfill: CallbackSet<V>.Fulfill? = nil) -> Self {
        self.fulfill = CallbackSet<V>.makeFulfill(self.deferred, useDefault: useDefault, fulfill: fulfill)
        return self
    }
    
    func build() -> CallbackSet<V> {
        if self.fulfill == nil {
            setFulfill()
        }
        return build(self.fulfill!)
    }
}