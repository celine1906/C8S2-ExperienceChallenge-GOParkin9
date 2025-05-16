//
//  ARModalViewModel.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 14/05/25.
//

import Foundation
import SwiftUI
import CoreLocation

class ARModalViewModel: ObservableObject {
    @Published var destination: destinationData?

    func updateDestination(from record: ParkingRecord, currentLocation: CLLocation) {
        let destinationCoordinate = CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude)
        let distance = currentLocation.distance(from: CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude))
        let formatted = distance > 999 ? String(format: "%.2f km", distance / 1000) : "\(Int(distance)) m"

        let image = record.images.first?.getImage()
        
        self.destination = destinationData(
            latitude: record.latitude,
            longitude: record.longitude,
            altitude: record.altitude,
            images: image,
            distance: formatted
        )
    }
}
