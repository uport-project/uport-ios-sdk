//
//  MNID.swift
//  uPortSDK
//
//  Created by josh on 3/12/18.
//

import UIKit

public enum MNIDError: Error {
    case encodingException(String)
}

public class MNID: NSObject {
    
    func decode( mnid: String ) throws {
        guard mnid != nil && !mnid.isEmpty else {
            throw MNIDError.encodingException("Can't decode a null or empty mnid")
        }

        let rawMnid = mnid

    }
    
    func encode( account: Account ) {
        
    }
    func encode( network: String, address: String ) {
        
    }
}
