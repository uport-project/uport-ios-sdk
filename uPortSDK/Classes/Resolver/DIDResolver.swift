//
//  DIDResolver.swift
//  uPortSDK
//
//  Created by Cornelis van der Bent on 06/12/2018.
//

import Foundation

protocol DIDResolver
{
    var method: String { get }

    func resolve(did: String) throws -> DIDDocument

    func canResolve(did: String) -> Bool
}
