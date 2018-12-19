//
//  UniversalDIDResolver.swift
//  uPortSDK
//
//  Created by Cornelis van der Bent on 06/12/2018.
//

import Foundation

public enum UniversalDIDResolverError: Error
{
    case resolverLacksMethod
    case noSuitableResolver
}

public struct UniversalDIDResolver: DIDResolver
{
    private var resolvers: [String : DIDResolver] = [ : ]

    public mutating func register(resolver: DIDResolver) throws
    {
        guard resolver.method.isEmpty == false else
        {
            throw UniversalDIDResolverError.resolverLacksMethod
        }

        resolvers[resolver.method] = resolver
    }

    // MARK: - DIDResolver Implementation

    public func resolveSync(did: String) throws -> DIDDocument
    {
        if let resolver = try findResolver(for: did)
        {
            return try resolver.resolveSync(did: did)
        }
        else
        {
            throw UniversalDIDResolverError.noSuitableResolver
        }
    }

    public var method: String = ""

    public func canResolve(did: String) -> Bool
    {
        return findResolver(for: did) != nil
    }

    private func findResolver(for did: String) -> DIDResolver?
    {
        if let dido = try? DIDObject(did),
           let resolver = resolvers[dido.method]
        {
            return resolver
        }
        else
        {
            return resolvers.values.first { $0.canResolve(did: did) }
        }
    }
}
