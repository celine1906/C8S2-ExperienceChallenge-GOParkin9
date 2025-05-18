//
//  ShortcutsIntent.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 16/05/25.
//


import AppIntents
import UIKit
import CoreLocation
import SwiftData
import IntentsUI

// pilihan lantai parkir
enum Floor: String, AppEnum {
    case basement1, basement2
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Your Parking Floor"
    }

    static var caseDisplayRepresentations: [Floor : DisplayRepresentation] {
        [
            .basement1: "Basement 1",
            .basement2: "Basement 2"
        ]
    }
    
    var displayString: String {
        switch self {
        case .basement1: return "Basement 1"
        case .basement2: return "Basement 2"
        }
    }
}


struct AppIntentShortcutProvider: AppShortcutsProvider {
    
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SaveLocation(),
                    phrases:[
                        "Save parking location in \(.applicationName)",
                        "Remember where I parked in \(.applicationName)",
                        "Save my car location in \(.applicationName)",
                        "I parked my car, save it in \(.applicationName)",
                        "Mark my parking spot in \(.applicationName)"
                    ]
                    ,shortTitle: "Save Location", systemImageName: "mappin.and.ellipse")
        
        AppShortcut(intent: Navigate(),
                    phrases: [
                        "Navigate to my vehicle in \(.applicationName)",
                        "Where did I park? Use \(.applicationName)",
                        "Take me to my car using \(.applicationName)",
                        "Find my parking spot in \(.applicationName)",
                        "Help me find my car in \(.applicationName)"
                    ]
                    ,shortTitle: "Navigate", systemImageName: "location")
        
    }
    
}



struct SaveLocation: AppIntent {
    @Parameter(title: "Parking Floor") var floor: Floor
    @Parameter(title: "Parking Pillar") var pillar: String
  
    static var title: LocalizedStringResource = LocalizedStringResource("SaveLocation")
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        guard CLLocationManager.locationServicesEnabled(),
              let location = locationManager.location else {
            throw NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location not available."])
        }
        // Simpan langsung ke model context
        let container = try ModelContainer(for: ParkingRecord.self)
        let context = await container.mainContext
        
        let fetch = FetchDescriptor<ParkingRecord>(
            predicate: #Predicate { $0.isHistory == false }
        )

        let records = try context.fetch(fetch)
               
       let record = ParkingRecord(
           latitude: location.coordinate.latitude,
           longitude: location.coordinate.longitude,
           altitude: location.altitude,
           isHistory: false,
           floor: floor.displayString,
           pillar: pillar,
           createdAt: Date.now,
           images: []
       )
        
        if let existingRecord = records.first {
            // Update properti record lama
            existingRecord.latitude = location.coordinate.latitude
            existingRecord.longitude = location.coordinate.longitude
            existingRecord.altitude = location.altitude
            existingRecord.floor = floor.displayString
            existingRecord.pillar = pillar
            existingRecord.createdAt = Date.now
            existingRecord.images = [] // kosongkan atau biarkan seperti sebelumnya
        } else {
            // Insert baru jika tidak ada
            context.insert(record)
        }

        
        try context.save()
        
        return .result(
            dialog: "Your parking location has been saved",
            view: ResponseView(icon: "mappin.and.ellipse", message: "Parking Location Saved", description: "at \(floor.displayString), close to \(pillar) pillar", color: .secondary3)
        )
    }
}

struct Navigate: AppIntent {
    static var title: LocalizedStringResource = "Navigate"
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try ModelContainer(for: ParkingRecord.self)
        let context = await container.mainContext

        let fetch = FetchDescriptor<ParkingRecord>(
            predicate: #Predicate { $0.isHistory == false }
        )

        let records = try context.fetch(fetch)

        if records.isEmpty {
            print("⚠️ No active parking record found.")
            return .result(
                dialog: "There is no active parking record saved",
                view: ResponseView(icon: "mappin.slash", message: "No Active Parking", description: nil, color: .red)
            )
        } else {
            print("✅ Parking record found, triggering navigation.")
            UserDefaults.standard.set(true, forKey: "navigateToAR")
            return .result(
                dialog: "Navigating you to your vehicle"
            )
        }
    }
}
