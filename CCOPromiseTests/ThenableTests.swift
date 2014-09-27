//
//  ThenableTests.swift
//  CCOPromise
//
//  Created by William Remaerd on 9/24/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

import UIKit
import XCTest
import CCOPromise

typealias FutureCallback = (Float) -> Void

protocol FutureTnenable
{
    func then(#onFulfilled: Resolution?, onRejected: Rejection?, onFutureCallback: FutureCallback?) -> FutureTnenable
    func catch(onRejected: Rejection) -> FutureTnenable
}

class ThenableObject: Thenable
{
    func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil) -> Thenable
    {
        return self
    }
    
    func catch(onRejected: Rejection) -> Thenable
    {
        return then(onFulfilled: nil, onRejected: onRejected);
    }
}

class FutureThenableObject: FutureTnenable
{
    func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil, onFutureCallback: FutureCallback? = nil) -> FutureTnenable
    {
        return self;
    }
    
    func catch(onRejected: Rejection) -> FutureTnenable
    {
        return then(nil, onRejected: onRejected, onFutureCallback: nil)
    }
}


class ThenableTests: XCTestCase
{
    func test_expansibility()
    {
        let aThenableObject = ThenableObject()
        
        aThenableObject.then(
            onFulfilled:
            { (value) -> Any? in
                return nil
            },
            onRejected:
            { (error) -> Any? in
                return nil
        })
        
        let aFutureThenableObject = FutureThenableObject()
        
        aThenableObject.then(
            onFulfilled:
            { (value) -> Any? in
                return nil
            },
            onRejected:
            { (error) -> Any? in
                return nil
        })
    }
    
    func test_convenience()
    {
        let aThenableObject = ThenableObject()

        
        // General
        
        aThenableObject.then(
            onFulfilled:
            { (value) -> Any? in
                
                return nil
            },
            onRejected:
            { (error) -> Any? in
                
                return nil
            }
        )
        
        aThenableObject.then(
            onFulfilled:
            { (value) -> Any? in
                
                return nil
            }
        )
        
        aThenableObject.then(
            onRejected:
            { (error) -> Any? in
                
                return nil
            }
        )
        
        // Then
        
        aThenableObject.then(
            { (value) -> Any? in
                
                return nil
            }
        )
        
        aThenableObject.then { (value) -> Any? in
            return nil
        }
        
        // Catch
        
        aThenableObject.catch (
            { (error) -> Any? in
                return nil
            }
        )
        
        aThenableObject.catch { (error) -> Any? in
            return nil
        }
    }
}