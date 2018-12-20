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

/// A DID resolver that selects the appropriate registered resolver.
public struct UniversalDIDResolver: DIDResolver
{
    private var resolvers: [String : DIDResolver] = [ : ]

    /// The queue on which all `completionHandler`s are invoked.  The main queue is the default.
    public private(set) var completionQueue: DispatchQueue

    /// Creates an empty (without resolvers) universal DID resolver.
    ///
    /// To make this struct useful, one or more DID resolvers must be installed using `register()`.
    ///
    /// - Parameters:
    ///     - completionQueue: The queue on which all `completionHandler`s are invoked.  The main queue is the default.
    ///
    init(completionQueue: DispatchQueue = DispatchQueue.main)
    {
        self.completionQueue = completionQueue
    }

    /// Installs a DID resolver.
    ///
    /// - Parameters:
    ///     - resolver: The DID resolver to be installed.
    ///
    /// - Throws: `UniversalDIDResolverError.resolverLacksMethod` if the resolver has an empty `method`.
    ///
    /// - ToDo: Perform more resolver checks (e.g. checking the validity of the `method` string).
    ///
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
        if let resolver = findResolver(for: did)
        {
            return try resolver.resolveSync(did: did)
        }
        else
        {
            throw UniversalDIDResolverError.noSuitableResolver
        }
    }

    /// Resolves the supplied DID asynchronously.
    ///
    /// It's safe to call this function on the main thread, because it returns immediately.  The result is received in
    /// `completionHandler` which is called on the `completionQueue`.  By default `completionQueue` is the main queue.
    ///
    /// - Parameters:
    ///     - did: The DID to be resolved.
    ///     - completionHandler: Invoked on the `completionQueue` with the result or error.
    ///     - document: The resolved DID document, or `nil` in case an error occurred.
    ///     - error: The error, or `nil` if successful.
    ///
    public func resolveAsync(did: String,
                             completionHandler: @escaping (_ document: DIDDocument?, _ error: Error?) -> Void)
    {
        DispatchQueue.global(qos: .userInitiated).async
        {
            do
            {
                let document = try self.resolveSync(did: did)
                self.completionQueue.async
                {
                    completionHandler(document, nil)
                }
            }
            catch
            {
                self.completionQueue.async
                {
                    completionHandler(nil, error)
                }
            }
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
