//
//  MintException.swift
//  MINT
//
//  Created by 安藤 泰造 on 2015/03/09.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

// Mint exception class
// Exception stack for Mint, manage invalid user operation.

enum MintEXC {
    case TypeInvalid(leafName: String, leafID: Int, required: String, invalid:String) // type of variable is invalid
    case ArgNotExist(leafName: String, leafID: Int, reguired: String) // required name of argument does not exist
    case LeafIDNotExist(leafID: Int)// leafID is not exist. Critical error & should kill the app
}

class MintErr {
    private var exceptions : [MintEXC] = []
    //private weak var interpreter : MintInterpreter!
    private init(){}
    
    var catch: MintEXC? {
        if let err = exceptions.last {
            exceptions.removeLast()
            return err
        }
        
        return nil
    }
    
    func rise(newErr: MintEXC) {
        exceptions.append(newErr)
    }
    
    class var exc: MintErr {
        struct Static{
            static let exception = MintErr()
        }
        return Static.exception
    }
    
}