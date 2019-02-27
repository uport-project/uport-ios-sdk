//
//  UPortDIDDocument.swift
//  UPort
//
//  Created by Cornelis van der Bent on 12/12/2018.
//

import Foundation

public class UPortDIDDocument: DIDDocument
{
    public var uportProfile: UPortIdentityDocument

    init(context: String = "https://w3id.org/did/v1",
         id: String,
         publicKey: [PublicKeyEntry] = [PublicKeyEntry](),
         authentication: [AuthenticationEntry] = [AuthenticationEntry](),
         service: [ServiceEntry] = [ServiceEntry](),
         profile: UPortIdentityDocument)
    {
        self.uportProfile = profile
        super.init(context: context,
                   id: id,
                   publicKey: publicKey,
                   authentication: authentication,
                   service: service)
    }
}
