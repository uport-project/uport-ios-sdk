//
//  JWTHeader.swift
//  UPort
//
//  Created by Cornelis van der Bent on 24/12/2018.
//

import Foundation

/// Possible errors thrown.
public enum JWTHeaderError: Error
{
    case missingJwtType
    case missingAlgorithm
    case unsupportedAlgorithm(String)
}

/// Contains JWT header data.
public struct JWTHeader
{
    public enum Algorithm: String
    {
        case ES256K = "ES256K"
        case ES256K_R = "ES256K-R"  // With recovery byte.
    }

    public var algorithm: Algorithm

    public init(dictionary: [String : Any]) throws
    {
        guard dictionary["typ"] as? String == "JWT" else
        {
            throw JWTHeaderError.missingJwtType
        }

        guard let alg = dictionary["alg"] as? String else
        {
            throw JWTHeaderError.missingAlgorithm
        }

        switch alg
        {
        case Algorithm.ES256K.rawValue:
            algorithm = .ES256K

        case Algorithm.ES256K_R.rawValue:
            algorithm = .ES256K_R

        default:
            throw JWTHeaderError.unsupportedAlgorithm(alg)
        }
    }
}
