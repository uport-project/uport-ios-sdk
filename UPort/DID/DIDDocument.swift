//
//  DIDDocument.swift
//  uPortSDK
//
//  Created by Cornelis van der Bent on 11/12/2018.
//

import Foundation

public class DIDDocument: Equatable
{
    public var context: String = "https://w3id.org/did/v1"
    public var id: String
    public var publicKey = [PublicKeyEntry]()
    public var authentication = [AuthenticationEntry]()
    public var service = [ServiceEntry]()

    public init(context: String = "https://w3id.org/did/v1",
                id: String,
                publicKey: [PublicKeyEntry] = [PublicKeyEntry](),
                authentication: [AuthenticationEntry] = [AuthenticationEntry](),
                service: [ServiceEntry] = [ServiceEntry]())
    {
        self.context = context
        self.id = id
        self.publicKey = publicKey
        self.authentication = authentication
        self.service = service
    }

    public static func == (lhs: DIDDocument, rhs: DIDDocument) -> Bool
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
    public var id: String
    public var type: DelegateType
    public var owner: String
    public var ethereumAddress: String?
    public var publicKeyHex: String?
    public var publicKeyBase64: String?
    public var publicKeyBase58: String?
    public var value: String?

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
    public var type: DelegateType
    public var publicKey: String

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
    public var type: String
    public var serviceEndpoint: String

    public init(type: String, serviceEndpoint: String)
    {
        self.type = type
        self.serviceEndpoint = serviceEndpoint
    }

    public static func == (lhs: ServiceEntry, rhs: ServiceEntry) -> Bool
    {
        return lhs.type == rhs.type && lhs.serviceEndpoint == rhs.serviceEndpoint
    }
}

public enum DelegateType: String
{
    case Secp256k1VerificationKey2018
    case Secp256k1SignatureAuthentication2018
    case Ed25519VerificationKey2018
    case RsaVerificationKey2018
    case Curve25519EncryptionPublicKey
}
