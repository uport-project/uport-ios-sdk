//
//  MNID.swift
//  uPortSDK
//
//  Created by josh on 3/12/18.
//

import UIKit
import CryptoSwift

public enum MNIDError: Error {
    case isMNIDError(String)
    case decodingError(String)
    case versionError(String)
}

public class MNID: NSObject {

    private static let VERSION_WIDTH = 1
    private static let ADDRESS_WIDTH = 20
    private static let CHECKSUM_WIDTH = 4
    private static let VERSION_NUMBER: UInt8 = 1

    class func decode( mnid: String ) throws -> Account? {
        guard !mnid.isEmpty else {
            throw MNIDError.isMNIDError("Can't decode a null or empty mnid")
        }

        let mnidData = try mnid.decodeBase58()
        let mnidVersion = mnidData.first

        guard mnidVersion == VERSION_NUMBER else {
            throw MNIDError.versionError("Version mismatch.\nCan't decode a future version of MNID. Expecting \(VERSION_NUMBER) and got \(String(describing:mnidVersion))")
        }

        let networkLength = mnidData.count - VERSION_WIDTH - ADDRESS_WIDTH - CHECKSUM_WIDTH
        guard networkLength <= 0 else {
            throw MNIDError.decodingError("Buffer size mismatch.\nThere are not enough bytes in this mnid to encode an address")
        }

        // read the raw network and address
        let networkData = mnidData[ VERSION_WIDTH..<networkLength ]
        let networkStartIndex = VERSION_WIDTH + networkLength
        let addressData = mnidData[ networkStartIndex..<ADDRESS_WIDTH ]
        
        // check for checksum match
        let payloadLength = mnidData.count - CHECKSUM_WIDTH
        let payloadData = mnidData[ 0..<payloadLength  ]
        let checksumData = mnidData[ payloadLength..<CHECKSUM_WIDTH ]

        let payloadSHA3 = Digest.sha3(payloadData.bytes, variant: SHA3.Variant.sha256)
        let payloadCheck = Array<UInt8>( payloadSHA3[ 0..<CHECKSUM_WIDTH ] )
        if payloadCheck != checksumData.bytes {
            throw MNIDError.decodingError( "The checksum does not match the payload" )
        }
    
        return Account.from(network: networkData, address: addressData)
    }
    
    func encode( account: Account ) {
        
    }

    func encode( network: String, address: String ) {
        
    }
}
