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
    private var resolvers: [String : DIDResolver] = [:]

    mutating func register(resolver: DIDResolver) throws
    {
        guard resolver.method.isEmpty == false else
        {
            throw UniversalDIDResolverError.resolverLacksMethod
        }

        resolvers[resolver.method] = resolver
    }

    // MARK: - DIDResolver Implementation

    public func resolve(did: String) throws -> DIDDocument
    {
        if let resolver = try findResolver(for: did)
        {
            return try resolver.resolve(did: did)
        }
        else
        {
            throw UniversalDIDResolverError.noSuitableResolver
        }
    }

    public var method: String = ""

    public func canResolve(did: String) -> Bool
    {
        return ((try? findResolver(for: did)) != nil)
    }

    private func findResolver(for did: String) throws -> DIDResolver?
    {
        let dido = try DIDObject(did)

        var resolver = resolvers[dido.method]
        if resolver == nil
        {
            resolver = resolvers.values.first { $0.canResolve(did: did) }
        }

        return resolver
    }
}
