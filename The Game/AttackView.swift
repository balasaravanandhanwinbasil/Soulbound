import SpriteKit
import SwiftUI

enum AttackType: CaseIterable {
    case soulBall, soulLaser, soulObstacle, soulFall
}

enum EnvironmentType: CaseIterable {
    case soul, man
}

struct AttackView: View {
    @Binding var playerPosition: CGPoint
    @Binding var playerHealth: Int
    @Binding var bossHealth: Int
    @Binding var breakDefense: Int
    
    @State var currentMode: EnvironmentType = .man
    @State var soulLengthTimer: TimeInterval = 0
    
    @State var manAttack: TimeInterval = 0
    @State private var currentManAttack: String? = nil
    let manAttacks = [
        "jump",
        "duck",
        "obby with ducking and jumping",
        "obby with 3 consecutive jumps",
        "big block where you have to move",
        "big block where you have to stay still",
        "tight jumps",
        "falling blocks",
        "moving ceiling",
        "zigzag walls"
    ]
    
    @State private var projectiles: [Enemy] = []
    @State private var lasers: [Enemy] = []
    @State private var obstacles: [Enemy] = []
    
    @State private var gravityObstacles: [Enemy] = []
    @State var gravityChaser: Enemy = Enemy(position: CGPoint(x: UIScreen.main.bounds.midX,
                                                              y: UIScreen.main.bounds.height - 100), size: .zero)
    @State var chaser: Bool = false
    
    @State private var hitCooldown: TimeInterval = 0
    let hitCooldownDuration: TimeInterval = 0.8
    
    @State private var spawnAccumulator: TimeInterval = 0
    @State private var attackSwitchAccumulator: TimeInterval = 0
    
    @State private var bossDamageAccumulator: TimeInterval = 0
    @State private var currentAttack: AttackType = .soulBall
    
    @State private var gameTimer: Timer?
    @State private var isJumping: Bool = false
    @State private var jumpVelocity: CGFloat = 0
    @State private var isDucking: Bool = false
    let gravity: CGFloat = 1.5
    var groundY: CGFloat = 670
    
    var swipeDownGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.height > 20 {
                    isDucking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isDucking = false
                    }
                }
            }
    }
    
    @State private var spawnThreshold: TimeInterval = 1.0
    @State private var safeZoneOpacity: Double = 0.2
    
    var body: some View {
        ZStack {
            if currentMode == .man {
                Color.cyan.edgesIgnoringSafeArea(.all)
                Rectangle()
                        .fill(Color.green)
                        .frame(width: UIScreen.main.bounds.width, height: 40)
                        .position(x: UIScreen.main.bounds.midX, y: groundY + 20)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }
            
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: isDucking ? 20 : 40)
                .position(x: playerPosition.x, y: isDucking ? playerPosition.y + 10 : playerPosition.y)
                .gesture(dragGesture)
                .gesture(tapGesture)
                .gesture(longPressGesture)

            
            ForEach(projectiles) { ball in
                Circle()
                    .fill(Color.red)
                    .frame(width: ball.size, height: ball.size)
                    .position(ball.position)
            }
            
            ForEach(lasers) { laser in
                if laser.life! > 0 {
                    SafeZoneCircle(size: laser.size, position: laser.position)
                } else {
                    ZStack {
                        Color.red.edgesIgnoringSafeArea(.all)
                        Circle()
                            .fill(Color.green)
                            .frame(width: laser.size, height: laser.size)
                            .position(laser.position)
                    }
                }
            }
            
            ForEach(obstacles) { enemy in
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 20, height: enemy.size)
                    .position(enemy.position)
            }
            
            ForEach(gravityObstacles) { enemy in
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: enemy.size, height: enemy.size)
                    .position(enemy.position)
            }
            
            if(chaser) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 35, height: 35)
                    .position(gravityChaser.position)
            }
            
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
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                playerPosition.x = min(max(value.location.x, 0), UIScreen.main.bounds.width)
                playerPosition.y = min(max(value.location.y, 0), UIScreen.main.bounds.height)
            }
    }
    
    var tapGesture: some Gesture {
        TapGesture()
            .onEnded {
                if !isJumping {
                    isJumping = true
                    jumpVelocity = -20
                }
            }
    }
    
    var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                playerPosition.y += 50
            }
    }
    
    func startGameLoop() {
        gameTimer?.invalidate()
        lastUpdateTime = Date().timeIntervalSince1970
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            let now = Date().timeIntervalSince1970
            let dt = now - lastUpdateTime
            lastUpdateTime = now
            
            if currentMode == .soul {
                soulLengthTimer += dt
                bossDamageAccumulator += dt
                
                if soulLengthTimer >= 40 {
                    currentMode = .man
                    soulLengthTimer = 0
                    resetAttacks()
                }
            } 
            
            spawnAccumulator += dt
            attackSwitchAccumulator += dt
            
            if hitCooldown > 0 {
                hitCooldown -= dt
            }
            
            if attackSwitchAccumulator >= 10 {
                attackSwitchAccumulator = 0
                switchAttack()
            }
            
            if bossDamageAccumulator >= 5 {
                bossDamageAccumulator = 0
                bossHealth -= 10
            }
            
            updateAttacks(dt: dt)
            movePlayerPhysics()
            checkCollisions()
        }
    }
    
    @State private var lastUpdateTime: TimeInterval = 0
    
    func switchAttack() {
        if currentMode == .soul {
            currentAttack = AttackType.allCases.randomElement()!
            resetAttacks()
        } else {
            currentManAttack = manAttacks.randomElement()
            resetAttacks()
        }
    }
    
    func updateAttacks(dt: TimeInterval) {
        if currentMode == .soul {
            switch currentAttack {
            case .soulBall:
                chaser = true
                gravityChaser.target = playerPosition
                
                if spawnAccumulator >= 0.5 {
                    spawnAccumulator = 0
                    
                    for _ in 0..<3 {
                        let projSize = CGFloat.random(in: 30...45)
                        let targetOffsetX = CGFloat.random(in: -40...40)
                        let targetOffsetY = CGFloat.random(in: -40...40)
                        let target = CGPoint(
                            x: min(max(playerPosition.x + targetOffsetX, 0), UIScreen.main.bounds.width),
                            y: min(max(playerPosition.y + targetOffsetY, 0), UIScreen.main.bounds.height)
                        )
                        projectiles.append(
                            Enemy(
                                position: CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: 0),
                                size: projSize,
                                target: target
                            )
                        )
                    }
                }
                
                for i in projectiles.indices {
                    projectiles[i].moveTowardTarget(speed: 5)
                }
                gravityChaser.moveTowardTarget(speed: 3)
                
            case .soulLaser:
                if spawnAccumulator >= 1.8 {
                    spawnAccumulator = 0
                    
                    lasers.removeAll()
                    let safeWidth: CGFloat = 100
                    let safeHeight: CGFloat = 100
                    
                    let safeX = CGFloat.random(in: safeWidth...(UIScreen.main.bounds.width - safeWidth))
                    let safeY = CGFloat.random(in: safeHeight...(UIScreen.main.bounds.height - safeHeight))
                    
                    lasers.append(
                        Enemy(
                            position: CGPoint(x: safeX, y: safeY),
                            size: max(safeWidth, safeHeight),
                            life: 1.3
                        )
                    )
                }
                
                for i in lasers.indices {
                    lasers[i].life! -= dt
                }
                
                lasers.removeAll { $0.life! <= -0.5 }
                
            case .soulObstacle:
                if spawnAccumulator >= 0.9 {
                    spawnAccumulator = 0
                    
                    let gapHeight: CGFloat = 120
                    let spikeWidth: CGFloat = 20
                    
                    let gapCenterY = CGFloat.random(in: 100...(UIScreen.main.bounds.height - 100))
                    
                    let topSpikeHeight = gapCenterY - gapHeight/2
                    
                    obstacles.append(
                        Enemy(
                            position: CGPoint(x: UIScreen.main.bounds.width + spikeWidth/2, y: topSpikeHeight / 2),
                            size: topSpikeHeight,
                            target: nil
                        )
                    )
                    
                    let bottomSpikeHeight = UIScreen.main.bounds.height - (gapCenterY + gapHeight/2)
                    
                    obstacles.append(
                        Enemy(
                            position: CGPoint(x: UIScreen.main.bounds.width + spikeWidth/2, y: gapCenterY + gapHeight/2 + bottomSpikeHeight/2),
                            size: bottomSpikeHeight,
                            target: nil
                        )
                    )
                }
                
                for i in obstacles.indices {
                    obstacles[i].position.x -= 5
                }
                
                obstacles.removeAll { $0.position.x < -50 }
                
            case .soulFall:
                chaser = true
                gravityChaser.target = playerPosition
                
                if spawnAccumulator >= 1 {
                    spawnAccumulator = 0
                    for _ in 1..<25 {
                        gravityObstacles.append(
                            Enemy(position: CGPoint(
                                x: CGFloat.random(in: 40...(UIScreen.main.bounds.width - 40)),
                                y: -40
                            ),
                                  size: 40
                            )
                        )
                    }
                }
                for i in gravityObstacles.indices {
                    gravityObstacles[i].position.y += 5
                }
                gravityObstacles.removeAll { $0.position.y > UIScreen.main.bounds.height }
                gravityChaser.moveTowardTarget(speed: 3)
            }
        } else {
            if spawnAccumulator >= spawnThreshold {
                spawnAccumulator = 0
                let attack = manAttacks.randomElement()!
                
                switch attack {
                case "jump":
                    // Normal jump over a block
                    obstacles.append(
                        Enemy(
                            position: CGPoint(x: UIScreen.main.bounds.width + 40,
                                              y: groundY - 20),
                            size: 60
                        )
                    )
                    
                case "duck":
                    // Temporary low ceiling so player must duck
                    obstacles.append(
                        Enemy(
                            position: CGPoint(x: UIScreen.main.bounds.width + 40,
                                              y: groundY + 40), // from above
                            size: 60
                        )
                    )
                    
                case "obby with ducking and jumping":
                    // Combination: one to jump, one to duck
                    obstacles.append(
                        Enemy(
                            position: CGPoint(x: UIScreen.main.bounds.width + 60,
                                              y: groundY - 20),
                            size: 60
                        )
                    )
                    obstacles.append(
                        Enemy(
                            position: CGPoint(x: UIScreen.main.bounds.width + 140,
                                              y: groundY + 40),
                            size: 60
                        )
                    )
                    
                case "obby with 3 consecutive jumps":
                    // Three jump blocks in sequence
                    for i in 0..<3 {
                        obstacles.append(
                            Enemy(
                                position: CGPoint(x: UIScreen.main.bounds.width + CGFloat(80 * (i+1)),
                                                  y: groundY - 20),
                                size: 60
                            )
                        )
                    }
                    
                case "big block where you have you have to move":
                    // Big block covering center, player must jump OR duck to avoid depending on its height
                    obstacles.append(
                            Enemy(
                                position: CGPoint(x: UIScreen.main.bounds.width + 120,
                                                  y: UIScreen.main.bounds.height / 2),
                                size: UIScreen.main.bounds.height - 200 // leaves space top/bottom
                            )
                        )
                    
                case "big block where you have to stay still":
                    // Wide obstacle but leaves a gap in center (safe spot)
                    obstacles.append(
                        Enemy(
                            position: CGPoint(x: UIScreen.main.bounds.width + 60,
                                              y: groundY - 20),
                            size: 100
                        )
                    )
                    obstacles.append(
                        Enemy(
                            position: CGPoint(x: UIScreen.main.bounds.width + 180,
                                              y: groundY - 20),
                            size: 100
                        )
                    )
                    
                case "tight jumps":
                    // Narrowly spaced blocks that require precise jumps
                    for i in 0..<4 {
                        obstacles.append(
                            Enemy(
                                position: CGPoint(x: UIScreen.main.bounds.width + CGFloat(70 * (i+1)),
                                                  y: groundY - 20),
                                size: 50
                            )
                        )
                    }
                    
                case "falling blocks":
                    for _ in 0..<5 {
                        gravityObstacles.append(
                            Enemy(position: CGPoint(
                                x: CGFloat.random(in: 40...(UIScreen.main.bounds.width - 40)),
                                y: -40
                            ),
                                  size: 60
                            )
                        )
                    }

                case "moving ceiling":
                    obstacles.append(
                        Enemy(position: CGPoint(x: UIScreen.main.bounds.width + 60, y: groundY - 200),
                              size: 40)
                    )

                case "zigzag walls":
                    for i in 0..<5 {
                        let y = (i % 2 == 0) ? groundY - 20 : groundY - 160
                        obstacles.append(
                            Enemy(position: CGPoint(x: UIScreen.main.bounds.width + CGFloat(80 * (i+1)), y: y),
                                  size: 60)
                        )
                    }

                default:
                    break
                }
                
                spawnThreshold = Double.random(in: 0.6...1.8)
            }

            // Move obstacles
            for i in obstacles.indices {
                obstacles[i].position.x -= obstacles[i].size > 100 ? 5 : 7
            }

            // Remove off-screen obstacles
            obstacles.removeAll { $0.position.x < -100 }

        }
    }
    
    func resetAttacks() {
        projectiles.removeAll()
        lasers.removeAll()
        obstacles.removeAll()
        gravityObstacles.removeAll()
        chaser = false
    }
    
    func movePlayerPhysics() {
        if currentMode == .man {
            if isJumping {
                playerPosition.y += jumpVelocity
                jumpVelocity += gravity
                if playerPosition.y >= groundY {
                    playerPosition.y = groundY
                    isJumping = false
                }
            }
        } else {
            isJumping = false
            jumpVelocity = 0
        }
    }
    
    func checkCollisions() {
        let playerHalfWidth: CGFloat = 20
        let playerHalfHeight: CGFloat = isDucking ? 10 : 20
        let playerMinX = playerPosition.x - playerHalfWidth //Want to add the x and y axis of the player here?
        let playerMaxX = playerPosition.x + playerHalfWidth
        let playerMinY = playerPosition.y - playerHalfHeight
        let playerMaxY = playerPosition.y + playerHalfHeight

        for p in projectiles where p.position.distance(to: playerPosition) < 30 {
            if hitCooldown <= 0 {
                playerHealth -= 1
                hitCooldown = hitCooldownDuration
            }
            projectiles.removeAll { $0.id == p.id }
        }
        for l in lasers {
            if let life = l.life, life <= 0 {
                let distanceToSafe = playerPosition.distance(to: l.position)
                if distanceToSafe > l.size / 2 {
                    if hitCooldown <= 0 && playerHealth != 1 {
                        playerHealth -= 2
                        hitCooldown = hitCooldownDuration
                    } else if hitCooldown <= 0 {
                        playerHealth -= 1
                        hitCooldown = hitCooldownDuration
                    }
                }
            }
        }
        
        for o in obstacles {
            let halfWidth: CGFloat = 10
            let halfHeight: CGFloat = o.size / 2
            
            let rectMinX = o.position.x - halfWidth
            let rectMaxX = o.position.x + halfWidth
            let rectMinY = o.position.y - halfHeight
            let rectMaxY = o.position.y + halfHeight
            
            if playerPosition.x >= rectMinX && playerPosition.x <= rectMaxX &&
                playerPosition.y >= rectMinY && playerPosition.y <= rectMaxY {
                if hitCooldown <= 0 && playerHealth != 1 {
                    playerHealth -= 2
                    hitCooldown = hitCooldownDuration
                } else if hitCooldown <= 0 {
                    playerHealth -= 1
                    hitCooldown = hitCooldownDuration
                }
                obstacles.removeAll { $0.id == o.id }
            }
        }
        
        for g in gravityObstacles where g.position.distance(to: playerPosition) < 30 {
            if hitCooldown <= 0 {
                playerHealth -= 1
                hitCooldown = hitCooldownDuration
            }
            gravityObstacles.removeAll { $0.id == g.id }
        }
        
        if playerPosition.x >= gravityChaser.position.x && playerPosition.x <= gravityChaser.position.x {
            if hitCooldown <= 0 {
                playerHealth -= 2
                hitCooldown = hitCooldownDuration
            }
            gravityChaser = Enemy(position: CGPoint(x: UIScreen.main.bounds.midX,
                                                    y: UIScreen.main.bounds.height - 40), size: .zero)
        }
    }
}

struct Enemy: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var target: CGPoint? = nil
    var life: TimeInterval? = nil
    var reachedTarget: Bool = false
    var wanderOffset: CGPoint = .zero
    
    mutating func moveTowardTarget(speed: CGFloat = 5) {
        if !reachedTarget, let t = target {
            let dx = t.x - position.x
            let dy = t.y - position.y
            let dist = max(sqrt(dx*dx + dy*dy), 0.1)
            if dist < speed {
                position = t
                reachedTarget = true
                wanderOffset = CGPoint(x: CGFloat.random(in: -5...5), y: CGFloat.random(in: -5...5))
            } else {
                position.x += dx / dist * speed
                position.y += dy / dist * speed
            }
        } else {
            position.x += wanderOffset.x
            position.y += wanderOffset.y
            wanderOffset.x += CGFloat.random(in: -1...1)
            wanderOffset.y += CGFloat.random(in: -1...1)
            
            position.x = min(max(position.x, 0), UIScreen.main.bounds.width)
            position.y = min(max(position.y, 0), UIScreen.main.bounds.height)
        }
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

struct SafeZoneCircle: View {
    var size: CGFloat
    var position: CGPoint
    
    @State private var opacity: Double = 0.2
    
    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: size, height: size)
            .position(position)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.8
                }
            }
    }
}

#Preview {
    ContentView()
}
