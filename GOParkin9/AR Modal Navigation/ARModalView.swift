//
//  ModalView.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 13/05/25.
//

import SwiftUI
import SwiftData

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ARModalView: View {
    @Environment(\.modelContext) private var context
    @State var showModal: Bool = true
    @StateObject private var locationManager = NavigationManager()
    @StateObject var modalViewModel = ARModalViewModel()
    @Query(filter: #Predicate<ParkingRecord> { $0.isHistory == false }) var parkingRecords: [ParkingRecord]

    var body: some View {
        ZStack {
            if showModal {
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            if let destination = modalViewModel.destination {
                                altitudeComponent(data: destination)
                            }
                            Spacer()
                            Button(action: {
                                showModal.toggle()
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.black)
                                    .padding(8)
                            }
                        }

                        if let destination = modalViewModel.destination {
                            destinationComponent(data: destination)
                        }
                    }
                    .ignoresSafeArea()
                    .frame(alignment: .bottom)
                    .padding().padding(.bottom)
                    .background(Color.white)
                    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
                    .shadow(radius: 10)
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .bottom))
                }
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showModal.toggle()
                        }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                        .padding()
                    }
                    .padding()
                }
            }
        }
        .onReceive(locationManager.$location) { location in
            guard let userLocation = location,
            let record = parkingRecords.first else { return }
            modalViewModel.updateDestination(from: record, currentLocation: userLocation)
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.easeInOut, value: showModal)
    }
}


struct destinationComponent: View {
    var data: destinationData

    var body: some View {
        HStack {
            if let image = data.images {
                Image(uiImage: image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(data.distance)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text("to your vehicle")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(Color.secondary3.opacity(0.2))
        .cornerRadius(10)
    }
}


struct altitudeComponent: View {
    var data: destinationData

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "parkingsign.radiowaves.left.and.right")
                .foregroundColor(.gray)
            Text(data.floor)
                .font(.subheadline)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


