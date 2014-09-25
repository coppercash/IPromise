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
    func then(#onFulfilled: Resolution?, onRejected: Rejection?, onFutureCallback: FutureCallback?) -> Self
    func then(onFulfilled: Resolution) -> Self
    func catch(onRejected: Rejection) -> Self
}

class ThenableObject: Thenable
{
    func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil) -> Self
    {
        println("\(__FUNCTION__)")
        return self
    }
    
    func then(onFulfilled: Resolution) -> Self
    {
        return then(onFulfilled: onFulfilled, onRejected: nil);
    }
    
    func catch(onRejected: Rejection) -> Self
    {
        return then(onFulfilled: nil, onRejected: onRejected);
    }
}

class FutureThenableObject: FutureTnenable
{
    func then(onFulfilled: Resolution? = nil, onRejected: Rejection? = nil, onFutureCallback: FutureCallback? = nil) -> Self
    {
        return self;
    }
    
    func then(onFulfilled: Resolution) -> Self
    {
        return then(onFulfilled, onRejected: nil, onFutureCallback: nil);
    }
    
    func catch(onRejected: Rejection) -> Self
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
            { (result) -> Any? in
                return nil
            },
            onRejected:
            { (error) -> Any? in
                return nil
        })
        
        let aFutureThenableObject = FutureThenableObject()
        
        aThenableObject.then(
            onFulfilled:
            { (result) -> Any? in
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
            { (result) -> Any? in
                
                return nil
            },
            onRejected:
            { (error) -> Any? in
                
                return nil
            }
        )
        
        aThenableObject.then(
            onFulfilled:
            { (result) -> Any? in
                
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
            { (result) -> Any? in
                
                return nil
            }
        )
        
        aThenableObject.then { (result) -> Any? in
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