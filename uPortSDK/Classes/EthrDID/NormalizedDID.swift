//
//  EthrDIDResolverExtension.swift
//  uPortSDK
//
//  Created by mac on 8/29/18.
//

import Foundation

public enum NormalizedDIDError: Error {
    case invalidDIDCandidateParam
    case invalidDIDType
    case notDID
    case sanityCheckFailure
}

public struct NormalizedDID {
    /// the result of processing the did
    /// empty string if invalid didCandidate was passed to constructor
    var value = ""
    
    /// will be non-nil if constuct fails to process the DID
    var error: NormalizedDIDError?

    public let didParsePattern = try? NSRegularExpression( pattern: "^(did:)?((\\w+):)?((0x)([0-9a-fA-F]{40}))", options: .caseInsensitive )

    public init( didCandidate: String ) {
        let textCheckingResults = self.didParsePattern?.matches( in: didCandidate, options: [], range: NSRange(location: 0, length: didCandidate.count) )
        guard let textCheckingResult = textCheckingResults?.first else {
            self.error = NormalizedDIDError.invalidDIDCandidateParam
            return
        }
        
        var matches = [String]()
        for index in 1..<textCheckingResult.numberOfRanges {
            let range = Range(textCheckingResult.range(at: index), in: didCandidate )
            if range != nil {
                let stringSlice = didCandidate[ range! ]
                let match = String( stringSlice  )
                matches.append( match )
            }
        }
        
        guard 0 < matches.count else {
            self.error = NormalizedDIDError.notDID
            return
        }
        
        let didHeader = self.didHeader( matches: matches )
        let didType = self.didType( matches: matches )
        if !didType.isEmpty && !didType.starts(with: "ethr") {
            self.error = NormalizedDIDError.invalidDIDType
            return
            
        }
        if didHeader.isEmpty && !didType.isEmpty {
            self.error = NormalizedDIDError.notDID
            return            
        }
        
        guard let hexDigits = matches.last, hexDigits.count == 40 else {
            self.error = NormalizedDIDError.sanityCheckFailure
            return
        }
        
        self.value = "did:ethr:0x\(hexDigits)"
    }
    
    private func didHeader( matches: [String] ) -> String {
        return matches.filter({ (item) -> Bool in
            return item.starts(with: "did")
        }).first ?? ""
    }
    
    private func didType( matches: [String] ) -> String {
        return matches.filter({ (item) -> Bool in
            return item.starts(with: "ethr" )
        }).first ?? ""
    }
    
}
