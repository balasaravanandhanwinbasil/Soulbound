//
//  CameraView.swift
//  The Game
//
//  Created by Balasaravanan Dhanwin Basil  on 2/8/25.
//

import SwiftUI
import AVFoundation
import Vision
import SpriteKit

// MARK: - UIKit Camera ViewController

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var session: AVCaptureSession?
    var output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        checkCameraPermissions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }

    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setUpCamera()
                    }
                }
            }
        case .authorized:
            setUpCamera()
        default:
            break
        }
    }

    private func setUpCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
            session.startRunning()
            self.session = session
        } catch {
            print("Camera setup error: \(error)")
        }
    }
}

class LandscapeHostingController<Content>: UIHostingController<Content> where Content: View {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
}

extension UIDevice {
    static func forceOrientation(_ orientation: UIInterfaceOrientation) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        if let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
        
    }
}


struct CameraView: UIViewRepresentable {
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        previewLayer.connection?.videoRotationAngle = 0
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        Task {
            if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}
