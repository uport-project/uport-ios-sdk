//
//  ParsedDID.swift
//  uPortSDK
//
//  Created by Cornelis van der Bent on 06/12/2018.
//

import Foundation

enum ParsedDIDError: Error
{
    case invalidFormat
    case wrongScheme(String)
}

struct ParsedDID
{
    let raw: String
    let scheme: String    // Is always "did".
    let method: String
    let id: String
    let path: String?
    let fragment: String? // Only true DID fragment (see https://w3c-ccg.github.io/did-spec/#dfn-did-fragment).

    init(_ did: String) throws
    {
        raw = did

        let components = try ParsedDID.separateIntoComponents(did: did)

        scheme = components[0]
        method = components[1]

        let fragmentIndex = components[2].firstIndex(of: "#")
        let pathIndex = components[2].firstIndex(of: "/")

        if pathIndex != nil
        {
            id = String(components[2][String.Index(encodedOffset: 0) ... pathIndex!])
            path = String(components[2][pathIndex! ..< String.Index(encodedOffset: components[2].count)])
            fragment = nil // See https://w3c-ccg.github.io/did-spec/#dfn-did-fragment
        }
        else
        {
            path = nil

            if fragmentIndex != nil
            {
                id = String(components[2][String.Index(encodedOffset: 0) ... pathIndex!])
                fragment = String(components[2][fragmentIndex! ..< String.Index(encodedOffset: components[2].count)])
            }
            else
            {
                id = components[2]
                fragment = nil
            }
        }
    }

    private static func separateIntoComponents(did: String) throws -> [String]
    {
        let components = did.components(separatedBy: ":")

        guard components.count == 3 else
        {
            throw ParsedDIDError.invalidFormat
        }

        guard components[0] == "did" else
        {
            throw ParsedDIDError.wrongScheme(components[0])
        }

        return components
    }
}
