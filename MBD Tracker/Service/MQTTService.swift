//
//  MQTTService.swift
//  MBD Tracker
//
//  Created by Soeng Saravit on 12/8/21.
//

import CocoaMQTT

class MQTTService {
    
    var mqtt: CocoaMQTT?
    final let username = "zzxb"
    final let password = "1234"
    final let host = "147.182.226.231"
    final let port:UInt16 = 1883
    var isConnected = false
    
    init() {
        let clientID = "MBDTracker_" + String(ProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientID: clientID, host: host, port: port)
        mqtt?.username = username
        mqtt?.password = password
        mqtt?.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        mqtt?.keepAlive = 120
        isConnected = mqtt!.connect()
        mqtt?.didPublishMessage = {mqtt, message, id in
            print("MQTT: message published")
        }
        mqtt?.didConnectAck = {mqtt, ack in
            print("MQTT: connected")
            mqtt.publish(CocoaMQTTMessage(topic: "heart-rate", string: "[test] ready to publish"))
        }
        mqtt?.didDisconnect = {mqtt, error in
            print("MQTT: disconnected - " + error!.localizedDescription)
            self.isConnected = false
        }
    }
    
    func publishMessageToBroker(payload:[String:Any]) {
        if !isConnected {
            isConnected = self.mqtt!.connect()
        }
        let data = try? JSONSerialization.data(withJSONObject: payload, options: [])
        let payload = String(data: data!, encoding: .utf8)
        let message = CocoaMQTTMessage(topic: "heart-rate", string: payload!)
        mqtt?.publish(message)
    }
}
