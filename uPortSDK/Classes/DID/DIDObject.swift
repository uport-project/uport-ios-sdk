//
//  DIDObject.swift
//  uPortSDK
//
//  Created by Cornelis van der Bent on 06/12/2018.
//

import Foundation

public enum DIDObjectError: Error
{
    case invalidFormat
    case emptyMethod
    case wrongScheme(String)
}

public struct DIDObject
{
    private(set) var did: String
    private(set) var scheme: String    // Is always "did".
    private(set) var method: String
    private(set) var id: String
    private(set) var path: String?
    private(set) var fragment: String? // Only true DID fragment (see https://w3c-ccg.github.io/did-spec/#dfn-did-fragment).

    var isReference: Bool
    {
        return path != nil || fragment != nil
    }

    public init(_ did: String) throws
    {
        let components = try DIDObject.separateIntoComponents(did: did)
        guard components[0] == "did" else
        {
            throw DIDObjectError.wrongScheme(components[0])
        }

        self.did = did
        scheme = components[0]
        method = components[1]
        id = ""

        if findPath(component: components[2]) == false
        {
            findFragment(component: components[2])
        }

        guard !id.isEmpty else
        {
            throw DIDObjectError.invalidFormat
        }
    }

    private mutating func findPath(component: String) -> Bool
    {
        let idPath = component.split(separator: "/",
                                     maxSplits: 1,
                                     omittingEmptySubsequences: false).map(String.init)
        if idPath.count == 2
        {
            id = idPath[0]
            path = idPath[1].isEmpty ? nil : idPath[1]
            fragment = nil

            return true
        }
        else
        {
            return false
        }
    }

    private mutating func findFragment(component: String)
    {
        let idFragment = component.split(separator: "#",
                                         maxSplits: 1,
                                         omittingEmptySubsequences: false).map(String.init)
        if idFragment.count == 2
        {
            id = idFragment[0]
            fragment = idFragment[1].count > 0 ? idFragment[1] : nil
            path = nil
        }
        else
        {
            id = component
            fragment = nil
            path = nil
        }
    }

    private static func separateIntoComponents(did: String) throws -> [String]
    {
        let components = did.components(separatedBy: ":")

        guard components.count == 3 else
        {
            throw DIDObjectError.invalidFormat
        }

        guard (components.reduce(true) { $0 && !$1.isEmpty }) else
        {
            throw DIDObjectError.invalidFormat
        }

        return components
    }
}
