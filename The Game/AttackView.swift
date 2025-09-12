import SwiftUI
import SpriteKit
import Vision
import AVFoundation

struct AttackView: View {
    // MARK: - Observed Objects & Bindings
    @ObservedObject var detector: HumanDetector
    @Binding var playerPosition: CGPoint
    @Binding var playerHealth: Int
    @Binding var bossHealth: Int
    @Binding var breakDefense: Int

    // MARK: - Game States
    @State private var projectiles: [UUID: CGPoint] = [:]
    @State private var lasers: [UUID: CGFloat] = [:]
    @State private var obstacles: [UUID: CGPoint] = [:]
    @State private var teleporters: [UUID: CGPoint] = [:]
    @State private var buttons: [UUID: CGPoint] = [:]
    @State private var gameTimer: Timer?
    @State private var isJumping = false
    @State private var verticalVelocity: CGFloat = 0
    @State private var isDucking = false
    @State private var currentMode: GameMode = .man
    @State private var soulLengthTimer: CGFloat = 0

    // MARK: - Constants
    let groundY: CGFloat = 670

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            if currentMode == .man {
                Color.cyan.ignoresSafeArea()
                Rectangle()
                    .fill(Color.green)
                    .frame(width: UIScreen.main.bounds.width, height: 40)
                    .position(x: UIScreen.main.bounds.midX, y: groundY + 20)
            } else {
                Color.black.ignoresSafeArea()
            }

            // Player
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: isDucking ? 20 : 40)
                .position(x: playerPosition.x,
                          y: isDucking ? playerPosition.y + 10 : playerPosition.y)

            // Projectiles
            ForEach(Array(projectiles.keys), id: \.self) { id in
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .position(projectiles[id] ?? .zero)
            }

            // Lasers
            ForEach(Array(lasers.keys), id: \.self) { id in
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 20, height: UIScreen.main.bounds.height)
                    .position(x: lasers[id] ?? 0, y: UIScreen.main.bounds.midY)
            }

            // Obstacles
            ForEach(Array(obstacles.keys), id: \.self) { id in
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 50, height: 50)
                    .position(obstacles[id] ?? .zero)
            }

            // Teleporters
            ForEach(Array(teleporters.keys), id: \.self) { id in
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: 50, height: 50)
                    .position(teleporters[id] ?? .zero)
            }

            // Buttons
            ForEach(Array(buttons.keys), id: \.self) { id in
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 50, height: 20)
                    .position(buttons[id] ?? .zero)
            }

            // Boss Health Bar
            VStack {
                Spacer()
                Text("Boss HP: \(bossHealth)")
                    .font(.headline)
                    .padding()
            }

            // Kill Switch Button
            if currentMode == .man {
                VStack {
                    Spacer()
                    Button("KILL THEM. KILL THEM ALL.") {
                        breakDefense += 1
                        if breakDefense >= 15 {
                            currentMode = .soul
                            soulLengthTimer = 0
                            breakDefense = 0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                currentMode = .man
                                resetAttacks()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear { startGameLoop() }
        .onDisappear { gameTimer?.invalidate() }

        .onChange(of: detector.xAxisBody) { _, _ in
            updatePlayerPositionFromVision()
        }
        .onChange(of: detector.yAxisBody) { _, _ in
            updatePlayerPositionFromVision()
        }
    }

    // MARK: - Vision Update
    private func updatePlayerPositionFromVision() {
        guard let xNorm = detector.xAxisBody, let yNorm = detector.yAxisBody else { return }
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        let mappedX = xNorm * screenWidth
        let mappedY = (1 - yNorm) * screenHeight

        let smoothing: CGFloat = 0.15
        let newX = playerPosition.x + (mappedX - playerPosition.x) * smoothing
        let newY = playerPosition.y + (mappedY - playerPosition.y) * smoothing

        playerPosition = CGPoint(x: newX, y: newY)
    }

    // MARK: - Game Loop
    private func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateGame()
        }
    }

    private func updateGame() {

        if isJumping {
            playerPosition.y += verticalVelocity
            if playerPosition.y >= groundY {
                playerPosition.y = groundY
                isJumping = false
                verticalVelocity = 0
            }
        }

        soulLengthTimer += 0.016

        updateProjectiles()
        updateLasers()
        updateObstacles()
        updateTeleporters()
        updateButtons()
    }

    private func resetAttacks() {
        projectiles.removeAll()
        lasers.removeAll()
        obstacles.removeAll()
        teleporters.removeAll()
        buttons.removeAll()
    }

    private func updateProjectiles() {
        for id in projectiles.keys {
            projectiles[id]?.x -= 5
        }
    }

    private func updateLasers() { }
    private func updateObstacles() { }
    private func updateTeleporters() { }
    private func updateButtons() { }
}

enum GameMode {
    case man, soul
}
