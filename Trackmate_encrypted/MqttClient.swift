//
//  MqttClient.swift
//  TrackMateEX
//
//  Created by 김도은 on 2023/08/08.
//


import CocoaMQTT
import Foundation

////MQTT 5.0
class MqttClient: CocoaMQTT5Delegate{
    
    var onMessageCompletion: ((String, [UInt8]) -> Void)?
    var afterConnect: (() -> Void)?
    var onPublish: ((String)->Void)?

    func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
        
        if let inform = afterConnect{
            inform()
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
        //print("didPublishMessage")
        if let onPublish = onPublish{
            onPublish(message.topic)
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
        //print("didPublishAck")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
        //print("didPublishRec")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
        if let deliveryMessage = onMessageCompletion{
            deliveryMessage(message.topic, message.payload)
        }
    }
    
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
        //print("didSubscribeTopics")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: Dictionary<String, Any>, failed: [String], subAckData: MqttDecodeSubAck?) {
    //print("didSubscribeTopics")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], UnsubAckData: MqttDecodeUnsubAck?) {
        //print("didUnsubscribeTopics")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
        //print("didReceiveDisconnectReasonCode")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        //print("didReceiveAuthReasonCode")
    }
    
    func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
        //print("mqtt5DidPing")
    }
    
    func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
        //print("mqtt5DidReceivePong")
    }
    
    func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: Error?) {
        //print("mqtt5DidDisconnect")
    }
    

    
    let mqtt5: CocoaMQTT5!
    
    init(brokerAdress: String){
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        // let clientID = "doeun"

        mqtt5 = CocoaMQTT5(clientID: clientID, host: brokerAdress, port: 1883)

        let connectProperties = MqttConnectProperties()
        connectProperties.topicAliasMaximum = 0
        connectProperties.sessionExpiryInterval = 0
        connectProperties.receiveMaximum = 60000
        connectProperties.maximumPacketSize = 60000
        mqtt5.connectProperties = connectProperties

        mqtt5.username = "dony"
        mqtt5.password = "dony"
        mqtt5.willMessage = CocoaMQTT5Message(topic: "cctv", string: "This is a cctv") // CocoaMQTTWill(topic: "/will", message: "dieout")
        mqtt5.keepAlive = 180
        mqtt5.delegate = self
    
    }
    
    func onMessage(completion: @escaping (String, [UInt8]) -> Void){
        onMessageCompletion = completion
    }
    
    func connect(completion: @escaping () -> Void) -> Bool{
        afterConnect = completion

        return mqtt5.connect()
    }
    
    func subscribe(topic: String){
        //print("subscribe \(topic)")
        mqtt5.subscribe(topic, qos: .qos0)
        //print("after subscribe")
    }
    
    func publish(topic: String, message:String, onPublish: ((String) -> Void)? = nil){
        //print("publish")
        self.onPublish = onPublish
        let publishProperties = MqttPublishProperties()
        publishProperties.contentType = "JSON"
        mqtt5.publish(topic, withString: message, qos: .qos1, DUP: false, retained: false, properties: publishProperties)
        //print("after publish")
    }
    
    func unscribe(topic: String){
        mqtt5.unsubscribe(topic)
    }
    
    func disconnect(){
        mqtt5.disconnect()
    }
}


