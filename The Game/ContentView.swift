import SwiftUI
import AVFoundation

struct ContentView: View {
    @State var playerHealth: Int = 5
    @State var bossHealth: Int = 100
    @State var breakDefense: Int = 0
    
    @State var playerPosition: CGPoint = CGPoint(x: 100, y: 100)
    
    @StateObject private var detector = HumanDetector()
    @StateObject private var camera = CameraManager()
    
    var body: some View {
        if (playerHealth <= 0) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.black, .red]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Image(systemName: "xmark.octagon.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.red)
                        .shadow(radius: 20)

                    Text("GAME OVER !!!")
                        .font(.system(size: 50, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(radius: 10)

                    Text("I understand. You got enough on your plate already.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal)

                    Button {
                        playerHealth = 5
                        bossHealth = 100
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    }
                }
                .padding()
            }
        }
        else if (bossHealth <= 0) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.black, .yellow]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Image(systemName: "crown.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.yellow)
                        .shadow(radius: 20)

                    Text("YOU WON")
                        .font(.system(size: 50, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(radius: 10)

                    Text("Congratulations on not being caseoh")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal)

                    Button {
                        playerHealth = 5
                        bossHealth = 100
                    } label: {
                        Label("Play Again?", systemImage: "arrow.clockwise.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    }
                }
                .padding()
            }
        }
        else {
            VStack {
                VStack(spacing:20){
                    OverlayView(
                        playerHealth: $playerHealth,
                        bossHealth: $bossHealth,
                        bossDefense: $breakDefense
                    )
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(maxWidth: .infinity, maxHeight: 2)
                        .padding(.horizontal, 16)
                    
                }
                
                ZStack {
                    CameraPreviewView(session: camera.session)
                        .ignoresSafeArea()
                        .task {
                            while true {
                                if let buffer = camera.currentPixelBuffer {
                                    await detector.detect(in: buffer)
                                }
                                try? await Task.sleep(nanoseconds: 33_000_000)
                            }
                        }
                    
                    AttackView(
                        detector: detector,
                        playerPosition: $playerPosition,
                        playerHealth: $playerHealth,
                        bossHealth: $bossHealth,
                        breakDefense: $breakDefense
                    )
                }
            }
            .background(.black)
        }
    }
}

#Preview {
    ContentView()
}
