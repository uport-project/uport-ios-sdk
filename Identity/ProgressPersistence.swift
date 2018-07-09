//
//  ProgressPersistence.swift
//  uPortSDK
//
//  Created by mac on 6/5/18.
//

import UIKit

enum AccountCreationState: Int {
    case none = 0, rootKeyCreated, deviceKeyCreated, recoveryKeyCreated, fuelTokenObtained, proxyCreationSent, complete
}

class ProgressPersistence: NSObject {
    
    var state: AccountCreationState
    let stateRetrievalKey = "uPortSDK.AccountCreationState.RetrievalKey"
    
    override init() {
        
        let stateRawValue = UserDefaults.standard.integer(forKey: self.stateRetrievalKey)
        self.state = AccountCreationState( rawValue: stateRawValue ) ?? .none
        super.init()
        
    }
    
    func reset() {
        UserDefaults.standard.set( 0, forKey: self.stateRetrievalKey)
        self.state = .none
    }
}
