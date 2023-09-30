//
//  MapExLocationManagerViewController.swift
//  TrackMateEX
//
//  Created by 김도은 on 2023/08/10.
//

import UIKit
import NMapsMap
import CoreLocation

extension MapViewController: CLLocationManagerDelegate{
    
    func initLocationManager(){
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation() //didUpdateLocations을 지속적으로 요청
        
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: locationManager.location?.coordinate.latitude ?? 0, lng: locationManager.location?.coordinate.longitude ?? 0))
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)

        
        let locationOverlay = mapView.locationOverlay
        locationOverlay.iconWidth = 100
        locationOverlay.iconHeight = 100
        locationOverlay.hidden = true
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
          //location5
          switch status {
          case .authorizedAlways, .authorizedWhenInUse:
              print("GPS 권한 설정됨")
              self.locationManager.startUpdatingLocation() // 중요!
          case .restricted, .notDetermined:
              print("GPS 권한 설정되지 않음")
              //getLocationUsagePermission()
          case .denied:
              print("GPS 권한 요청 거부됨")
              //getLocationUsagePermission()
          default:
              print("GPS: Default")
          }
      }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 위치 정보 업데이트 시 호출되는 함수, 마지막에 가장가까운 위치 정보가 들어 있음
        guard let newLocation = locations.last else { return }

        movingDistance = 100.0
        if let currentLocation = currentLocation {
            movingDistance = newLocation.distance(from: currentLocation)
        }
        currentLocation = newLocation
    }
    
    func finalLocationManager(){
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        currentLocation = nil
    }
}
