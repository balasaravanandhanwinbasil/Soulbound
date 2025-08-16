import SwiftUI
import Combine

// MARK: - Projectile Manager

struct Projectile: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let speed: CGFloat = 3

    mutating func updatePosition() {
        let dx = targetX - x
        let dy = targetY - y
        let distance = max(sqrt(dx*dx + dy*dy), 0.1)
        let directionX = dx / distance
        let directionY = dy / distance
        x += directionX * speed
        y += directionY * speed
    }

    func isOffScreen(width: CGFloat, height: CGFloat) -> Bool {
        return x < -50 || x > width + 50 || y < -50 || y > height + 50
    }

    func collidesWith(playerX: CGFloat, playerY: CGFloat, size: CGFloat = 30) -> Bool {
        let dx = playerX - x
        let dy = playerY - y
        return sqrt(dx*dx + dy*dy) < (size / 2 + 10)
    }
}

// MARK: - Projectile Manager

class ProjectileManager: ObservableObject {
    @Published var projectiles: [Projectile] = []
    
    var playerX: CGFloat = 100
    var playerY: CGFloat = 100
    
    var healthCallback: ((Int) -> Void)?

    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height

    private var spawnTimer: AnyCancellable?
    private var moveTimer: AnyCancellable?
    
    func start() {
        stop()
        spawnTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            let startX = CGFloat.random(in: 0...self.screenWidth)
            let new = Projectile(x: startX, y: 0, targetX: self.playerX, targetY: self.playerY)
            self.projectiles.append(new)
        }

        moveTimer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            for i in self.projectiles.indices {
                self.projectiles[i].updatePosition()
            }
            self.projectiles.removeAll {
                if $0.collidesWith(playerX: self.playerX, playerY: self.playerY) {
                    self.healthCallback?(1)
                    return true
                }
                return $0.isOffScreen(width: self.screenWidth, height: self.screenHeight)
            }
        }
    }

    func stop() {
        spawnTimer?.cancel()
        moveTimer?.cancel()
    }

    func reset() {
        projectiles.removeAll()
        stop()
    }
}

// MARK: - Attack View

struct AttackView: View {
    @ObservedObject var manager: ProjectileManager
    @Binding var health: Int
    @Binding var bossHealth: Int
    @Binding var resetTrigger: Bool
    
    @Binding var xaxis: CGFloat
    @Binding var yaxis: CGFloat

    @State private var attackType: String = "Man_ObstacleAttackView"
    private let attackTypes = ["Soul_BallAttack", "Soul_LaserAttack", "Soul_ObstacleAttack", "Man_ObstacleAttackView"]

    @State private var x: CGFloat = 100
    @State private var y: CGFloat = 600

    @State private var timerCancellable: AnyCancellable?
    @State private var bossTimer: AnyCancellable?

    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    let moveSpeed: CGFloat = 30

    var body: some View {
        VStack {
            ZStack {
                if attackType == "Soul_BallAttack" {
                    SoulBallAttackView(manager: manager, health: $health, resetTrigger: $resetTrigger, x: $xaxis, y: $yaxis)
                }
                if attackType == "Soul_LaserAttack" {
                    LaserAttackView(manager: manager, health: $health, resetTrigger: $resetTrigger, x: $xaxis, y: $yaxis)
                }
                if attackType == "Soul_ObstacleAttack" {
                    SoulObstacleAttackView(playerX: $x, playerY: $y, health: $health, resetTrigger: $resetTrigger)
                }
                if attackType == "Man_ObstacleAttackView" {
                    SoulGravityObstacleAttackView(playerX: $x, playerY: $y, health: $health, resetTrigger: $resetTrigger)
                }
                playerControls
            }
        }
        .onAppear {
            startTimer()
            startBossDamage()
        }
        .onDisappear {
            timerCancellable?.cancel()
            bossTimer?.cancel()
        }
    }

    var playerControls: some View {
        VStack {
            Spacer()
            VStack(spacing: 15) {
                    Button("Up") { move(dx: 0, dy: -moveSpeed) }
                    HStack(spacing: 40) {
                        Button("Left") { move(dx: -moveSpeed, dy: 0) }
                        Button("Right") { move(dx: moveSpeed, dy: 0) }
                    }
                    Button("Down") { move(dx: 0, dy: moveSpeed) }
                Text("Health: \(health)").foregroundColor(.white).padding(.top, 10)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 30)
        }
    }

    func move(dx: CGFloat, dy: CGFloat) {
        x = min(max(x + dx, 0), screenWidth)
        y = min(max(y + dy, 0), screenHeight)
        manager.playerX = x
        manager.playerY = y
    }

    func startTimer() {
        timerCancellable = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                switchAttack()
            }
    }

    func startBossDamage() {
        bossTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if bossHealth > 0 {
                    bossHealth -= 5
                }
            }
    }

    func switchAttack() {
        withAnimation {
            if attackType == "Soul_BallAttack" {
                attackType = "Soul_LaserAttack"
            } else if attackType == "Soul_LaserAttack" {
                attackType = "Soul_ObstacleAttack"
            } else if attackType == "Soul_ObstacleAttack" {
                attackType = "Man_ObstacleAttackView"
            } else {
                attackType = "Soul_BallAttack"
            }
            resetTrigger = true
        }
    }
}


// MARK: - SoulBall Attack

struct SoulBallAttackView: View {
    @ObservedObject var manager: ProjectileManager
    @Binding var health: Int
    @Binding var resetTrigger: Bool
    @Binding var x: CGFloat
    @Binding var y: CGFloat

    var body: some View {
        ZStack {
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.yellow)
                .position(x: x, y: y)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            x = value.location.x
                            y = value.location.y
                            updatePlayerPosition()
                        }
                )
                .onAppear {
                    manager.healthCallback = { damage in
                        if health > 0 { health -= damage }
                    }
                    manager.start()
                }
                .onChange(of: resetTrigger) { newValue in
                    if newValue { resetPlayer() }
                }

            ForEach(manager.projectiles) { projectile in
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .position(x: projectile.x, y: projectile.y)
            }
        }
    }

    func updatePlayerPosition() {
        manager.playerX = x
        manager.playerY = y
    }

    func resetPlayer() {
        x = 100
        y = 100
        updatePlayerPosition()
        manager.reset()
        manager.start()
        resetTrigger = false
    }
}

// MARK: - Laser Attack

struct LaserAttackView: View {
    @ObservedObject var manager: ProjectileManager
    @Binding var health: Int
    @Binding var resetTrigger: Bool
    @Binding var x: CGFloat
    @Binding var y: CGFloat

    @State private var laserXs: [CGFloat] = []
    @State private var timer: Timer?

    let laserWidth: CGFloat = 30
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width

    var body: some View {
        ZStack {
            // Lasers
            ForEach(laserXs, id: \.self) { laserX in
                Rectangle()
                    .fill(Color.red.opacity(0.4))
                    .frame(width: laserWidth, height: screenHeight)
                    .position(x: laserX, y: screenHeight / 2)
                    .onChange(of: x) { _ in checkCollisions() }
                    .onChange(of: y) { _ in checkCollisions() }
            }

            // Player
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.yellow)
                .position(x: x, y: y)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            x = value.location.x
                            y = value.location.y
                            checkCollisions()
                        }
                )
                .onAppear {
                    manager.healthCallback = { _ in }
                    manager.stop()
                    startSpammingLasers()
                }
                .onChange(of: resetTrigger) { newValue in
                    if newValue { resetPlayer() }
                }
        }
    }

    func checkCollisions() {
        for laserX in laserXs {
            if abs(x - laserX) < laserWidth / 2 + 15 {
                if health > 0 {
                    health -= 1
                }
            }
        }

        manager.playerX = x
        manager.playerY = y
    }

    func resetPlayer() {
        x = 100
        y = 100
        laserXs.removeAll()
        timer?.invalidate()
        timer = nil
        startSpammingLasers()
        resetTrigger = false
    }

    func startSpammingLasers() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            let randomX = CGFloat.random(in: 40...(screenWidth - 40))
            laserXs.append(randomX)

            // Optional: remove old lasers after a while
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                laserXs.removeAll { $0 == randomX }
            }

            checkCollisions()
        }
    }
}

// MARK: Soul Objects Jumping

struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat = 40
}

struct SoulObstacleAttackView: View {
    @State private var lastHitTime: Date = Date.distantPast
    let hitCooldown: TimeInterval = 0.5
    
    @Binding var playerX: CGFloat
    @Binding var playerY: CGFloat
    @Binding var health: Int
    @Binding var resetTrigger: Bool

    @State private var obstacles: [Obstacle] = []
    @State private var fallTimer: AnyCancellable?
    @State private var spawnTimer: AnyCancellable?

    let fallSpeed: CGFloat = 5
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            // Obstacles falling
            ForEach(obstacles) { obstacle in
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: obstacle.size, height: obstacle.size)
                    .position(x: obstacle.x, y: obstacle.y)
            }

            // Player
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.yellow)
                .position(x: playerX, y: playerY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            playerX = min(max(value.location.x, 0), screenWidth)
                            playerY = min(max(value.location.y, 0), screenHeight)
                        }
                )
        }
        .onAppear {
            startSpawning()
            startFalling()
        }
        .onDisappear {
            fallTimer?.cancel()
            spawnTimer?.cancel()
        }
        .onChange(of: resetTrigger) { newValue in
            if newValue { resetPlayer() }
        }
    }

    func startSpawning() {
        spawnTimer = Timer.publish(every: 1.2, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let randomX = CGFloat.random(in: 40...(screenWidth - 40))
                obstacles.append(Obstacle(x: randomX, y: -40))
            }
    }

    func startFalling() {
        fallTimer = Timer.publish(every: 0.016, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                for i in obstacles.indices {
                    obstacles[i].y += fallSpeed
                }
                obstacles.removeAll { $0.y > screenHeight }

                for obstacle in obstacles {
                    guard obstacle.y > 0 else { continue }

                    let dx = abs(obstacle.x - playerX)
                    let dy = abs(obstacle.y - playerY)

                    let now = Date()

                    if dx < 30 && dy < 30 && health > 0 && now.timeIntervalSince(lastHitTime) > hitCooldown {
                        health -= 1
                        lastHitTime = now
                        break
                    }
                }
            }
    }

    func resetPlayer() {
        playerX = screenWidth / 2
        playerY = screenHeight / 2
        resetTrigger = false
        health = 5
        obstacles.removeAll()
    }
}


// MARK: I WANAND SI
struct SoulGravityObstacleAttackView: View {
    @Binding var playerX: CGFloat
    @Binding var playerY: CGFloat
    @Binding var health: Int
    @Binding var resetTrigger: Bool

    @State private var obstacles: [Obstacle] = []
    @State private var fallTimer: AnyCancellable?
    @State private var spawnTimer: AnyCancellable?

    @State private var isJumping = false
    @State private var jumpVelocity: CGFloat = 0
    let gravity: CGFloat = 1.5
    let groundY: CGFloat = UIScreen.main.bounds.height - 150  // Adjust ground level as needed

    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height

    // For hit cooldown
    @State private var lastHitTime: Date = Date.distantPast
    let hitCooldown: TimeInterval = 0.5

    var body: some View {
        ZStack {
            // Falling obstacles
            ForEach(obstacles) { obstacle in
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: obstacle.size, height: obstacle.size)
                    .position(x: obstacle.x, y: obstacle.y)
            }

            // Player
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.yellow)
                .position(x: playerX, y: playerY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            playerX = min(max(value.location.x, 0), screenWidth)
                        }
                )

            // Jump Button
            VStack {
                Spacer()
                Button("Jump") {
                    jump()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            playerY = groundY
            startSpawning()
            startFalling()
        }
        .onDisappear {
            fallTimer?.cancel()
            spawnTimer?.cancel()
        }
        .onChange(of: resetTrigger) { newValue in
            if newValue { resetPlayer() }
        }
    }

    func startSpawning() {
        spawnTimer = Timer.publish(every: 1.2, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let randomX = CGFloat.random(in: 40...(screenWidth - 40))
                obstacles.append(Obstacle(x: randomX, y: -40))
            }
    }

    func startFalling() {
        fallTimer = Timer.publish(every: 0.016, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                for i in obstacles.indices {
                    obstacles[i].y += 5  // constant fall speed simulating gravity
                }
                obstacles.removeAll { $0.y > screenHeight }

                // Collision check with cooldown
                let now = Date()
                for obstacle in obstacles {
                    guard obstacle.y > 0 else { continue }
                    let dx = abs(obstacle.x - playerX)
                    let dy = abs(obstacle.y - playerY)
                    if dx < 30 && dy < 30 && health > 0 && now.timeIntervalSince(lastHitTime) > hitCooldown {
                        health -= 1
                        lastHitTime = now
                        break
                    }
                }

                // Jump physics
                if playerY < groundY {
                    playerY += jumpVelocity
                    jumpVelocity += gravity
                    if playerY > groundY {
                        playerY = groundY
                        isJumping = false
                    }
                }
            }
    }

    func jump() {
        if !isJumping {
            isJumping = true
            jumpVelocity = -20
        }
    }

    func resetPlayer() {
        playerX = screenWidth / 2
        playerY = groundY
        resetTrigger = false
        health = 5
        obstacles.removeAll()
    }
}


#Preview {
    ContentView()
}
