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
        JWTTools.dateProvider = DateProvider(date: Date(timeIntervalSince1970: 12345678))
        let testPayload = ["claims": ["name": "R Daneel Olivaw"]]
        let privKey = "54ece214d38fe6b46110a21c69fd55230f09688bf85b95fc7c1e4e160441ece1"
        let testSigner = KPSigner(privateKey: privKey)
        let address = testSigner.getAddress()
        let issuerDid = "did:ethr:" + address
        
        JWTTools.create(payload: testPayload, issuerDID: issuerDid, signer: testSigner, expiresIn: 300) { (token, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            do
            {
                let (_, payload, _, _) = try JWTTools.decode(jwt: token!)
                let claims = payload.claims!["claims"] as? [String: Any]
                XCTAssertEqual((claims?["name"] as? String), testPayload["claims"]!["name"])
            } catch
            {
                
            }
            
        }
    }
    
    func testKPSignerJWT()
    {
        let expectation = self.expectation(description: "Verify Share Request JWT")
        let referenceSig: [String: Any] = [ "r": "6bcd81446183af193ca4a172d5c5c26345903b24770d90b5d790f74a9dec1f68",
                                            "s": "e2b85b3c92c9b4f3cf58de46e7997d8efb6e14b2e532d13dfa22ee02f3a43d5d",
                                            "v": 1]
        
        let privKey = "65fc670d9351cb87d1f56702fb56a7832ae2aab3427be944ab8c9f2a0ab87960"
        let payload = "Hello, world!"
        let testSigner = KPSigner(privateKey: privKey)
        testSigner.signJWT(rawPayload: payload) { (sig, error) in
            if error != nil
            {
                XCTFail("\(String(describing: error))")
            } else {
                let rData = try? (sig!["r"] as? String)?.decodeBase64()
                let sData = try? (sig!["s"] as? String)?.decodeBase64()
                let vNum = sig!["v"] as? Int
                
                let rString = rData??.toHexString()
                let sString = sData??.toHexString()

                XCTAssertEqual(referenceSig["r"] as? String, rString)
                XCTAssertEqual(referenceSig["s"] as? String, sString)
                XCTAssertEqual(referenceSig["v"] as? Int, vNum)

                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 3)
    }
}
