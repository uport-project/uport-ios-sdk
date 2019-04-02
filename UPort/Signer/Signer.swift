//
//  File.swift
//  UPort
//
//  Created by Aldi Gjoka on 3/7/19.
//  Copyright © 2019 ConsenSys. All rights reserved.
//

import Foundation

typealias SignatureCallback = (exception?, NSDictionary?) -> Void

public protocol Signer {
    //static func signETH(rawMessage: Data, callback: SignatureCallback)
    
    func signJWT(rawPayload: String, completionHandler: @escaping UPTHDSignerJWTSigningResult)
    
    //func getAddress() -> String
}

