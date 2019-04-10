//
//  KPSigner.swift
//  UPort
//
//  Created by Aldi Gjoka on 4/4/19.
//  Copyright © 2019 ConsenSys. All rights reserved.
//

import Foundation
import UPTEthereumSigner

class KPSigner: Signer {
    private var privateKey: String
    
    init(privateKey: String) {
        self.privateKey = privateKey
    }

    func signJWT(rawPayload: String, completionHandler: @escaping UPTHDSignerJWTSigningResult) {
        let payloadData = rawPayload.data(using: .utf8)
        let hash = payloadData?.sha256()
        let keyData = BTCDataFromHex(self.privateKey)
        let keypair = BTCKey.init(privateKey: keyData)
        let sig = jwtSignature(keypair, hash)
        completionHandler(sig, nil)
    }

    func getAddress() -> String {
        let keyData = BTCDataFromHex(self.privateKey)
        let keypair = BTCKey.init(privateKey: keyData)
        let address = UPTEthSigner.ethAddress(withPublicKey: keypair?.publicKey as Data?)!
        return address
    }
}
