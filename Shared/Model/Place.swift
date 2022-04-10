//
//  Place.swift
//  IphonMapApp (iOS)
//
//  Created by 하명관 on 2022/04/10.
//

import SwiftUI
import MapKit

struct Place: Identifiable {
    
    var id = UUID().uuidString
    var placemark: CLPlacemark
    
}
