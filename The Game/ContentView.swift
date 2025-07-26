import SwiftUI
import AVFoundation
import Vision

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

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}


struct ContentView: View {
    var body: some View {
        CameraView()
            .edgesIgnoringSafeArea(.all)
    }
}
