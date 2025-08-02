import SwiftUI
import AVFoundation
import Vision
import SpriteKit


struct ContentView: View {
    @State var playerHealth: Int = 5
    @State var projectiles: [Projectile] = []
    
    var body: some View {
        if playerHealth != 0 {
            VStack {
                VStack(spacing:20){
                    OverlayView(
                        playerHealth: $playerHealth,
                        ultimate: 3,
                        bossHealth: 60,
                        bossDefense: 50
                    )
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(maxWidth: .infinity, maxHeight: 2)
                        .padding(.horizontal, 16)
                    
                }
                
                ZStack {
                    CameraView()
                        .edgesIgnoringSafeArea(.all)
                        .onAppear()
                        .padding()
                    AttackView(
                        projectiles: $projectiles,
                        health: $playerHealth
                    )
                }
            }.onAppear {
                UIDevice.forceOrientation(.landscapeRight)
            }
            .background(.black)
        } else {
            Text("GAME OVER !!!")
            Text("I understand. You got enough on your plate already.")
            Button() {
                playerHealth = 5
            } label: {
                Text("reset")
            }
        }
    }
}

#Preview {
    ContentView()
}
