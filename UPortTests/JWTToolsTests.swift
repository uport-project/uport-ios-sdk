//
//  JWTToolsTests.swift
//  UPortTests
//
//  Created by Cornelis van der Bent on 20/12/2018.
//  Copyright © 2018 ConsenSys. All rights reserved.
//

import XCTest
@testable import UPort

class DateProvider: JWTToolsDateProvider
{
    var date: Date

    init(date: Date)
    {
        self.date = date
    }

    func now() -> Date
    {
        return date
    }
}

class JWTToolsTests: XCTestCase
{
    let incomingJwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NksifQ.eyJpc3MiOiIyb21SSlpMMjNaQ1lnYzFyWnJG" +
                      "VnBGWEpwV29hRUV1SlVjZiIsImlhdCI6MTUxOTM1MDI1NiwicGVybWlzc2lvbnMiOlsibm90aWZ" +
                      "pY2F0aW9ucyJdLCJjYWxsYmFjayI6Imh0dHBzOi8vYXBpLnVwb3J0LnNwYWNlL29sb3J1bi9jcm" +
                      "VhdGVJZGVudGl0eSIsIm5ldCI6IjB4MzAzOSIsImFjdCI6ImRldmljZWtleSIsImV4cCI6MTUyM" +
                      "jU0MDgwMCwidHlwZSI6InNoYXJlUmVxIn0.EkqNUyrZhcDbTQl73XpL2tp470lCo2saMXzuOZ91" +
                      "UI2y-XzpcBMzhhSeUORnoJXJhHnkGGpshZlESWUgrbuiVQ"

    let validShareReqToken1 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NksifQ.eyJpc3MiOiIyb2VYdWZIR0RwVTUxYmZLQnNa" +
                              "RGR1N0plOXdlSjNyN3NWRyIsImlhdCI6MTUyMDM2NjQzMiwicmVxdWVzdGVkIjpbIm5hbWUiLCJ" +
                              "waG9uZSIsImNvdW50cnkiLCJhdmF0YXIiXSwicGVybWlzc2lvbnMiOlsibm90aWZpY2F0aW9ucy" +
                              "JdLCJjYWxsYmFjayI6Imh0dHBzOi8vY2hhc3F1aS51cG9ydC5tZS9hcGkvdjEvdG9waWMvWG5IZ" +
                              "nlldjUxeHNka0R0dSIsIm5ldCI6IjB4NCIsImV4cCI6MTUyMDM2NzAzMiwidHlwZSI6InNoYXJl" +
                              "UmVxIn0.C8mPCCtWlYAnroduqysXYRl5xvrOdx1r4iq3A3SmGDGZu47UGTnjiZCOrOQ8A5lZ0M9" +
                              "JfDpZDETCKGdJ7KUeWQ"

    func testTwoPartsException()
    {
        do
        {
            _ = try JWTTools.decode(jwt: "header.payload")
        }
        catch JWTToolsError.malformedNotThreeParts
        {
            XCTAssertTrue(true)
        }
        catch
        {
            XCTAssertTrue(false)
        }
    }

    func testFourPartsException()
    {
        do
        {
            _ = try JWTTools.decode(jwt: "header.payload.some.more")
        }
        catch JWTToolsError.malformedNotThreeParts
        {
            XCTAssertTrue(true)
        }
        catch
        {
            XCTAssertTrue(false)
        }
    }

    func testVerifyIncomingJWT()
    {
        let expectation = self.expectation(description: "Verify Incoming JWT")

        JWTTools.dateProvider = DateProvider(date: Date(timeIntervalSince1970: 1522540300))
        JWTTools.verify(jwt: incomingJwt)
        { (payload, error) in
            if let error = error
            {
                XCTFail("\(error)")
            }

            XCTAssertNotNil(payload)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3)
    }

    func testVerifyShareRequestJWT()
    {
        let expectation = self.expectation(description: "Verify Share Request JWT")

        JWTTools.dateProvider = DateProvider(date: Date(timeIntervalSince1970: 1520366666))
        JWTTools.verify(jwt: validShareReqToken1)
        { (payload, error) in
            if let error = error
            {
                XCTFail("\(error)")
            }

            XCTAssertNotNil(payload)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3)
    }
    
    func testCreateJWT()
    {
        let expectation = self.expectation(description: "Verify Incoming JWT")
        
        JWTTools.dateProvider = DateProvider(date: Date(timeIntervalSince1970: 1520366666))
        UPTHDSigner.createHDSeed(UPTEthKeychainProtectionLevel.normal, rootDerivationPath: UPORT_ROOT_DERIVATION_PATH) {
            (address, pubkey, error) in
            if (address != nil) {
                let testAddress = address
                let testSigner = UPTHDSignerImpl(rootAddress: testAddress!)
                JWTTools.create(payload: ["claim": "test"], issuerDID: "did:ethr:" + testAddress!, signer: testSigner, expiresIn: 600) { (token, error) in
                    
                    JWTTools.verify(jwt: token!) { (payload, error) in
                        expectation.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 3)
    }
}
