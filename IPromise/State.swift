//
//  PromiseState.swift
//  IPromise
//
//  Created by William Remaerd on 10/5/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

public enum State: Printable {
    case Pending, Fulfilled, Rejected
    
    mutating func fulfill() -> Bool {
        if self != .Pending {
            return false
        }
        else {
            self = .Fulfilled
            return true
        }
    }
    
    mutating func reject() -> Bool {
        if self != .Pending {
            return false
        }
        else {
            self = .Rejected
            return true
        }
    }
    
    public var description: String {
        switch self {
        case .Pending:
            return "Pending"
        case .Fulfilled:
            return "Fulfilled"
        case .Rejected:
            return "Rejected"
            }
    }
}
