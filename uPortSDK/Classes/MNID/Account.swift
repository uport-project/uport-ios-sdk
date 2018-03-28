//
//  Account.swift
//  uPortSDK
//
//  Created by josh on 3/12/18.
//

import UIKit

public class Account: NSObject {
    
    let network: String!
    let address: String!
    
    init?( network: String, address: String ) {
        guard !network.isEmpty && !address.isEmpty else {
            return nil
        }
        
        let addressWithoutHexPrefix = address.withoutHexPrefix
        let ethereumAddressNumChars = 40
        let numZerosToPad = ethereumAddressNumChars - addressWithoutHexPrefix.count
        guard 0 < numZerosToPad else {
            return nil
        }
        
        let paddedAddress = addressWithoutHexPrefix.pad(toMultipleOf: numZerosToPad, character: "0", location: .left)
        self.network = network
        self.address = "0x\(paddedAddress)"

        super.init()
    }
    
    class func from( network: Data, address: Data ) -> Account? {
        return Account.init( network: network.hexEncodedString(), address: address.hexEncodedString() )
    }
    
}
