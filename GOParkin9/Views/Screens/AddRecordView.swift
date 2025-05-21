
//
//  AddRecordView.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 24/03/25.
//
import SwiftUI
import CoreLocation
import CoreLocationUI
import SwiftData


struct ModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingAlert = false
    @State private var showingAlertSave = false
    @State private var showingCamera = false
    @State private var isImageFullscreen = false
    @State private var selectedImage: UIImage?
    @State private var selectedFloor: String? = nil
    @State private var floors = ["Basement 1", "Basement 2"]
    let dateTime = Date.now
    
    @State private var parkingPillar = ""
    @State private var isPillarInvalid = false

    let savedLocation:CLLocation
    
    var isPillarValid: Bool {
        parkingPillar.range(of: "^[A-Z]+[0-9]+$", options: .regularExpression) != nil
    }

    
    @Environment(\.modelContext) var context

    func addParkingRecord(latitude: Double, longitude: Double, altitude: Double, images: [UIImage], floor:String, pillar:String) {
        let convertedImages = images.map { ParkingImage(image: $0) }
        
        let record = ParkingRecord(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            isHistory: false,
            floor: floor,
            pillar: pillar,
            createdAt: dateTime,
            images: convertedImages
        )
        
        context.insert(record)
        
        do {
            try context.save()
            print("Record added successfully!")
        } catch {
            print("Failed to save record: \(error)")
        }
    }

    @Query var parkingRecords: [ParkingRecord]
    
    @State private var images: [UIImage] = [] // State untuk menyimpan gambar

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button {
                    
                    if let selected = selectedFloor, isPillarValid {
                        print("Button clicked")
                            addParkingRecord(
                                latitude: savedLocation.coordinate.latitude,
                                longitude: savedLocation.coordinate.longitude,
                                altitude: savedLocation.altitude,
                                images: images,
                                floor: selected,
                                pillar: parkingPillar
                            )
                            dismiss()
                    } else {
                        if selectedFloor == nil {
                            showingAlertSave.toggle()
                        } else if !isPillarValid {
                            isPillarInvalid.toggle()
                        }
                    }
                    
                } label: {
                    Text("Done")
                }
                .disabled(!(selectedFloor != nil && isPillarValid))
                .alert("Invalid pillar format", isPresented: $isPillarInvalid) {
                    Button("OK") {}
                } message: {
                    Text("Pillar must contain 1 uppercase letter and 1 number (example: A1, B3).")
                }
            }
            .padding()
            
            VStack(alignment: .leading){
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Location saved!")
                    }.padding(.bottom)
                    HStack {
                        Image(systemName: "calendar")
                        Text(dateTime, format: .dateTime.day().month().year())
                    }.padding(.bottom)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text(dateTime, format: .dateTime.hour().minute())
                    }
                    HStack {
                        Image(systemName: "stairs")
                        Picker("On which floor is your vehicle parked?", selection: $selectedFloor) {
                            Text("Please select your parking floor").tag(nil as String?)
                            ForEach(floors, id: \.self) { floor in
                                Text(floor).tag(floor as String?)
                            }
                        }.pickerStyle(.menu)
                    }
                
                    HStack {
                        Image(systemName: "p.circle")
                        TextField("Enter parking pillar (example: A1)", text: $parkingPillar)
                            .textInputAutocapitalization(.characters)
                    }
                    .padding(.bottom)

                
                Text("Take up to 8 photos of your parking spot environment")
                    .padding(.vertical)
                GridView(images: $images, onSelectImage: { img in
                    selectedImage = img
                    isImageFullscreen = true
                }, isImageFullscreen: $isImageFullscreen)
                Spacer()
            }.padding()
            Spacer()
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { isImageFullscreen && selectedImage != nil },
                set: { isImageFullscreen = $0 }
            )
        ) {
            if let selectedImage = selectedImage {
                ImagePreviewView(imageName: selectedImage, isPresented: $isImageFullscreen)
            } else {
                Text("Image not found").foregroundColor(.white)
            }
        }
    }
        
}

struct ImagePreviewWrapper: View {
    var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    var body: some View {
        if let selectedImage {
            ImagePreviewView(imageName: selectedImage, isPresented: $isPresented)
        } else {
            Text("Image not found").foregroundColor(.white)
        }
    }
}

struct GridView: View {
    @Binding var images: [UIImage]
    var onSelectImage: (UIImage) -> Void
    @Binding var isImageFullscreen: Bool
//    @Binding var selectedImage: UIImage?
    
    @State private var showingCamera = false
    @State private var newImage: UIImage?

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(images.indices, id: \.self) { img in
                Image(uiImage: images[img])
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
                    .onTapGesture {
                        onSelectImage(images[img])
//                        isImageFullscreen.toggle()
                    }
                    .overlay(
                        Button(action: {
                            images.remove(at: img)
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.red)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .offset(x: -35, y: -35)
                    )
            }
            
            if images.count < 8 {
                Button(action: {
                    showingCamera.toggle()
                }) {
                    Rectangle()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Color.gray.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            Text("+").foregroundColor(.blue)
                                .font(.system(size: 35))
                        )
                }
                .fullScreenCover(isPresented: $showingCamera) {
                    CameraView(image: $newImage)
                        .ignoresSafeArea()
                }
                .onChange(of: newImage) { newValue in
                    if let newImage = newValue {
                        images.append(newImage)
                        self.newImage = nil
                    }
                }
            }
        }
        .padding()
        
    }
}

#Preview {
    ContentView()
}
