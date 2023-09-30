//
//  MapMarkerViewController.swift
//  TrackMateEX
//
//  Created by iOSprogramming on 2023/08/15.
//

import UIKit
import NMapsMap
import CoreLocation


extension MapViewController{
    
    // 위치 정보를 받아서 마커를 업데이트하는 함수
    func updateMarkerForUser(name: String, latitude: Double, longitude: Double) {
        // 이미 해당 이름의 마커가 존재하는지 확인
        //let markerColors = [UIColor.red, UIColor.blue, UIColor.green, UIColor.orange,UIColor.cyan,UIColor.darkGray, UIColor.black, UIColor.magenta, UIColor.purple,UIColor.systemPink,UIColor.systemYellow]

        
        if let marker = markers[name] {
            // 마커의 위치 업데이트
            let position = NMGLatLng(lat: latitude, lng: longitude)
            marker.position = position
            return
        }
        
        // 새로운 마커 생성
        let position = NMGLatLng(lat: latitude, lng: longitude)
        let marker = MYMarker(name: name)
        marker.position = position
        marker.mapView = mapView

        marker.showInfoWindow()
        markers[name] = marker
        

    }
    
    func removeMarkerWithTitle(title: String) {
        if let markerToRemove = markers[title] {
            markerToRemove.mapView = nil // 해당 마커를 지도에서 제거
            markers.removeValue(forKey: title) // 마커 딕셔너리에서 해당 마커 엔트리 제거
        }
    }
    
    // 위치 정보 업데이트를 수신받아 처리하는 함수
    func handlePositionUpdate(message: String) {

        let components = message.components(separatedBy: ", ")
        guard components.count >= 3,
              let userName = components.first?.split(separator: ":").last,
              let latitudeStr = components[1].split(separator: ":").last,
              let longitudeStr = components[2].split(separator: ":").last,
              let latitude = Double(latitudeStr),
              let longitude = Double(longitudeStr)
        else {
            return
        }
        
        DispatchQueue.main.async {
            self.updateMarkerForUser(name: String(userName), latitude: latitude, longitude: longitude)
        }
    }
    
    func handlePositionUpdate(mate: String, latitude: Double, longitude: Double) {

        DispatchQueue.main.async {
            self.updateMarkerForUser(name: mate, latitude: latitude, longitude: longitude)
        }
    }
}

final class MYMarker: NMFMarker {
    
    let name: String // Name 프로퍼티 추가
    
    let markerImages: [UIImage] = [
        UIImage(named: "dog1.png")!,
        UIImage(named: "dog2.png")!,
        UIImage(named: "dog3.png")!,
        UIImage(named: "dog4.png")!,
        UIImage(named: "dog5.png")!,
        UIImage(named: "dog6.png")!,
        UIImage(named: "dog7.png")!,
        UIImage(named: "dog8.png")!,
        // Add more image names as needed
    ]

    
    let mateInfoWindow = NMFInfoWindow()
    
    init(name: String) {
        self.name = name
        super.init()
        setUI()
        setInfoWindow()
    }
}

extension MYMarker {

    
    private func setUI() {
        let randomImageIndex = Int.random(in: 0..<markerImages.count)
        let randomImage = markerImages[randomImageIndex]
        let image = NMFOverlayImage(image: randomImage)
        self.iconImage = image
        
        self.width = CGFloat(NMF_MARKER_SIZE_AUTO)
        self.height = CGFloat(NMF_MARKER_SIZE_AUTO)
        
        self.anchor = CGPoint(x: 0.5, y: 0.5)
        
        self.iconPerspectiveEnabled = true
    }
    
    private func setInfoWindow() {
        mateInfoWindow.dataSource = self
        
       // print("setInfoWindow")
    }
    
    func showInfoWindow() {
        mateInfoWindow.open(with: self)
       // print("showInfoWindow")
    }
    
    func hideInfoWindow() {
        mateInfoWindow.close()
    }
}

// MARK: - NMFOverlayImageDataSource

extension MYMarker: NMFOverlayImageDataSource {
    func view(with overlay: NMFOverlay) -> UIView {
        // 마커 위에 보여줄 InfoView 이미지 리턴
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 58, height: 50))
        imageView.image = UIImage(named: "signboard.png")!
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 10, width: 58, height: 50))
        titleLabel.text = name
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "Yeongdeok Snow Crab", size: 14)
        titleLabel.textColor = .white
        imageView.addSubview(titleLabel)
        //print("view return")
        return imageView
    }
}
