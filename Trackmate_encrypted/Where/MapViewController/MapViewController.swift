//
//  ViewController.swift
//  HiTrackMate
//
//  Created by 김도은 on 2023/06/16.
//

import UIKit
import NMapsMap
import CoreLocation


class MateInfo{
    var selected: Bool
    var pubn: Int
    var pube: Int
    var sentKey: Int
    var receivedKey: Int
    var lastAccessTime: Int?
    
    init(_ seledted: Bool, _ pubn: Int, _ pube: Int){
        self.selected = seledted
        self.pubn = pubn
        self.pube = pube
        self.sentKey = 0
        self.receivedKey = 0
    }
}

class MapViewController: UIViewController{
    
    var mqttClient: MqttClient?     
    var userName: String?
    var userInfo: MateInfo!
    var mates: [String: MateInfo] = [:] // Any : [선택여부, 공개키N, 공개키e]가 들어갈 것임
    
    // 마커 관리를 위한 딕셔너리
    var markers: [String: NMFMarker] = [:]
    @IBOutlet weak var information: UITextView!
    @IBOutlet var mapView: NMFMapView!
    
    let tableView = UITableView()

    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var movingDistance: CLLocationDistance?
    let rsa = RsaKey()
    
    //복호화에 사용
    var prid:Int?
    var pubn:Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initMapView()
        initTableView()
        information.text = ""

    }
    
    override func viewDidAppear(_ animated: Bool) {
        letsGo()
    }
    override func viewWillDisappear(_ animated: Bool) {
        finalLocationManager()
        finalMqtt()
        
        print("call will disappear")
    }
    override func viewDidDisappear(_ animated: Bool) {
        print("call did disappear")
    }

    @objc func dismissKeyboard(sender: UITapGestureRecognizer){
        mapView.endEditing(false)
    }
    
    @objc func buttonTapped() {
        print("버튼이 클릭되었습니다.")
        performSegue(withIdentifier: "Search", sender: self)

    }
    
    func initMapView(){
        mapView.positionMode = .direction
        mapView.zoomLevel=12
    }


    var inputUserNameAlert: UIAlertController?
    @objc func alertTextFieldDidChange(_ sender: UITextField) {
        inputUserNameAlert?.actions[0].isEnabled = sender.text!.count > 0
    }
    
    func letsGo(){
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1초 딜레이
            //닉네임 입력 알림창
            let alertTitle = "어서오세요"
            let alertmsg = "사용할 닉네임을 입력하세요"

            self.inputUserNameAlert = UIAlertController(title: alertTitle, message: alertmsg, preferredStyle: .alert)
            self.inputUserNameAlert?.addTextField(){ (textField) in
                textField.placeholder = "사용자 닉네임"
                textField.isSecureTextEntry = false
                textField.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
            }
            
            let confirm = UIAlertAction(title: "확인", style: .default){ (_) in
                //확인을 클릭했을때 처리할 내용
                if let txt = self.inputUserNameAlert?.textFields?[0]{
                    if txt.text?.isEmpty != true {
                        //사용자 키발급 및 초기화
                        
                        self.rsa.generateKeySet(maxPQ: 128, maxED: 128)
                        self.rsa.printKeys()
                        
                        self.userName = txt.text!
                        
//                        self.mates[self.userName!] = MateInfo(true, self.rsa.pubn!, self.rsa.pube!) //자기자신은 selected
//                        self.mates[self.userName!]?.sentKey = self.rsa.generateSymetricKey()
//                        self.mates[self.userName!]?.receivedKey = self.mates[self.userName!]!.sentKey

                        self.userInfo = MateInfo(true, self.rsa.pubn!, self.rsa.pube!) //자기자신은 selected
                        self.userInfo.sentKey = self.rsa.generateSymetricKey()
                        self.userInfo.receivedKey = self.userInfo.sentKey
                        
                        self.prid = self.rsa.prid! //개인키
                        self.pubn = self.rsa.pubn!
                        
                        print("metes.count=\(self.mates.count)")
                        
                        self.tableView.reloadData()
                        self.initLocationManager()
                        self.initMqtt()
                        self.startSender()
                    }
                }
            }
            confirm.isEnabled = false
            self.inputUserNameAlert?.addAction(confirm)
            self.present(self.inputUserNameAlert!, animated: true)
        }
        
    }
    
    func startSender(){
        
        DispatchQueue.global().async {
            var ticker = 0
            while(true){
                Thread.sleep(forTimeInterval: 1)    // 매 1초간 잔다

                guard let _ = self.userName else { continue }
                guard let _ = self.mqttClient else { continue }
                guard let currentLocation = self.currentLocation else { continue }

                self.sendUserName()
                
                if ticker % 2 == 0{
                    self.sendLocation(location: currentLocation, alarm: true)
                    
                    DispatchQueue.main.async {
                        let latitude = currentLocation.coordinate.latitude
                        let longitude = currentLocation.coordinate.longitude
                        self.updateMarkerForUser(name: self.userName!, latitude: latitude, longitude: longitude)
                    }
                }
                
                ticker += 1
                
                self.requestSymetricKey()

                for (mateName, mate) in self.mates{
                    if let lastAccessTime = mate.lastAccessTime{
                        if Int(Date().timeIntervalSince1970) - lastAccessTime > 5{
                            DispatchQueue.main.async {
                                self.mates.removeValue(forKey: mateName)
                                self.tableView.reloadData()
                                self.printInforamtion(information: "delete \(mateName)")
                                self.removeMarkerWithTitle(title: mateName)
                            }
                        }
                    }
                }
            }
        }
    }

    
    var informationArray: [String] = []
    var informationCount: Int = 0
    func printInforamtion(information: String){
        
        if informationArray.count >= 10{
            informationArray.remove(at: 0)
        }
        informationArray.append(information)
        informationCount += 1
        var str = ""
        for i in 0..<self.informationArray.count{
            str += (String(informationCount - self.informationArray.count + i) + "-" + self.informationArray[i] + "\n")
        }
        DispatchQueue.main.async {
            self.information.text = str
        }
    }
}



