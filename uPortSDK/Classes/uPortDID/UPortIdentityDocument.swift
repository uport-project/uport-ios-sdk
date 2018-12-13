//
//  UPortIdentityDocument.swift
//  uPortSDK
//
//  Created by josh on 3/6/18.
//

import Foundation

public struct UPortIdentityDocument: Codable
{
    public var type: String?           // ex: "Organization", "Person"
    public var publicKey: String?      // ex: "0x04613bb3a4874d27032618f020614c21cbe4c4e4781687525f6674089f9bd3d6c7f6eb13569053d31715a3ba32e0b791b97922af6387f087d6b5548c06944ab062"
    public var publicEncKey: String?   // ex: "0x04613bb3a4874d27032618f020614c21cbe4c4e4781687525f6674089f9bd3d6c7f6eb13569053d31715a3ba32e0b791b97922af6387f087d6b5548c06944ab062"
    public var image: String?          // ex: {"@type":"ImageObject","name":"avatar","contentUrl":"/ipfs/QmSCnmXC91Arz2gj934Ce4DeR7d9fULWRepjzGMX6SSazB"}
    public var name: String?           // ex: "uPort @ Devcon3" , "Vitalik Buterout"
    public var didDescription: String? // ex: "uPort Attestation"
    public var context: String?
    
    public init(context: String?, type: String?, publicKey: String?, publicEncKey: String?, description: String?, image: String?, name: String?)
    {
        self.context = context
        self.type = type
        self.publicKey = publicKey
        self.publicEncKey = publicEncKey
        self.didDescription = description
        self.image = image
        self.name = name
    }

    func convertToDIDDocument(did: String) throws -> UPortDIDDocument
    {
        let normalizedDid = try normalizeDid(did)

        let publicKeyEntry = PublicKeyEntry(id: "\(normalizedDid)#keys-1",
                                            type: .Secp256k1VerificationKey2018,
                                            owner: normalizedDid,
                                            publicKeyHex: publicKey?.withoutHexPrefix)
        var publicKeyEntries = [publicKeyEntry]
        if publicEncKey != nil
        {
            let publicEncKeyEntry = PublicKeyEntry(id: "\(normalizedDid)#keys-2",
                type: .Curve25519EncryptionPublicKey,
                owner: normalizedDid,
                publicKeyBase64: publicEncKey)
            publicKeyEntries.append(publicEncKeyEntry)
        }

        let authenticationEntry = AuthenticationEntry(type: .Secp256k1SignatureAuthentication2018,
                                                      publicKey: "\(normalizedDid)#keys-1")

        let profile = UPortIdentityDocument(context: nil,
                                            type: self.type,
                                            publicKey: nil,
                                            publicEncKey: nil,
                                            description: self.didDescription,
                                            image: self.image,
                                            name: self.name)

        return UPortDIDDocument(context: "https://w3id.org/did/v1",
                                id: did,
                                publicKey: publicKeyEntries,
                                authentication: [authenticationEntry],
                                profile: profile)
    }

    private func normalizeDid(_ did: String) throws -> String
    {
        let dido = try DIDObject(did)

        return "did:uport:\(dido.id)"
    }
}

extension UPortIdentityDocument: Equatable
{
    public static func ==(lhs: UPortIdentityDocument, rhs: UPortIdentityDocument) -> Bool
    {
        return lhs.publicKey == rhs.publicKey && lhs.publicEncKey == rhs.publicEncKey
    }
}
