//
//  ScenarioTests.swift
//  IPromise
//
//  Created by William Remaerd on 10/21/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import UIKit
import XCTest
import IPromise

class ScenarioTests: XCTestCase {
    
    func test_urlLoadingPost_promiseBase() {
        
        let expt = expectationWithDescription(__FUNCTION__)
        
        let promise = Promise<String> { (resolve, reject) -> Void in
            let url: NSURL! = NSURL(string: "http://posttestserver.com/post.php")
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
                if let _ = error {
                    reject(reason: error)
                    return
                }
                resolve(value: NSString(data: data, encoding: NSUTF8StringEncoding)!)
            }
        }
        
        promise.then(
            onFulfilled: { (value) -> Void in
                println(value)
                expt.fulfill()
            },
            onRejected: { (reason) -> Void in
                expt.fulfill()
            }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
    
    func test_urlLoadingPost_DeferredBase() {
        
        func request() -> Promise<String> {
            let d = Deferred<String>()
            
            let url: NSURL! = NSURL(string: "http://posttestserver.com/post.php")
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            
            NSURLConnection.sendAsynchronousRequest(
                request,
                queue: NSOperationQueue.mainQueue())
                { (response, data, error) -> Void in
                    if let _ = error {
                        d.reject(error)
                        return
                    }
                    d.resolve(NSString(data: data, encoding: NSUTF8StringEncoding)!)
            }
            
            return d.promise;
        }
        
        let expt = expectationWithDescription(__FUNCTION__)
        
        request()
            .then(
                onFulfilled: { (value) -> Void in
                    println(value)
                    expt.fulfill()
                },
                onRejected: { (reason) -> Void in
                    expt.fulfill()
                }
        )
        
        waitForExpectationsWithTimeout(7, handler: nil)
    }
}
