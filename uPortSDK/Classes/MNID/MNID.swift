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
    case codingError(String)
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

        guard mnidVersion != nil && mnidVersion! <= VERSION_NUMBER else {
            throw MNIDError.versionError("Version mismatch.\nCan't decode a future version of MNID. Expecting \(VERSION_NUMBER) and got \(String(describing:mnidVersion))")
        }

        let networkLength = mnidData.count - VERSION_WIDTH - ADDRESS_WIDTH - CHECKSUM_WIDTH
        guard 0 < networkLength else {
            throw MNIDError.codingError("Buffer size mismatch.\nThere are not enough bytes in this mnid to encode an address")
        }

        // read the raw network and address
        let networkEndIndex = VERSION_WIDTH + networkLength
        let networkData = mnidData[ VERSION_WIDTH..<networkEndIndex ]
        let addressEndIndex = networkEndIndex + ADDRESS_WIDTH
        let addressData = mnidData[ networkEndIndex..<addressEndIndex ]
        
        // check for checksum match
        let payloadLength = mnidData.count - CHECKSUM_WIDTH
        let payloadData = mnidData[ 0..<payloadLength  ]
        let checksumEndIndex = payloadLength + CHECKSUM_WIDTH
        let checksumData = mnidData[ payloadLength..<checksumEndIndex ]

        let payloadSHA3 = Data( payloadData ).sha3( .sha256 )
        let payloadCheck = Array<UInt8>( payloadSHA3[ 0..<CHECKSUM_WIDTH ] )
        if payloadCheck != checksumData.bytes {
            throw MNIDError.codingError( "The checksum does not match the payload" )
        }
    
        return Account.from(network: networkData, address: addressData)
    }
    
    class func encode( account: Account? ) throws -> String {
        let safeAccount = account ?? Account( network: "00", address: "00" )
        return try MNID.encode(network: safeAccount!.network, address: safeAccount!.address)
    }

    class func encode( network: String, address: String ) throws -> String {
        guard let addressData = Data( fromHexEncodedString: address.withoutHexPrefix ) else {
            throw MNIDError.codingError( "Invalid Address: could not compute a byte array from the hex address provided" )
        }
        
        guard let networkData = Data( fromHexEncodedString: network.withoutHexPrefix ) else {
            throw MNIDError.codingError( "Invalid Network: could nto compute a byte array from the hex network provided" )
        }
        
        if ADDRESS_WIDTH < addressData.count {
            throw MNIDError.codingError( "Address is too long. An Ethereum address must be 20 bytes long." )
        }

        let mnidDataCapacity = VERSION_WIDTH + networkData.count + ADDRESS_WIDTH + CHECKSUM_WIDTH
        var mnidData = Data( capacity: mnidDataCapacity )

        // version
        mnidData.append(VERSION_NUMBER)

        // network
        mnidData.append( networkData )

        // address
        if addressData.count < ADDRESS_WIDTH{
            let numZeros = ADDRESS_WIDTH - addressData.count
            mnidData.append( Data( count: numZeros ) )
        }

        mnidData.append( addressData )

        // checksum
        let checksummableWidth = mnidDataCapacity - CHECKSUM_WIDTH
        let payloadArray = Array( mnidData[ 0..<checksummableWidth ] )
        let payloadData = Data( payloadArray )
        let sha3HashData = payloadData.sha3( .sha256 )
        let checksumSlice = sha3HashData[ 0..<CHECKSUM_WIDTH ]

        mnidData.append(checksumSlice)
        return mnidData.base58EncodedString()
    }
}
