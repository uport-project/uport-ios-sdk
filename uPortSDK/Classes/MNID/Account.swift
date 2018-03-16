//
//  Account.swift
//  uPortSDK
//
//  Created by josh on 3/12/18.
//

import UIKit

public class Account: NSObject {
    
    let network: String
    let address: String
    
    private init?( network: String, address: String ) {
        if !network.isEmpty, !address.isEmpty {
            let addressWithoutHexPrefix = address.withoutHexPrefix
            let ethereumAddressNumChars = 40
            let numZerosToPad = ethereumAddressNumChars - addressWithoutHexPrefix.count
            if 0 < numZerosToPad {
                let paddedAddress = addressWithoutHexPrefix.pad(toMultipleOf: numZerosToPad, character: "0", location: .left)
                self.network = network
                self.address = "0x\(paddedAddress)"
            }
        }
        
        return nil
    }
    
    class func from( network: Data, address: Data ) -> Account? {
        return Account.init( network: network.hexEncodedString(), address: address.hexEncodedString() )
    }
    
}
