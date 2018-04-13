// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import uPortSDK

class DIDResolverSpec: QuickSpec {
    override func spec() {
        describe("testing did resolver components") {
            it("encapsulates json rpc") {
                let expectedPayload = "{\"method\":\"eth_call\",\"jsonrpc\":\"2.0\",\"id\":1,\"params\":[{\"to\":\"0xaddress\",\"data\":\"some0xdatastring\"},\"latest\"]}"
                let ethCall = EthCall( address: "0xaddress", data: "some0xdatastring")
                let payload = JsonRpcBaseRequest( ethCall: ethCall ).toJsonRPC()!

                expect(payload) == expectedPayload
            }
            
            it("encodes eth call") {
                let expectedEncoding = "0x447885f075506f727450726f66696c654950465331323230000000000000000000000000000000000000000000000000f12c30cd32b4a027710c150ae742f50db0749213000000000000000000000000f12c30cd32b4a027710c150ae742f50db0749213"
                let acc = Account(network: "0x04", address: "0xf12c30cd32b4a027710c150ae742f50db0749213")!
                let encoding = DIDResolver.encodeRegistryFunctionCall( registrationIdentifier: "uPortProfileIPFS1220", issuer: acc, subject: acc)
                
                expect(encoding) == expectedEncoding
            }

            it( "can call registry with appropriate server response" ) {
                let expectedDocAddress = "QmWzBDtv8m21ph1aM57yVDWxdG7LdQd3rNf5xrRiiV2D2E"
                let docAddressHex = DIDResolver.synchronousIpfsHash( mnid: "2ozs2ntCXceKkAQKX4c9xp2zPS8pvkJhVqC" )
                
                expect(docAddressHex) == expectedDocAddress
            }
            
            it ( "Can get JSON DID" ) {
                let expectedDDO = DIDDocument(
                    context: "http://schema.org",
                    type: "Person",
                    publicKey: "0x04e8989d1826cd6258906cfaa71126e2db675eaef47ddeb9310ee10db69b339ab960649e1934dc1e1eac1a193a94bd7dc5542befc5f7339845265ea839b9cbe56f",
                    publicEncKey: "k8q5G4YoIMP7zvqMC9q84i7xUBins6dXGt8g5H007F0=",
                    description: nil,
                    image: nil,
                    name: nil
                )
                
                let ddo = DIDResolver.synchronousProfileDocument( mnid: "2ozs2ntCXceKkAQKX4c9xp2zPS8pvkJhVqC" )
                
                expect( ddo! ) == expectedDDO
            }
        }
    }
            /*
            it("can read") {
                expect("number") == "string"
            }

            it("will eventually fail") {
                expect("time").toEventually( equal("done") )
            }
            
            context("these will pass") {

                it("can do maths") {
                    expect(23) == 23
                }

                it("can read") {
                    expect("🐮") == "🐮"
                }

                it("will eventually pass") {
                    var time = "passing"

                    DispatchQueue.main.async {
                        time = "done"
                    }

                    waitUntil { done in
                        Thread.sleep(forTimeInterval: 0.5)
                        expect(time) == "done"

                        done()
                    }
                }
            }
        }
        

        
        @Test
        fun calls_registry() {
            
            val expectedDocAddress = "Qm-WzBDtv8m21ph1aM57yVDWxdG7LdQd3rNf5xrRiiV2D2E"
            val docAddressHex = DIDResolver().getIpfsHashSync("2ozs2ntCXceKkAQKX4c9xp2zPS8pvkJhVqC")
            
            assertEquals(expectedDocAddress, docAddressHex)
        }
        
        @Test
        fun getJsonDIDSync() {
            
            val expectedDDO = DDO(
                context = "http://schema.org",
                type = "Person",
                publicKey = "0x04e8989d1826cd6258906cfaa71126e2db675eaef47ddeb9310ee10db69b339ab960649e1934dc1e1eac1a193a94bd7dc5542befc5f7339845265ea839b9cbe56f",
                publicEncKey = "k8q5G4YoIMP7zvqMC9q84i7xUBins6dXGt8g5H007F0=",
                description = null,
                image = null,
                name = null
            )
            
            val ddo = DIDResolver().getProfileDocumentSync("2ozs2ntCXceKkAQKX4c9xp2zPS8pvkJhVqC")
            
            assertEquals(expectedDDO, ddo)
        }
        
        
 
    }
 */
}
