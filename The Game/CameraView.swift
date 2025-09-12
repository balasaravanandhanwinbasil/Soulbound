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

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var currentPixelBuffer: CVPixelBuffer?
    
    let session = AVCaptureSession()
    
    override init() {
        super.init()
        setupSession()
    }
    
    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Cannot access camera")
            return
        }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        if session.canAddOutput(output) { session.addOutput(output) }
        
        session.commitConfiguration()
        
        Task{
            session.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        DispatchQueue.main.async {
            self.currentPixelBuffer = pixelBuffer
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    
    // 1.
    let session: AVCaptureSession
    
    // 2.
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        previewLayer.connection?.videoRotationAngle = 0
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    // 3.
    func updateUIView(_ uiView: UIView, context: Context) {
        Task {
            if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}
