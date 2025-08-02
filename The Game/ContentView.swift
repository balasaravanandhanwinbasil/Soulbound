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


struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}


struct ContentView: View {
    var body: some View {
        ZStack {
            CameraView()
                .edgesIgnoringSafeArea(.all)
                .onAppear()
                .padding()
            VStack(spacing:20){
                OverlayView(
                    playerHealth: 2,
                    ultimate: 3,
                    bossHealth: 60,
                    bossDefense: 50
                )
                
                Rectangle()
                    .fill(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: 2)
                    .padding(.horizontal, 16)
                
                
                AttackView()
            }
        }.onAppear {
            UIDevice.forceOrientation(.landscapeRight)
        }
        .background(.black)
    }
}

#Preview {
    ContentView()
}
