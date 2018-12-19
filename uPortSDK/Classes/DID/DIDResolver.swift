//
//  DIDResolver.swift
//  uPortSDK
//
//  Created by Cornelis van der Bent on 06/12/2018.
//

import Foundation

public protocol DIDResolver
{
    var method: String { get }

    func resolveSync(did: String) throws -> DIDDocument

    func canResolve(did: String) -> Bool
}
