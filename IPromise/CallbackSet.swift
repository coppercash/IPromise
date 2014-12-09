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
    
    init<N>(
        _ deferred: Deferred<N>,
        fulfill: Fulfill,
        reject: Reject?,
        progress: Progress?
        ) {
            let r = (reject != nil) ? reject! :
                { (reason: NSError) -> Void in deferred.reject(reason) }
            let p = (progress != nil) ? progress! :
                { (progress: Float) -> Void in deferred.progress(progress) }
            self.init(fulfill, r, p)
    }

    init(
        _ deferred: Deferred<V>,
        fulfill: Fulfill?,
        reject: Reject?,
        progress: Progress?
        ) {
            let f = (fulfill != nil) ? fulfill! :
                { (value: V) -> Void in deferred.resolve(value) }
            self.init(deferred, fulfill, reject, progress)
    }
    
    
    static func defaultFulfill(deferred: Deferred<V>, fulfill: Fulfill? = nil) -> Fulfill {
        return (fulfill != nil) ? fulfill! :
            { (value: V) -> Void in deferred.resolve(value) }
    }
    
    static func defaultReject<N>(deferred: Deferred<N>, reject: Reject? = nil) -> Reject {
        return (reject != nil) ? reject! :
            { (reason: NSError) -> Void in deferred.reject(reason) }
    }
    
    static func defaultProgress<N>(deferred: Deferred<N>, progress: Progress? = nil) -> Progress {
        return (progress != nil) ? progress! :
            { (progress: Float) -> Void in deferred.progress(progress) }
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
    
    var fulfill: CallbackSet<V>.Fulfill? = nil
    var reject: CallbackSet<V>.Reject? = nil
    var progress: CallbackSet<V>.Progress? = nil
    
    init(deferred: Deferred<N>) {
    }
    
    
}