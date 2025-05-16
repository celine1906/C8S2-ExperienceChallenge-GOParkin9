//
//  ParkingRecord.swift
//  GOParkin9
//
//  Created by Rico Tandrio on 21/03/25.
//

import Foundation
import SwiftData
import CoreLocation
import UIKit

@Model
class ParkingRecord: Identifiable {
    var id: UUID = UUID()
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var isHistory: Bool
    var isPinned: Bool
    var createdAt: Date
    var completedAt: Date
    var floor: String
    
    @Relationship(deleteRule: .cascade) var images: [ParkingImage] = []
    
    init (
        latitude: Double,
        longitude: Double,
        altitude: Double,
        isHistory: Bool,
        floor: String,
        createdAt: Date,
//        completedAt: Date,
        images: [ParkingImage]
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.isHistory = false
        self.isPinned = false
        self.createdAt = Date()
        self.completedAt = Date()
        self.images = images
        self.floor = floor
    }
}

struct destinationData: Identifiable {
    var id: UUID = UUID()
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var images: UIImage?
    var distance: String
}
