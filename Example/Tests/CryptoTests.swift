//
//  CryptoTests.swift
//  uPortSDK_Tests
//
//  Created by Aldi Gjoka on 12/5/18.
//  Copyright © 2018 ConsenSys. All rights reserved.
//
import Sodium
import XCTest
@testable import uPortSDK

class CryptoTests: XCTestCase
{
    override func setUp()
    {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetPublicKey()
    {
        let secretKey = "2zKGhQCdzrpOoejE+dbIxvN5r+0wCEcUnV465+fXEtc="
        let expectedPublicKey = "8hWKNxUltyh4dyBDcg5wKy6i9y0EI+0LeaqG/zuVgXo="
        
        if let pk = try! Crypto.getEncryptionPublicKey(secretKey: secretKey)
        {
            XCTAssertEqual(pk, expectedPublicKey)
        }
    }
    
    func testGetPublicKeyRandomVectors()
    {
        let fixtures = parseTestCases("ScalarMultTestValues")
        for vec in fixtures {
            let expectedPk1 = vec[0]
            let sk1 = vec[1]
            let expectedPk2 = vec[2]
            let sk2 = vec[3]
            
            if let actualPk1 = try! Crypto.getEncryptionPublicKey(secretKey: sk1)
            {
                XCTAssertEqual(actualPk1, expectedPk1)
            }
            
            if let actualPk2 = try! Crypto.getEncryptionPublicKey(secretKey: sk2)
            {
                XCTAssertEqual(actualPk2, expectedPk2)
            }
        }
    }
    
    func testPadding()
    {
        let original = "hello"
        let padded = original.padToBlock()
        let unpadded = padded.unpadFromBlock()
        XCTAssertEqual(unpadded, original)
    }
    
    func testZeroPaddingUnicode()
    {
        let messages: Array<String> =
            [
                "hello",
                "小路の藪",
                "柑子、パイ",
                "ポパイポ パイ",
                "ポのシューリンガ",
                "ン。五劫の擦り切れ",
                "、食う寝る処に住む処",
                "。グーリンダイのポンポ",
                "コピーのポンポコナーの、",
                "長久命の長助、寿限無、寿限",
                "無、グーリンダイのポンポコピ",
                "ーのポンポコナーの。やぶら小路",
                "🇯🇵 🇰🇷 🇩🇪 🇨🇳 🇺🇸 🇫🇷 🇪🇸 🇮🇹 🇷🇺 🇬🇧",
                "🎄 🌟 ❄️ 🎁 🎅 🦌"
        ]
        
        for message in messages
        {
            let padded = message.padToBlock()
            XCTAssertNotEqual(Array(message.utf8), padded)
            XCTAssertTrue(padded.count % 64 == 0)
            
            let unpadded = padded.unpadFromBlock()
            XCTAssertEqual(message, unpadded)
            
        }
    }
    
    func testEncryptAndDecrypt()
    {
        let originalMessage = "Hello EIP1098"
        let boxSecret = Array<UInt8>(base64: "Qgigj54O7CsQOhR5vLTfqSQyD3zmq/Gb8ukID7XvC3o=")
        let boxPub = "oGZhZ0cvwgLKslgiPEQpBkRoE+CbWEdi738efvQBsH0="
        
        let result = Crypto.encrypt(message: originalMessage, boxPub: boxPub)
        let decrypted = Crypto.decrypt(encrypted: result, secretKey: boxSecret)
        XCTAssertEqual(decrypted, originalMessage)
    }
    
    func testDecrypt()
    {
        let c = Crypto.EncryptedMessage(nonce: "1dvWO7uOnBnO7iNDJ9kO9pTasLuKNlej",
                                        ephemPublicKey: "FBH1/pAEHOOW14Lu3FWkgV3qOEcuL78Zy+qW1RwzMXQ=",
                                        ciphertext: "f8kBcl/NCyf3sybfbwAKk/np2Bzt9lRVkZejr6uh5FgnNlH/ic62DZzy")
        
        let decryptedMessage = Crypto.decrypt(encrypted: c,
                                              secretKey: Array<UInt8>(hex: "7e5374ec2ef0d91761a6e72fdf8f6ac665519bfdf6da0a2329cf0d804514b816"))
        
        XCTAssertEqual(decryptedMessage,"My name is Satoshi Buterin")
    }
    
    func testJsonDeserialization()
    {
        let json =
        """
        {"version":"x25519-xsalsa20-poly1305","nonce":"JAX+g+/e3RnnNXHRS4ct5Sb+XdgYoJeY","ephemPublicKey":"JLBIe7eSVyq6egVexeWrlKQyOukSo66G3N0PlimMUyI","ciphertext":"Yr2o6x831YWFZr6KESzSkBqpMv1wYkxPULbVSZi21J+2vywrVeZnDe/U2GW40wzUpLv4HhFgL1kvt+cORrapsqCfSy2L1ltMtkilX06rJ+Q"}
        """
        
        let enc = try! Crypto.EncryptedMessage.fromJson(jsonData: json.data(using: .utf8)!)
        XCTAssertEqual("x25519-xsalsa20-poly1305", enc.version)
        XCTAssertEqual("JAX+g+/e3RnnNXHRS4ct5Sb+XdgYoJeY", enc.nonce)
        XCTAssertEqual("JLBIe7eSVyq6egVexeWrlKQyOukSo66G3N0PlimMUyI", enc.ephemPublicKey)
        XCTAssertEqual("Yr2o6x831YWFZr6KESzSkBqpMv1wYkxPULbVSZi21J+2vywrVeZnDe/U2GW40wzUpLv4HhFgL1kvt+cORrapsqCfSy2L1ltMtkilX06rJ+Q", enc.ciphertext)
        
    }
    
    func testJsonSerialization()
    {
        //language=JSON
        let expected = """
        {"ciphertext":"f8kBcl\\/NCyf3sybfbwAKk\\/np2Bzt9lRVkZejr6uh5FgnNlH\\/ic62DZzy","nonce":"1dvWO7uOnBnO7iNDJ9kO9pTasLuKNlej","ephemPublicKey":"FBH1\\/pAEHOOW14Lu3FWkgV3qOEcuL78Zy+qW1RwzMXQ=","version":"x25519-xsalsa20-poly1305"}
        """
        let expectedDictionary = try! JSONSerialization.jsonObject(with: expected.data(using: .utf8)!, options: []) as! [String: Any]
        
        
        let input = Crypto.EncryptedMessage(nonce: "1dvWO7uOnBnO7iNDJ9kO9pTasLuKNlej",
                                            ephemPublicKey: "FBH1/pAEHOOW14Lu3FWkgV3qOEcuL78Zy+qW1RwzMXQ=",
                                            ciphertext: "f8kBcl/NCyf3sybfbwAKk/np2Bzt9lRVkZejr6uh5FgnNlH/ic62DZzy")
        let inputJson = try! input.toJson()
        
        if let inputDictionary = try! JSONSerialization.jsonObject(with: inputJson, options: []) as? [String: Any]
        {
            if let nonce = inputDictionary["nonce"] as? String
            {
                XCTAssertEqual(expectedDictionary["nonce"] as! String, nonce)
            }
            
            if let ciphertext = inputDictionary["ciphertext"] as? String
            {
                XCTAssertEqual(expectedDictionary["ciphertext"] as! String, ciphertext)
            }
            
            if let version = inputDictionary["version"] as? String
            {
                XCTAssertEqual(expectedDictionary["version"] as! String, version)
            }
            
            if let ephemPublicKey = inputDictionary["ephemPublicKey"] as? String
            {
                XCTAssertEqual(expectedDictionary["ephemPublicKey"] as! String, ephemPublicKey)
            }
        }
        
    }
    
    func testEncryptAndDecryptLargeMessage() {
        let sodium = Sodium()
        let loremIpsum = """
        やぶら小路の藪柑子、パイポパイポ パイポのシューリンガン。五劫の擦り切れ、食う寝る処に住む処。グーリンダイのポンポコピーのポンポコナーの、長久命の長助、寿限無、寿限無、グーリンダイのポンポコピーのポンポコナーの。やぶら小路の藪柑子。
        パイポパイポ パイポのシューリンガン、水行末 雲来末 風来末。シューリンガンのグーリンダイ、グーリンダイのポンポコピーのポンポコナーの。やぶら小路の藪柑子、寿限無、寿限無。パイポパイポ パイポのシューリンガン。寿限無、寿限無、長久命の長助。シューリンガンのグーリンダイ。長久命の長助、水行末 雲来末 風来末。グーリンダイのポンポコピーのポンポコナーの。
        パイポパイポ パイポのシューリンガン。長久命の長助。やぶら小路の藪柑子、長久命の長助、パイポパイポ パイポのシューリンガン、グーリンダイのポンポコピーのポンポコナーの、海砂利水魚の、寿限無、寿限無。食う寝る処に住む処。水行末 雲来末 風来末、シューリンガンのグーリンダイ、五劫の擦り切れ。グーリンダイのポンポコピーのポンポコナーの。海砂利水魚の、食う寝る処に住む処、シューリンガンのグーリンダイ。五劫の擦り切れ。水行末 雲来末 風来末。寿限無、寿限無、やぶら小路の藪柑子。
        やぶら小路の藪柑子、寿限無、寿限無。長久命の長助。五劫の擦り切れ、グーリンダイのポンポコピーのポンポコナーの。パイポパイポ パイポのシューリンガン。シューリンガンのグーリンダイ、五劫の擦り切れ、食う寝る処に住む処。
        水行末 雲来末 風来末、水行末 雲来末 風来末、パイポパイポ パイポのシューリンガン。グーリンダイのポンポコピーのポンポコナーの、五劫の擦り切れ、寿限無、寿限無、シューリンガンのグーリンダイ。海砂利水魚の、パイポパイポ パイポのシューリンガン。五劫の擦り切れ、やぶら小路の藪柑子。海砂利水魚の、食う寝る処に住む処、食う寝る処に住む処、寿限無、寿限無。長久命の長助、やぶら小路の藪柑子。グーリンダイのポンポコピーのポンポコナーの。
        국회는 헌법개정안이 공고된 날로부터 60일 이내에 의결하여야 하며. 모든 국민은 법률이 정하는 바에 의하여 선거권을 가진다. 이 경우 공무원 자신의 책임은 면제되지 아니한다, 국가원로자문회의의 조직·직무범위 기타 필요한 사항은 법률로 정한다.
        समूह ढांचा शुरुआत मानसिक उसीएक् दोषसके संसाध मेमत सकते निर्देश विस्तरणक्षमता शीघ्र और्४५० प्राथमिक ध्वनि उनका एसलिये सम्पर्क प्राधिकरन यधपि हिंदी मुखय प्रमान आशाआपस प्रतिबध समजते हार्डवेर संस्क्रुति केवल संसाध नयेलिए जानकारी स्वतंत्र विवरन मानव स्थिति है।अभी निरपेक्ष सकते विशेष उपेक्ष निर्देश ध्वनि करती तकरीबन विनिमय सुस्पश्ट भारत करता। एसेएवं एकत्रित विवरन एछित मुख्य सभिसमज निरपेक्ष स्वतंत्रता २४भि
        ومن هو مدينة غينيا. لها مع الشطر العصبة المتساقطة،, جيما الذود و ولم, الآخر انذار بمباركة بـ حيث. جُل في بتطويق حاملات والكساد, أضف هناك الأولى ولاتّساع في. بحث أم وترك عسكرياً الجنرال, عل مايو المارق حين, بقعة شدّت المشترك تعد في.
        լոռեմ իպսում դոլոռ սիթ ամեթ, վենիամ դելենիթ նե սիթ, եոս վեռեառ ինթեգռե ծոռպոռա իդ, պոսթեա պռոդեսսեթ վիմ ան. նոսթռուդ վիվենդո նո պեռ. եի նոսթռո ֆասթիդիի ինծիդեռինթ եում, մոդո պռոբաթուս ռեծթեքուե նե դուո. եամ սինթ մունեռե.
        ლორემ იფსუმ დოლორ სით ამეთ, ეუმ რებუმ აფფელლანთურ ეა. ვის ეა სოლეთ რათიონიბუს, ეა ნეც ყუანდო ფართიენდო ირაცუნდია. ცუმ ად ფალლი ვოლუთფათ. ან აეთერნო თამყუამ ვის, ეა ილლუდ აეყუე ველ. ნე ყუო ალია.
        שער מוגש בשפה הקהילה אם. סרבול ביוני על לוח. את לחבר המלצת חבריכם אחר, מה שתי בשפה להפוך ניהול. המחשב משפטים ויקיפדיה אם בקר.
        En ruffen iw'rem grousse oft. Do alles d'Beem weisen ons, hun Räis kille Stret jo. Um kille frësch sin, d'Stroos däischter un zum. Ronn aremt Schuebersonndeg as ass, un sinn geplot wou. Un erem d'Liewen d'Vullen hun. Ké der fond Noper uechter, Feld éiweg gewëss en hir, en Ronn lait heemlech hir.
        डाले। गएआप वेबजाल रहारुप निरपेक्ष साधन औषधिक अत्यंत निर्माण विशेष संभव स्थापित पहोचाना संपुर्ण आजपर सारांश सभिसमज निर्देश विभाग सदस्य ब्रौशर केन्द्रित विचरविमर्श ७हल अत्यंत माहितीवानीज्य विवरन मुखय ध्वनि प्रौध्योगिकी विकेन्द्रियकरण सुनत कीसे हमारी परिवहन हार्डवेर सार्वजनिक होने प्रति जिम्मे बेंगलूर प्रतिबध्दता मानसिक और्४५० प्राधिकरन ध्येय ७हल पहेला पत्रिका विश्वास मुश्किले जैसी कार्य नयेलिए भोगोलिक सोफ़्टवेर कर्य
        🇯🇵 🇰🇷 🇩🇪 🇨🇳 🇺🇸 🇫🇷 🇪🇸 🇮🇹 🇷🇺 🇬🇧
        🎄 🌟 ❄️ 🎁 🎅 🦌
        """
        
        let boxSecret = Array<UInt8>(base64: "2zKGhQCdzrpOoejE+dbIxvN5r+0wCEcUnV465+fXEtc=")
        let boxPub = "8hWKNxUltyh4dyBDcg5wKy6i9y0EI+0LeaqG/zuVgXo="
        
        let enc = Crypto.encrypt(message: loremIpsum, boxPub: boxPub)
        let recoveredMessage = Crypto.decrypt(encrypted: enc, secretKey: boxSecret)
        XCTAssertEqual(recoveredMessage, loremIpsum)
    }
    
    func parseTestCases(_ fileName: String) -> [[String]] {
        do
        {
            let file = Bundle(for: type(of: self)).url(forResource: fileName, withExtension: "json")
            let data = try Data(contentsOf: file!)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String]] else
            {
                return []
            }
            return json!
        }
        catch
        {
            print(error)
            return []
        }
    }
    
}
