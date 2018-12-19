//
//  DIDResolver.swift
//  uPortSDK
//
//  Created by Cornelis van der Bent on 06/12/2018.
//

import Foundation

/**
    DID resolver protocol.  This is the interface expected by the `UniversalDIDResolver`.
 */
public protocol DIDResolver
{
    /// DID method, for example `"uport"` or `"ethr"`.
    var method: String { get }

    /// Resolves the supplied DID synchronously, on the current thread.
    ///
    /// Because the current thread is blocked, **do not call this function on the main thread**.  Consider using
    /// `UniversalDIDResolver.resolveAsync(...)`.
    ///
    /// - Parameters:
    ///     - did: The DID to be resolved.
    ///
    /// - Throws: An error defined by the implementing class/struct.
    ///
    /// - Returns: The resolved DID document.
    ///
    func resolveSync(did: String) throws -> DIDDocument

    ///Checks if the supplied DID has the proper format to be resolved.
    ///
    /// - Parameters:
    ///     - did: The DID to be checked.
    ///
    /// - Returns: If supplied DID has the proper format `true`, otherwise `false`.
    ///
    func canResolve(did: String) -> Bool
}
