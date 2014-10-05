//
//  PromiseState.swift
//  CCOPromise
//
//  Created by William Remaerd on 10/5/14.
//  Copyright (c) 2014 CopperCash. All rights reserved.
//

public enum PromiseState: Printable {
    case Pending, Fulfilled, Rejected
    
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
