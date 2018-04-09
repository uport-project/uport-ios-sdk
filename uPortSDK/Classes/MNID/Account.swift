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
    
    public init?( network: String, address: String ) {
        guard !network.isEmpty && !address.isEmpty else {
            return nil
        }
        
        var addressWithoutHexPrefix = address.withoutHexPrefix
        let ethereumAddressNumChars = 40
        let numZerosToPad = ethereumAddressNumChars - addressWithoutHexPrefix.count
        if 0 < numZerosToPad {
            addressWithoutHexPrefix = addressWithoutHexPrefix.pad(toMultipleOf: numZerosToPad, character: "0", location: .left)
        } else if numZerosToPad < 0 {
            return nil
        }
        
        self.network = network
        self.address = "0x\(addressWithoutHexPrefix)"

        super.init()
    }
    
    public class func from( network: Data, address: Data ) -> Account? {
        return Account.init( network: network.hexEncodedString(), address: address.hexEncodedString() )
    }
    
}
