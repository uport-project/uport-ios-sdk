//
//  UPTHDSignerImpl.swift
//  UPort
//
//  Created by Aldi Gjoka on 3/12/19.
//  Copyright © 2019 ConsenSys. All rights reserved.
//

import Foundation
import UPTEthereumSigner


class UPTHDSignerImpl: Signer
{
    //private var hdSigner: UPTHDSigner
    var rootAddress: String
    var deviceAddress: String
    
    init(rootAddress: String)
    {
        //self.hdSigner = hdSigner
        self.rootAddress = rootAddress
        self.deviceAddress = rootAddress
    }
    
    func signJWT(rawPayload: String, completionHandler: @escaping UPTHDSignerJWTSigningResult)
    {
        UPTHDSigner.signJWT(rootAddress,
                            derivationPath: UPORT_ROOT_DERIVATION_PATH,
                            data: rawPayload,
                            prompt: "simple",
                            callback: completionHandler)

    }
}
