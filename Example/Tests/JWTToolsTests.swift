//
//  JWTToolsTests.swift
//  uPortSDK_Tests
//
//  Created by Cornelis van der Bent on 20/12/2018.
//  Copyright © 2018 ConsenSys. All rights reserved.
//

import XCTest
@testable import uPortSDK

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
        let expectation = self.expectation(description: "Verify JWT")

        JWTTools.verify(jwt: incomingJwt)
        { (payload, error) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3)
    }

    func testVerifyShareRequest()
    {
        let expectation = self.expectation(description: "Verify JWT")

        JWTTools.verify(jwt: validShareReqToken1)
        { (payload, error) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3)
    }
}
