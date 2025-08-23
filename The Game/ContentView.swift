import SwiftUI


struct ContentView: View {
    @State var playerHealth: Int = 5
    @State var bossHealth: Int = 100
    @State var breakDefense: Int = 0
    
    @State var playerPosition: CGPoint = CGPoint(x: 100, y: 100)
    
    var body: some View {
        if (playerHealth != 0 && bossHealth != 0) {
            VStack {
                VStack(spacing:20){
                    OverlayView(
                        playerHealth: $playerHealth,
                        ultimate: 3,
                        bossHealth: $bossHealth,
                        bossDefense: $breakDefense
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
                        playerPosition: $playerPosition,
                        playerHealth: $playerHealth,
                        bossHealth: $bossHealth,
                        breakDefense: $breakDefense
                    )
                }
            }.onAppear {
                UIDevice.forceOrientation(.landscapeRight)
            }
            .background(.black)
        } else if (playerHealth == 0) {
            Text("GAME OVER !!!")
            Text("I understand. You got enough on your plate already.")
            Button() {
                playerHealth = 5
                bossHealth = 100
            } label: {
                Text("reset")
            }
        } else if (bossHealth == 0){
            Text("Wow you won")
            Text("Congratulations on not being caseoh")
            Button() {
                playerHealth = 5
                bossHealth = 100
            } label: {
                Text("reset")
            }
        }
    }
}

#Preview {
    ContentView()
}
