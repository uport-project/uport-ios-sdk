//
//  EthrDID.swift
//  uPortSDK
//
//  Created by josh on 8/9/18.
//

import Foundation
import UPTEthereumSigner
import BigInt

public enum EthrDIDError: Error {
    case invalidAddress
}

public struct EthrDID {
    
    public struct DelegateOptions {
        var delegateType: String?
        var expiresIn: Int64?
    }
    
    private var address: String
    private var rpc: JsonRPC
    private var registry: String
    var signer: UPTEthereumSigner
    private var owner: String?
    
    public init( address: String, rpc: JsonRPC, registry: String, signer: UPTEthereumSigner ) {
        self.address = address
        self.rpc = rpc
        self.registry = registry
        self.signer = signer
    }
    
    public func lookupOwner( cache: Bool = true, callback: (String?, Error?) -> Void ) {
        if cache && self.owner != nil {
            callback( self.owner!, nil )
            return
        }
        
        guard let addressBigUInt = BigUInt( self.address.withoutHexPrefix, radix: 16 ) else {
            callback( nil, EthrDIDError.invalidAddress )
            return
        }
        
        var encodedCall = try! EthereumDIDRegistry.IdentityOwner.encodeCall(arguments:Solidity.Address(bigUInt:addressBigUInt))
//        var jsonRPCResponce = rpc.ethCall(registry, encodedCall)
    }
    
    func changeOwner( newOwner: String, callback: (String) -> Void ) {
    
    }
    
    func addDelegate( delegate: String, options: DelegateOptions? = nil, callback: (String) -> Void ) {
        
    }
}

