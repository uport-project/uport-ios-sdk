//
//  AccountCreator.swift
//  UPort
//
//  Created by mac on 6/5/18.
//

import UIKit

typealias AccountCreatorCallback = (Error?, Account) -> Void

class AccountCreator: NSObject
{
    private var progress = ProgressPersistence()
    /*
    func createAccount( networkId: String, forceRestart: Bool = false, onCompletion: AccountCreatorCallback) {
        if forceRestart {
            self.progress.reset()
        }
        
//        val signer = UportHDSigner()
        
        switch self.progress.state {
            
        case .none:
                signer.createHDSeed(context, KeyProtection.Level.SIMPLE) { err, rootAddress, _ ->
                    if (err != null) {
                        return@createHDSeed fail(err, callback)
                    }
                    val bundle = oldBundle.copy(rootAddress = rootAddress)
                    progress.save(AccountCreationState.ROOT_KEY_CREATED, bundle)
                    return@createHDSeed createAccount(networkId, false, callback)
                }
            
            
        case .rootKeyCreated:
                signer.computeAddressForPath(context, oldBundle.rootAddress, Account.GENERIC_DEVICE_KEY_DERIVATION_PATH, "") { err, deviceAddress, _ ->
                    if (err != null) {
                        return@computeAddressForPath fail(err, callback)
                    }
                    val bundle = oldBundle.copy(deviceAddress = deviceAddress)
                    progress.save(AccountCreationState.DEVICE_KEY_CREATED, bundle)
                    return@computeAddressForPath createAccount(networkId, false, callback)
                }
            
            
        case .deviceKeyCreated:
                signer.computeAddressForPath(context, oldBundle.rootAddress, Account.GENERIC_RECOVERY_DERIVATION_PATH, "") { err, recoveryAddress, _ ->
                    if (err != null) {
                        return@computeAddressForPath fail(err, callback)
                    }
                    val detail = oldBundle.copy(recoveryAddress = recoveryAddress)
                    progress.save(AccountCreationState.RECOVERY_KEY_CREATED, detail)
                    return@computeAddressForPath createAccount(networkId, false, callback)
                }
            
            
        case .recoveryKeyCreated :
                fuelTokenProvider.onCreateFuelToken(oldBundle.deviceAddress) { err, fuelToken ->
                    if (err != null) {
                        return@onCreateFuelToken fail(err, callback)
                    }
                    
                    val bundle = oldBundle.copy(fuelToken = fuelToken)
                    progress.save(AccountCreationState.FUEL_TOKEN_OBTAINED, bundle)
                    return@onCreateFuelToken createAccount(networkId, false, callback)
                }
            
            
        case .fuelTokenObtained:
                
                requestIdentityCreation(
                    oldBundle.deviceAddress,
                    oldBundle.recoveryAddress,
                    networkId,
                    oldBundle.fuelToken,
                    { err, identityInfo ->
                        if (err != null) {
                            return@requestIdentityCreation fail(err, callback)
                        }
                        val bundle = oldBundle.copy(txHash = identityInfo.txHash ?: "")
                        progress.save(AccountCreationState.PROXY_CREATION_SENT, bundle)
                        
                        return@requestIdentityCreation createAccount(networkId, false, callback)
                })
                
            
            
        case .proxyCreationSent:
                Thread({
                    var pollingDelay = POLLING_INTERVAL
                    while (state != AccountCreationState.COMPLETE) {
                        
                        lookupIdentityInfo(oldBundle.deviceAddress) { _, identityInfo ->
                            
                            //if (err != null) {
                            //    //FIXME: an error here does not necessarily mean a failure; the flow splits here based on type of failure, for example Unnu returns 404 if the proxy hasn't been mined yet
                            //    return@lookupIdentityInfo fail(context, err, callback)
                            //}
                            
                            if (identityInfo != UnnuIdentityInfo.blank) {
                                val proxyAddress = identityInfo.proxyAddress ?: ""
                                val acc = Account(
                                oldBundle.rootAddress,
                                oldBundle.deviceAddress,
                                networkId,
                                proxyAddress,
                                identityInfo.managerAddress,
                                Networks.get(networkId).txRelayAddress,
                                oldBundle.fuelToken,
                                SignerType.MetaIdentityManager
                                )
                                state = AccountCreationState.COMPLETE
                                progress.save(state, oldBundle.copy(partialAccount = acc))
                                
                                return@lookupIdentityInfo callback(null, acc)
                            }
                            
                        }
                        
                        pollingDelay = Math.round(pollingDelay * BACKOFF_FACTOR).toLong()
                        //FIXME: use saner polling model.. coroutines maybe?
                        Thread.sleep(pollingDelay)
                    }
                }).start()
            
        case .complete:
                return callback(null, oldBundle.partialAccount)
            
        default:
            return callback(RuntimeException("Exhausted account creation options, ${state.name}"), Account.blank)
    }
     */
}
