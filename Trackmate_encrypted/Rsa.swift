//
//  RsaUtilities.swift
//  rsa
//
//  Created by iOSprogramming on 2023/08/16.
//

import Foundation
import BigNumber

class RsaKey{
    
    static let maxPQ = 128
    static let maxED = 2048
    static let divider = 512
    var pubn: Int?
    var pube: Int?
    var prid: Int?

    init(){
        
    }
    
    func generateSymetricKey() -> Int{
        let lower = 128*256
        let upper = 256*256
        return Int.random(in: lower..<upper)
    }
    
    func printKeys(){
        print("pubn=\(pubn), pube=\(pube), prid=\(prid)")
    }
    
    func changeToAscii(plain: String) -> [Int] {
        // 문자열을 문자 하나씩 아스키코드로 변환하여 배열에 저장
        var asciiArray: [Int] = []
        for char in plain {
            if let asciiValue = char.asciiValue {
                asciiArray.append(Int(asciiValue))
            }
        }
        return asciiArray
    }
    
    func changeToString(intArray: [Int]) -> String { //아스키 -> string
        var resultString = ""
        
        for intValue in intArray {
            if let unicodeScalar = UnicodeScalar(intValue) {
                let character = Character(unicodeScalar)
                resultString.append(character)
            }
        }
        
        return resultString
    }

    
    func isPrime(n: Int) -> Bool{
        for i in 2..<n{
            if n % i == 0{
                return false
            }
        }
        return true
    }
    
    func hasCommonDivider(a: Int, b: Int) -> Bool{
        let c = min(a, b)
        for i in 2..<c{
            if a % i == 0 && b % i == 0{
                return true
            }
        }
        return false
    }
    
    func getPrimeNumbers(maxPrime: Int) -> [Int] {
        var primeNumbers: [Int] = []
        
        for i in 11...maxPrime{
            if isPrime(n: i){
                primeNumbers.append(i)
            }
        }
        return primeNumbers;
    }
    
    func getDisjoints(phiN: Int) -> [Int]{
        var disjointNumber: [Int] = []
        
        for i in 2..<phiN{
            if isPrime(n: i){
                if hasCommonDivider(a: i, b: phiN) == false{
                    disjointNumber.append(i)
                }
            }
        }
        return disjointNumber
    }
    
    func getTargetPrivateKeys(phiN: Int, e: Int) -> [Int]{
        var privateKeys: [Int] = []

        for k in 1..<1000{
            if (k*phiN+1) % e == 0{
                let d = (k*phiN+1)/e
                if d == e { continue }
                if d == 1{ continue }
                if d >= phiN {continue }
                privateKeys.append(d)
            }
            
        }
        return privateKeys
    }
    
    func findED(maxED: Int, p:Int, q: Int) -> [Int]?{
        
        let phiN = (p-1)*(q-1)
        
        // 가능한 모든 e를 찾는다
        let disjointNumbers = getDisjoints(phiN: phiN)
        
        var usedNumbersE : [Int] = []

        while true{
            
            var e: Int = 0
            while true{
                // 하나의 e를 랜덤하게 선택한다
                if usedNumbersE.count == disjointNumbers.count{
                    break
                }
                
                e = disjointNumbers.randomElement()!
                if e < maxED{
                    
                    if usedNumbersE.contains(e) == false{
                        usedNumbersE.append(e)
                        break
                    }
                }
                usedNumbersE.append(e)
            }
            
            // 더이상 선택할 수 없으면 빠져나온다
            if e == 0{
                break
            }
            
            // e와 phoiN에 대하여 가능한 모등 d를 찾는다
            let privateKeys = getTargetPrivateKeys(phiN: phiN, e: e)
            var usedNumbersD : [Int] = []
            
            while true{
                
                // 하나의 d를 선택한다
                if usedNumbersD.count == privateKeys.count{
                    break
                }
                let d = privateKeys.randomElement()!
                if d < maxED{
                    if usedNumbersD.contains(d) == false{
                        return [e, d]
                    }
                }
                usedNumbersD.append(d)
            }
        }
        return nil
    }
    
    func generateKeySet(maxPQ: Int, maxED: Int){ //가능한 e,d배열을 만들고 랜덤배당
        
        self.pubn = nil
        self.pube = nil
        self.prid = nil
       
        if maxPQ > RsaKey.maxPQ || maxED > RsaKey.maxED{
            return
        }
        
        let primeNumbers = getPrimeNumbers(maxPrime: maxPQ)
        var usedNumbersP : [Int] = []
        
        while true{
            if usedNumbersP.count == primeNumbers.count{
                break
            }
            var p: Int = 0
            while true{
                p = primeNumbers.randomElement()!
                if usedNumbersP.contains(p) == false{
                    break
                }
            }
            usedNumbersP.append(p)
            //print("ppp=\(p)")
            if p == 0{
                break
            }
            
            var q: Int = 0
            var usedNumbersQ : [Int] = [p]
            while true{
                q = primeNumbers.randomElement()!
                if usedNumbersQ.contains(q) == false{
                    break
                }
            }
            usedNumbersQ.append(q)
            if q == 0{
                break
            }
            
            //print("p=\(p), q=\(q)")
            if let ed = findED(maxED: maxED, p: p, q: q){
                self.pubn = p*q
                self.pube = ed[0]
                self.prid = ed[1]
                return
            }
        }
        //generateKeySet(maxPQ: maxPQ+10, maxED: maxED+128)
        
    }
    
    func encryptionByAsymmetricKey(plain: String, pubn: Int?, pube: Int?) -> String?{
        
        // 주어진 공개키로 암호화 한다.
        // 나의 위치를 다른사람(공개키의 주인)에게 보내기. 위하여 암호화 한다
        
        //문자 하나식 아스키코드로 변환 -> 공식
        guard let pubn = pubn, let pube = pube else {
            return nil
        }
        // 한글을 처리하기 위하여 url encoding
        guard let text = plain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else{ return nil }
        let asciiArray = changeToAscii(plain: text)
        

        // 각 요소를 pube 승한 뒤 pubn으로 나머지를 구하여 새로운 배열에 저장
        var encryptedArray: [Int] = []
        let bpube = BInt(pube)
        let bpubn = BInt(pubn)

        for ascii in asciiArray {

            let bvalue = BInt(ascii)
            
            let q = pube / RsaKey.divider
            let r = pube % RsaKey.divider
    
            var rr = BInt(1)
            for _ in 0..<q{
                rr *= ((bvalue ** RsaKey.divider) % bpubn)
            }
            rr *= ((bvalue ** r) % bpubn)
            
            
            var x = Int(rr % bpubn)

            encryptedArray.append(x)
        }
        
        // 암호화된 정수 배열이 encryptedArray에 들어 있다.
        // 그런데 이를 문자열로 바꾸기 위해서는 [Int] -> [UInt8]로 변환하고 그것을 base64 스트링으로 만든다.
        var encryptedArrayUInt8: [UInt8] = []
        for i in 0..<encryptedArray.count{
            let v = encryptedArray[i]
            let array = withUnsafeBytes(of: v.bigEndian, Array.init)
            encryptedArrayUInt8 = encryptedArrayUInt8 + array
        }
        let data = Data(encryptedArrayUInt8)
        let base64String = data.base64EncodedString()
        return base64String
    }

    
    func decryptionByAsymmetricKey(encryptedString: String ,pubn: Int?, pubd: Int?) -> String?{
        
        // 개인키로 복호화 한다
        // 무사히 복호가 된다면 나만을 위한 메시지가 된다.
        // 그렇지만 민서가 철수를 가장하고 영희에게 보낼수가 있다.
        // 철수가 보냈다는 것을 확신하기 위하여
        
        // 입력 문자열을 띄어쓰기로 구분하여 배열로 분할
        
        //문자 하나식 아스키코드로 변환 -> 공식
        //let asciiArray = changeToAscii(plain: plain)
        
        guard let pubn = pubn, let pubd = pubd else {
            return nil
        }
        
        // base64문자열인 encryptedString를 [UInt8]배열을 만들고 이를 [Int]로 만든다.
        let encryptedArrayUInt8 = [UInt8](Data(base64Encoded: encryptedString)!)
        var encryptedArray: [Int] = []
        for i in 0..<encryptedArrayUInt8.count/8{
            let array = encryptedArrayUInt8[i*8..<(i+1)*8]
            let data = Data(array)
            let value = Int(bigEndian: data.withUnsafeBytes { $0.pointee })
            encryptedArray.append(Int(value))
        }
        
        // [Int]에서 복호화를 한다.
        var decryptedArray: [Int] = []
        let bpubn = BInt(pubn)
        for value in encryptedArray {
            let q = pubd / RsaKey.divider
            let r = pubd % RsaKey.divider
            
            var rr = BInt(1)
            for _ in 0..<q{
                rr *= ((BInt(value) ** RsaKey.divider) % bpubn)
            }
            rr *= ((BInt(value) ** r) % bpubn)
            
            
            let x = Int(rr % bpubn)
            decryptedArray.append(x)
        }
        
        let decryptedString = changeToString(intArray: decryptedArray)
        return decryptedString.removingPercentEncoding

    }
    
    func convertToIntArray(stringArray: [String]) -> [Int] {
        let intArray = stringArray.compactMap { Int($0) }
        return intArray
    }

    
    func hashing(plain: String) -> String{
        
        var value: Int = 0
        for x in plain{
            value += Int(x.unicodeScalars.first!.value)
        }
        print("\(value)")
        value = value * value

        value %= 9967 // 소수
        return String(value)
    }
    
    func encryptionBySymetricKey(plain: String, key: Int) -> String{
        // 주어진 공개키로 암호화 한다.
        // 나의 위치를 다른사람(공개키의 주인)에게 보내기. 위하여 암호화 한다

        // 한글을 처리하기 위하여 url encoding
        guard let text = plain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else{ return "" }
        let asciiArray = changeToAscii(plain: text)
        
        // 각 요소를 pube 승한 뒤 pubn으로 나머지를 구하여 새로운 배열에 저장
        var encryptedArray: [Int] = []
        for ascii in asciiArray {
            encryptedArray.append(Int(ascii)*key)
        }

        var encryptedArrayUInt8: [UInt8] = []
        for i in 0..<encryptedArray.count{
            let v = encryptedArray[i]
            let array = withUnsafeBytes(of: v.bigEndian, Array.init)
            encryptedArrayUInt8 = encryptedArrayUInt8 + array
        }
        let data = Data(encryptedArrayUInt8)
        let base64String = data.base64EncodedString()
        return base64String
    }
    
    func decryptionBySymetricKey(encryptedString: String , key: Int) -> String?{
        
        // 개인키로 복호화 한다
        // 무사히 복호가 된다면 나만을 위한 메시지가 된다.
        // 그렇지만 민서가 철수를 가장하고 영희에게 보낼수가 있다.
        // 철수가 보냈다는 것을 확신하기 위하여
        
        // 입력 문자열을 띄어쓰기로 구분하여 배열로 분할
        
        //문자 하나식 아스키코드로 변환 -> 공식
        //let asciiArray = changeToAscii(plain: plain)

        if key == 0{
            return nil
        }
        
        // base64문자열인 encryptedString를 [UInt8]배열을 만들고 이를 [Int]로 만든다.
        let encryptedArrayUInt8 = [UInt8](Data(base64Encoded: encryptedString)!)
        var encryptedArray: [Int] = []
        for i in 0..<encryptedArrayUInt8.count/8{
            let array = encryptedArrayUInt8[i*8..<(i+1)*8]
            let data = Data(array)
            let value = Int(bigEndian: data.withUnsafeBytes { $0.pointee })
            encryptedArray.append(Int(value))
        }
        
        // [Int]에서 복호화를 한다.
        var decryptedArray: [Int] = []
        for value in encryptedArray {
            decryptedArray.append(value/key)
        }
        
        let decryptedString = changeToString(intArray: decryptedArray)
        return decryptedString.removingPercentEncoding

    }
}
