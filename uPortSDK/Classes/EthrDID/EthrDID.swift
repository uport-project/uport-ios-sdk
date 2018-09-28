//
//  EthrDID.swift
//  uPortSDK
//
//  Created by josh on 8/9/18.
//

import Foundation
import UPTEthereumSigner
import BigInt
import Promises

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
    private var owner: String?
    
    public init( address: String, rpc: JsonRPC, registry: String ) {
        self.address = address
        self.rpc = rpc
        self.registry = registry
    }
    
    public func lookupOwner( cache: Bool = true ) -> Promise<String> {
        return Promise<String> { fulfill, reject in
            DispatchQueue.global().async {
                DispatchQueue.global().async {
                    do {
                        let response = try self.lookupOwnerSynchronous( cache: cache )
                        fulfill( response )
                    } catch {
                        reject( error )
                    }
                }
            }
        }
    }
    
    public func lookupOwner( cache: Bool = true, callback: @escaping (_ ownerAddress: String?, _ error: Error?) -> Void ) {
        DispatchQueue.global().async {
            do {
                let response = try self.lookupOwnerSynchronous( cache: cache )
                callback( response, nil )
            } catch {
                callback( nil, error )
            }
        }
    }
    
    public func lookupOwnerSynchronous( cache: Bool = true ) throws -> String {
        if cache && self.owner != nil {
            return self.owner!
        }
        
        guard let addressBigUInt = BigUInt( self.address.withoutHexPrefix, radix: 16 ) else {
            throw EthrDIDError.invalidAddress
        }
        
        let solidityAddressOptional = try? Solidity.Address(bigUInt:addressBigUInt)
        guard let solidityAddress = solidityAddressOptional else {
            throw EthrDIDError.invalidAddress
        }
        
        let encodedCall = EthereumDIDRegistry.IdentityOwner.encodeCall(arguments:solidityAddress)
        let response = try rpc.ethCallSynchronous(address: self.registry, data: encodedCall)
        guard let rawResult = JsonRpcBaseResponse.fromJson(json: response).result as? String else {
            throw JsonRpcError.invalidResult
        }
        
        let addressStartIndex = rawResult.index(rawResult.endIndex, offsetBy: -40)
        let address = String( rawResult[ addressStartIndex...rawResult.endIndex ] )
        return address.withHexPrefix
    }
    
    func changeOwner( newOwner: String, callback: @escaping ( _ transactionHash: String?, _ error: Error? ) -> Void ) {
        self.lookupOwner(cache: true) { ownerAddress, error in
            guard error == nil, let ownerAddress = ownerAddress else {
                print( "error looking up owner -> \(error!)" )
                return
            }

            guard let ownerAddressBigUInt = BigUInt( ownerAddress.withoutHexPrefix, radix: 16 ),
                  let newOwnerAddressBigUInt = BigUInt( newOwner.withoutHexPrefix, radix: 16 )  else {
                callback( nil, EthrDIDError.invalidAddress )
                return
            }
            
            let ownerAddressOptional = try? Solidity.Address( bigUInt: ownerAddressBigUInt )
            let newOwnerAddressOptional = try? Solidity.Address( bigUInt: newOwnerAddressBigUInt )
            guard let ownerAddressSolidity = ownerAddressOptional,
                    let newOwnerAddressSolidity = newOwnerAddressOptional else {
                callback( nil, EthrDIDError.invalidAddress )
                return
            }
            
            let encodedCall = EthereumDIDRegistry.ChangeOwner.encodeCall(arguments: (identity: ownerAddressSolidity, newOwner: newOwnerAddressSolidity))
         }
    }
    
    func addDelegate( delegate: String, options: DelegateOptions? = nil, callback: (String) -> Void ) {
        
    }

    private func signAndSendContractCall( owner: String, encodedCall: String, callback: (_ transactionHash: String?, _ error: Error ) -> Void ) {
        let noncePromise = self.rpc.transactionCount( address: owner )
        let gasPricePromise = self.rpc.gasPrice()
        all( noncePromise, gasPricePromise ).then { nonce, networkGasPrice in
            let unsignedTx = Transaction.defaultTransaction( from: EthAddress(input: owner),
                                                             gasLimit: BigInt( integerLiteral: 70000),
                                                             gasPrice: networkGasPrice,
                                                             input: Array(hex: encodedCall),
                                                             nonce: nonce,
                                                             to: EthAddress(input: self.registry),
                                                             value: BigInt( integerLiteral: 0 ) )
//            let signedEncodedTx =
            

        }
    }
}

