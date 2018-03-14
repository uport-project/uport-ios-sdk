//
//  Account.swift
//  uPortSDK
//
//  Created by josh on 3/12/18.
//

import UIKit

class Account: NSObject {
    
    private init( network: String, address: String ) {
        
    }
    
    init( network: Data, address: Data ) {
        self.init(network: networkString, address: addressString )
    }
}
