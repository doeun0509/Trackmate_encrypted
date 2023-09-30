//
//  MapExMqttViewController.swift
//  TrackMateEX
//
//  Created by 김도은 on 2023/08/10.
//
import UIKit
import NMapsMap
import CoreLocation


extension MapViewController{ //mqtt
    
    
    
    func initMqtt(){
        let brokerAddress =  "mqtt-dashboard.com" //"broker.hivemq.com"

        
        if let mqttClient = mqttClient{ //이미 연결되어있으면
            mqttClient.disconnect()
        }

        mqttClient = MqttClient(brokerAdress: brokerAddress)
        mqttClient?.onMessage(completion: onMessage) //메시지 수신 감지 후 onmessage 함수 실행

        _ = mqttClient?.connect(){

            self.mqttClient?.subscribe(topic: "who")
            self.mqttClient?.subscribe(topic: "requestSymetricKey")
            self.mqttClient?.subscribe(topic: "responseSymetricKey")
            self.mqttClient?.subscribe(topic: "location")
            self.mqttClient?.subscribe(topic: "leave")
        }
    }
    
    func onMessage(topic: String, payload: [UInt8]){
        
        let raw = Data(bytes: payload, count: payload.count)
        //let data = Data(base64Encoded: raw)
        let string = String(data: raw, encoding: .utf8)
        
        if topic == "requestSymetricKey"{
            
            if let message = String(data: raw, encoding: .utf8) {
                responseSymetricKey(message: message)
            }
        }
                    
        if topic == "responseSymetricKey"{
            
            if let message = String(data: raw, encoding: .utf8) {
                receiveSymetricKey(message: message)
            }
        }
        
        if topic=="who"{
            
            if let message = String(data: raw, encoding: .utf8) {
                receiveMateName(message: message , adding: true)
            }
        }
        
        else if topic == "leave"{
            if let message = String(data: raw, encoding: .utf8) {
                receiveMateName(message: message , adding: false)
            }
        }
        
        else if topic == "location"{
            if let string = string{
                receiveLocation(message: string)
            }
        }
    }
    
    
    func finalMqtt(){
        
        DispatchQueue.global().async {
            self.mqttClient?.publish(topic: "leave", message: "\(self.userName!)"){
                (topic: String) in
                if topic == "leave"{
                    sleep(1)
                    self.mqttClient?.disconnect()
                    self.mqttClient = nil
                    print("=====================")
                }
            }
        }
    }

    func requestSymetricKey(){
        guard let mqttClient = mqttClient else { return }
        guard let userName = userName else { return }
                           
        for (mateName, mateInfo) in mates{
            if mateInfo.receivedKey == 0{
                let message = "\(mateName):\(userName)"
                printInforamtion(information: message + " in requestSymetricKey")
                mqttClient.publish(topic: "requestSymetricKey", message: message)
            }
        }
    }
    
    func responseSymetricKey(message: String){
        guard let mqttClient = mqttClient else { return }
        guard let userName = userName else { return }
        
        // 받아야할 사람:보밴사람
        let components = message.split(separator: ":")
        if components.count != 2{
            return
        }
        
        let target = String(components[0])  // 받아야하는 사람
        let sender = String(components[1])  // 보낸사람
        
        if target != userName{   // 받아야하는 사람이 내가 아니면
            return
        }
        
        if let mateInfo = mates[sender]{
            
            if mateInfo.sentKey == 0{
                mateInfo.sentKey = rsa.generateSymetricKey()
            }
            
            let message = "\(sender):\(userName):\(mateInfo.sentKey)"
            printInforamtion(information: message + " in responseSymetricKey")
            let encryptStr = rsa.encryptionByAsymmetricKey(plain: message, pubn: mateInfo.pubn, pube: mateInfo.pube)!
            mqttClient.publish(topic: "responseSymetricKey", message: encryptStr)
        }
    }
    
    func receiveSymetricKey(message: String){
        
        guard let userName = userName else { return }
        let decryptStr = rsa.decryptionByAsymmetricKey(encryptedString: message, pubn: pubn, pubd: prid)!
        
        // 받아야하는 사람: 보낸사람: key
        let components = decryptStr.split(separator: ":")
        if components.count != 3{
            return
        }
        
        let target = String(components[0])  // 받아야하는 사람
        let sender = String(components[1])  // 보낸사람
        
        if userName == sender{   // 내가 보낸사람이면 사람이면 무시
            return
        }
        
        if userName != target{   // 내게 온 것이 아니면 무시
            return
        }

        if let mateInfo = mates[sender]{
            let key = Int(components[2])!
            self.printInforamtion(information: "1(\(sender):\(key) in receiveSymetricKey")
            mateInfo.receivedKey = key
            //reloadTable() // for testing
        }

    }

    func sendUserName(){
        
        guard let mqttClient = mqttClient else { return }
        guard let userName = userName else{ return }
        //guard let myInfo = mates[myName] else { return }
        let message = "\(userName):\(userInfo.pubn):\(userInfo.pube)"
        mqttClient.publish(topic: "who", message: message)
        
    }
    
    func receiveMateName(message: String, adding: Bool){
        
        // 친구이름:공용키1:공개키2
        let components = message.split(separator: ":")

        let mateName = String(components[0])
        
        if adding {
            
            if components.count != 3{
                return
            }
            if mateName == userName {
                return
            }
            
            let pubn = Int(components[1])!
            let pube = Int(components[2])!
            
            if mates[mateName] == nil{ // 새로 들어온 친구 이면
                mates[mateName] = MateInfo(false, pubn, pube)   // select, pubkeyn, kupkey
                printInforamtion(information: "new mate '\(mateName)' arrived")
                reloadTable()
            }
            mates[mateName]?.lastAccessTime = Int(Date().timeIntervalSince1970)
        }
        
        else{
            
            removeMarkerWithTitle(title: mateName)
            mates.removeValue(forKey: mateName)
            reloadTable()
        }
    }
    
    func sendLocation(location: CLLocation, alarm: Bool){
        
        guard let mqttClient = mqttClient else { return }
        guard let userName = userName else { return }
        
        for (mateName, mateInfo) in mates { //테이블뷰에서 선택된 사람의 공개키로만 암호화
            if mateInfo.sentKey == 0 || mateInfo.receivedKey == 0{
                continue
            }
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let mark = mateInfo.selected ? 1: 0
            
            let message = "\(mateName) \(latitude) \(longitude) \(mark)"
            let encryptedStr = rsa.encryptionBySymetricKey(plain: message, key: mateInfo.sentKey)
            mqttClient.publish(topic: "location", message: "\(userName)@@@@@" + encryptedStr)
        }
    }
    
    func receiveLocation(message: String){

        //printInforamtion(information: message + " in receiveLocation")
        let msgs = message.components(separatedBy: "@@@@@")
        if msgs.count != 2{
            return
        }
        
        let fromName = String(msgs[0])  // 보내사람
        
        if let mateInfo = mates[fromName]{
            guard let decryptedStr = rsa.decryptionBySymetricKey(encryptedString: msgs[1], key: mateInfo.receivedKey) else{
                return
            }
            let components = decryptedStr.components(separatedBy: " ")
            if userName == String(components[0]){
                if let latitude = Double(components[1]), let longitude = Double(components[2]){
                    if Int(components[3]) == 1{
                        handlePositionUpdate(mate: fromName, latitude: latitude, longitude: longitude)
                    }else{
                        removeMarkerWithTitle(title: fromName)
                    }
                }
            }
        }
    }
}
