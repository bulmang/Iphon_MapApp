//
//  MapViewModel.swift
//  IphonMapApp (iOS)
//
//  Created by 하명관 on 2022/04/09.
//

import SwiftUI
import MapKit
import CoreLocation

// 모든 지도의 데이터를 가져온다

class MapViewModoel: NSObject,ObservableObject,CLLocationManagerDelegate{
    
    @Published var mapView = MKMapView()
    
    // 지역
    @Published var region : MKCoordinateRegion!
    // 기본 위치 설정
    
    // 알람
    @Published var permissionDenied  = false
    
    
    // Map Type..
    @Published var mapType : MKMapType = .standard
    
    // SearchText
    @Published var searchText = ""
    
    // searched place
    @Published var places: [Place] = []
    
    
    // Updating Map Type..
    
    func updateMapType(){
        
        if mapType == .standard{
            mapType = .hybrid
            mapView.mapType = mapType
        }
        else{
            mapType = .standard
            mapView.mapType = mapType
        }
    }
    
    // Focus Location
    
    func focusLocation(){
        
        guard let _ = region else{return}
            
            mapView.setRegion(region, animated: true)
            mapView.setVisibleMapRect(mapView.visibleMapRect, animated: true)
    }
    
    // search place
    
    func searchQuery(){
        
        places.removeAll()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        // fetch
        MKLocalSearch(request: request).start { (response, _) in
            
            guard let result = response else{return}
            
            self.places = result.mapItems.compactMap({ (item) -> Place? in
                return Place(placemark: item.placemark)
            })
        }
    }
    
    // Pick Search Result..
    
    func selectPlace(place: Place){
        
        // Showing Pin on Map
        
        searchText = ""
        
        guard let coordinate = place.placemark.location?.coordinate else{return}
        
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate
        pointAnnotation.title = place.placemark.name ?? "No Name"
        
        // Removing All Old ones..
        mapView.removeAnnotations(mapView.annotations)
        
        mapView.addAnnotation(pointAnnotation)
        
        // Moving Map To that location
        
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.setVisibleMapRect(mapView.visibleMapRect, animated: true)
    }
    
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            
        // 권한 확인
        
        switch manager.authorizationStatus {
        case .denied:
            // 알람
            permissionDenied.toggle()
        case .notDetermined:
            // 요청
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // 허가 받은 상황
            manager.requestLocation()
        default:
            ()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // 에러
        print(error.localizedDescription)
    }
    
    // 사용자 지역 가져오기
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let location = locations.last else{return}

        self.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)

        // 지도 업데이트
        self.mapView.setRegion(self.region, animated: true)

        // 부드러운 애니메이션
        self.mapView.setVisibleMapRect(self.mapView.visibleMapRect, animated: true)
    }
    
    
}
