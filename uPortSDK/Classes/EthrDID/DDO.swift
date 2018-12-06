//
//  DDO.swift
//  uPortSDK
//
//  Created by mac on 8/23/18.
//

import Foundation

public struct DDO: Equatable
{
    var id: String
    var publicKey = [PublicKeyEntry]()
    var authentication = [AuthenticationEntry]()
    var service = [ServiceEntry]()
    var context: String = "https://w3id.org/did/v1"

    public init(id: String,
                publicKey: [PublicKeyEntry] = [PublicKeyEntry](),
                authentication: [AuthenticationEntry] = [AuthenticationEntry](),
                service: [ServiceEntry] = [ServiceEntry](),
                context: String = "https://w3id.org/did/v1")
    {
        self.id = id
        self.publicKey = publicKey
        self.authentication = authentication
        self.service = service
        self.context = context
    }
    
    public static func == (lhs: DDO, rhs: DDO) -> Bool
    {
        var areAuthenticationsEqual = true
        for lhsAuthentication in lhs.authentication
        {
            let isInBoth = rhs.authentication.contains
            { (authEntry) -> Bool in
                return authEntry == lhsAuthentication
            }
            
            if !isInBoth
            {
                areAuthenticationsEqual = false
                break
            }
        }
        
        var areServiceEntryEqual = true
        for lhsService in lhs.service
        {
            let isInBoth = rhs.service.contains
            { (rhsService) -> Bool in
                return lhsService == rhsService
            }
            
            if !isInBoth
            {
                areServiceEntryEqual = false
            }
        }
        
        return lhs.id == rhs.id && lhs.context == rhs.context && areAuthenticationsEqual && areServiceEntryEqual
    }
}

public struct PublicKeyEntry: Equatable
{
    var id: String
    var type: DelegateType
    var owner: String
    var ethereumAddress: String?
    var publicKeyHex: String?
    var publicKeyBase64: String?
    var publicKeyBase58: String?
    var value: String?

    public init(id: String,
                type: DelegateType,
                owner: String,
                ethereumAddress: String? = nil,
                publicKeyHex: String? = nil,
                publicKeyBase64: String? = nil,
                publicKeyBase58: String? = nil,
                value: String? = nil)
    {
        self.id = id
        self.type = type
        self.owner = owner
        self.ethereumAddress = ethereumAddress
        self.publicKeyHex = publicKeyHex
        self.publicKeyBase64 = publicKeyBase64
        self.publicKeyBase58 = publicKeyBase58
        self.value = value
    }
    
    public static func == (lhs: PublicKeyEntry, rhs: PublicKeyEntry) -> Bool
    {
        return lhs.id == rhs.id && lhs.type == rhs.type && lhs.owner == rhs.owner
    }
}

public struct AuthenticationEntry
{
    var type: DelegateType
    var publicKey: String

    public init(type: DelegateType, publicKey: String)
    {
        self.type = type
        self.publicKey = publicKey
    }
    
    public static func == (lhs: AuthenticationEntry, rhs: AuthenticationEntry) -> Bool
    {
        return lhs.type == rhs.type && lhs.publicKey == rhs.publicKey
    }
}

public struct ServiceEntry
{
    var type: String
    var serviceEndpoint: String

    public init( type: String, serviceEndpoint: String ) {
        self.type = type
        self.serviceEndpoint = serviceEndpoint
    }
    
    public static func == (lhs: ServiceEntry, rhs: ServiceEntry) -> Bool {
        return lhs.type == rhs.type && lhs.serviceEndpoint == rhs.serviceEndpoint
    }
}

public enum DelegateType: String
{
    case Secp256k1VerificationKey2018
    case Secp256k1SignatureAuthentication2018
    case Ed25519VerificationKey2018
    case RsaVerificationKey2018
}
