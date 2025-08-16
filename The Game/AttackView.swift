import SpriteKit
import SwiftUI

enum AttackType: CaseIterable {
    case soulBall, soulLaser, soulObstacle, manObstacle
}

struct AttackView: View {
    @Binding var playerPosition: CGPoint
    @Binding var playerHealth: Int
    
    @State private var projectiles: [Enemy] = []
    @State private var lasers: [Enemy] = []
    @State private var obstacles: [Enemy] = []
    @State private var gravityObstacles: [Enemy] = []
    
    // TIMERS
    @State private var hitCooldown: TimeInterval = 0
    let hitCooldownDuration: TimeInterval = 0.8

    @State private var spawnAccumulator: TimeInterval = 0
    @State private var attackSwitchAccumulator: TimeInterval = 0
    
    @State private var bossDamageAccumulator: TimeInterval = 0
    @State private var currentAttack: AttackType = .soulLaser
    
    @State private var gameTimer: Timer?
    @State private var isJumping: Bool = false
    @State private var jumpVelocity: CGFloat = 0
    let gravity: CGFloat = 1.5
    var groundY: CGFloat = 100
    
    @State private var safeZoneOpacity: Double = 0.2
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .position(playerPosition)
                .gesture(dragGesture)
                .gesture(tapGesture)
                .gesture(longPressGesture)
            
            ForEach(projectiles) { enemy in
                Circle()
                    .fill(Color.red)
                    .frame(width: enemy.size, height: enemy.size)
                    .position(enemy.position)
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
            
            spawnAccumulator += dt
            attackSwitchAccumulator += dt
            bossDamageAccumulator += dt
            
            if hitCooldown > 0 {
                hitCooldown -= dt
            }
            
            if attackSwitchAccumulator >= 10 {
                attackSwitchAccumulator = 0
                switchAttack()
            }
            
            if bossDamageAccumulator >= 1 {
                bossDamageAccumulator = 0
            }
            
            updateAttacks(dt: dt)
            movePlayerPhysics()
            checkCollisions()
        }
    }
    
    @State private var lastUpdateTime: TimeInterval = 0
    
    func switchAttack() {
        let cases = AttackType.allCases
        if let idx = cases.firstIndex(of: currentAttack) {
            currentAttack = cases[(idx + 1) % cases.count]
            projectiles.removeAll()
            lasers.removeAll()
            obstacles.removeAll()
            gravityObstacles.removeAll()
            spawnAccumulator = 0
        }
    }
    
    func updateAttacks(dt: TimeInterval) {
        switch currentAttack {
        case .soulBall:
            if spawnAccumulator >= 0.5 {
                spawnAccumulator = 0

                for _ in 0..<5 {
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
                projectiles[i].moveTowardTarget(speed: 7)
            }
            
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
            if spawnAccumulator >= 1.2 {
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


        case .manObstacle:
            if spawnAccumulator >= 1.2 {
                spawnAccumulator = 0
                gravityObstacles.append(Enemy(position: CGPoint(x: CGFloat.random(in: 40...(UIScreen.main.bounds.width - 40)), y: -40), size: 40))
            }
            for i in gravityObstacles.indices { gravityObstacles[i].position.y += 5 }
            gravityObstacles.removeAll { $0.position.y > UIScreen.main.bounds.height }
        }
    }

    
    func movePlayerPhysics() {
        if isJumping {
            playerPosition.y += jumpVelocity
            jumpVelocity += gravity
            if playerPosition.y >= groundY {
                playerPosition.y = groundY
                isJumping = false
            }
        }
    }
    
    func checkCollisions() {
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
                        if hitCooldown <= 0 && playerHealth != 1{
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
                    if hitCooldown <= 0 && playerHealth != 1{
                        playerHealth -= 2
                        hitCooldown = hitCooldownDuration
                    } else if hitCooldown <= 0{
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
