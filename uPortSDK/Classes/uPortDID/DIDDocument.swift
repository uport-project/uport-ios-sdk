//
//  DIDDocument.swift
//  uPortSDK
//
//  Created by josh on 3/6/18.
//

import Foundation

public struct DIDDocument: Codable
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
}

extension DIDDocument: Equatable
{
    public static func ==(lhs: DIDDocument, rhs: DIDDocument) -> Bool
    {
        return lhs.publicKey == rhs.publicKey && lhs.publicEncKey == rhs.publicEncKey
    }
}
