//
//  ProgressPersistence.swift
//  UPort
//
//  Created by mac on 6/5/18.
//

import UIKit

enum AccountCreationState: Int
{
    case none = 0
    case rootKeyCreated
    case deviceKeyCreated
    case recoveryKeyCreated
    case fuelTokenObtained
    case proxyCreationSent
    case complete
}

class ProgressPersistence: NSObject
{
    var state: AccountCreationState
    let stateRetrievalKey = "uPortSDK.AccountCreationState.RetrievalKey"
    
    override init()
    {
        let stateRawValue = UserDefaults.standard.integer(forKey: self.stateRetrievalKey)
        self.state = AccountCreationState(rawValue: stateRawValue) ?? .none

        super.init()
    }
    
    func reset()
    {
        UserDefaults.standard.set(0, forKey: self.stateRetrievalKey)
        self.state = .none
    }
}
