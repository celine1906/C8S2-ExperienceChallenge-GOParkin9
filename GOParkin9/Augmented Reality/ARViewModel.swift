//
//  ARViewModel.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 09/05/25.
//

import Foundation
import ARKit
import RealityKit
import Combine

enum ARState {
    case loading
    case loaded(ARView)
    case error
}

class ARViewModel: ObservableObject {
    @Published var state: ARState = .loading
    @Published var modelName: String = "arrow"

    var arrowEntity: Entity?
    var arrowAnchor: AnchorEntity?
    var arView: ARView?

    /// Load ARView and prepare the AR session
    func loadARView() {
        state = .loading

        Task { [weak self] in
            guard let self else { return }

            do {
                let arView = await ARView(frame: .zero)
                let config = ARWorldTrackingConfiguration()
                config.planeDetection = [.horizontal, .vertical]
                config.environmentTexturing = .automatic
                await arView.session.run(config)

                // Simpan arView
                self.arView = arView

                // Load arrow entity hanya sekali
                self.arrowEntity = try await Entity.init(named: modelName)

                await MainActor.run {
                    self.state = .loaded(arView)
                }

            } catch {
                await MainActor.run {
                    self.state = .error
                }
            }
        }
    }

    /// Update arrow direction and display in AR view
    func updateArrow(bearing: Double) async {
        guard let arView = arView,
              let arrowEntity = arrowEntity else { return }

        // Hapus anchor sebelumnya (jika ada)
        if let existingAnchor = arrowAnchor {
            await arView.scene.removeAnchor(existingAnchor)
        }

        // Buat anchor baru di posisi world (0, 0, 0)
        let anchor = await AnchorEntity(world: SIMD3<Float>(0, 0, 0))
        let arrowClone = await arrowEntity.clone(recursive: true)

        // Arahkan panah berdasarkan bearing
        let yawInRadians = Float(bearing * .pi / 180)
        let rotation = simd_quatf(angle: yawInRadians, axis: [0, 1, 0])
        await MainActor.run {
            arrowClone.transform.rotation = rotation
            arrowClone.transform.translation = SIMD3<Float>(0, 0, -1)
        }
        // Tambahkan ke anchor dan scene
        await anchor.addChild(arrowClone)
        await arView.scene.anchors.append(anchor)

        // Simpan referensi anchor terakhir
        arrowAnchor = anchor
    }
}
