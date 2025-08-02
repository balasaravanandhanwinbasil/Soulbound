//
//  AttackView.swift
//  The Game
//
//  Created by Balasaravanan Dhanwin Basil  on 2/8/25.
//
import SwiftUI

struct Projectile: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let speed: CGFloat = 5

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

    func collidesWith(playerX: CGFloat, playerY: CGFloat, size: CGFloat = 60) -> Bool {
        let dx = playerX - x
        let dy = playerY - y
        return sqrt(dx*dx + dy*dy) < (size / 2 + 10)
    }
}

struct AttackView: View {
    @State private var x: CGFloat = 100
    @State private var y: CGFloat = 100
    @State private var dragStartX: CGFloat = 0
    @State private var dragStartY: CGFloat = 0
    
    @State private var projectiles: [Projectile] = []
    
    @Binding var health: Int

    let moveSpeed: CGFloat = 20
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(health > 0 ? .yellow : .gray)
                .position(x: x, y: y)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            x = dragStartX + value.translation.width
                            y = dragStartY + value.translation.height
                        }
                        .onEnded { _ in
                            dragStartX = x
                            dragStartY = y
                        }
                )
                .onAppear {
                    dragStartX = x
                    dragStartY = y
                    startProjectileTimers()
                }

            // Projectiles
            ForEach(projectiles) { projectile in
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .position(x: projectile.x, y: projectile.y)
            }

            // Controls
            VStack {
                Spacer()
                VStack(spacing: 15) {
                    Button("Up") { y = max(y - moveSpeed, 0) }
                    HStack(spacing: 40) {
                        Button("Left") { x = max(x - moveSpeed, 0) }
                        Button("Right") { x = min(x + moveSpeed, screenWidth) }
                    }
                    Button("Down") { y = min(y + moveSpeed, screenHeight) }
                    Text("Health: \(health)")
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 30)
            }
        }
    }

    func startProjectileTimers() {
        // Projectile spawner
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            DispatchQueue.main.async {
                let startX = CGFloat.random(in: 0...screenWidth)
                projectiles.append(Projectile(
                    x: startX, y: 0,
                    targetX: x,
                    targetY: y
                ))
            }
        }

        // Projectile updater
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            DispatchQueue.main.async {
                for i in projectiles.indices {
                    projectiles[i].updatePosition()
                }

                // Collision check and removal
                projectiles.removeAll {
                    if $0.collidesWith(playerX: x, playerY: y) {
                        if health > 0 {
                            health -= 1
                        }
                        return true
                    }
                    return $0.isOffScreen(width: screenWidth, height: screenHeight)
                }
            }
        }
    }

}


#Preview {
    ContentView()
}
