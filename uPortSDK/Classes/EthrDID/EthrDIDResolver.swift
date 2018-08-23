//
//  EthrDidResolver.swift
//  uPortSDK
//
//  Created by josh on 8/7/18.
//

import Foundation

public struct EthrDIDResolver {

    var registryAddress = "0xdca7ef03e98e0dc2b855be647c39abe984fcf21b"
    var rpc : JsonRPC

    public init( rpc: JsonRPC, registeryAddress: String = "0xdca7ef03e98e0dc2b855be647c39abe984fcf21b" ) {
        self.rpc = rpc
        self.registryAddress = registryAddress
    }

    func resolve( did: String ) -> DDO {
        var normalizeDid = normalizeDid( did )

    }

    private let didParsePattern = try? NSRegularExpression( pattern: "^(did:)?((\\w+):)?((0x)([0-9a-fA-F]{40}))", options: .caseInsensitive )
    private func normalizeDid( did: String ) -> String {
        let matchedSubstrings = didParsePattern?.matches( in: did, options: [], range: NSRange(location: 0, length: did.count) ).map { (result: NSTextCheckingResult) -> String in
            return did.substring(with: result.range)
        }

        guard matchedSubstrings != nil && 0 < matchedSubstrings.count else {
            return ""
        }



    }
}
