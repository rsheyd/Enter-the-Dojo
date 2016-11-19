//
//  GameScene.swift
//  Enter the Dojo
//
//  Created by Roman Sheydvasser on 11/10/16.
//  Copyright © 2016 RLabs. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bow = SKSpriteNode()
    var arrow = SKSpriteNode()
    var bg = SKSpriteNode()
    
    var powerLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
    var power = 0
    var score = 0
    var gameOverLabel = SKLabelNode()
    
    var timer = Timer()
    var previousPoint : CGPoint!
    
    enum ColliderType: UInt32 {
        case Arrow = 1
        case Enemy = 2
        case Ground = 4
    }
    
    var gameOver = false
    var pulling = false
    var arrowCollision = false
    var inFlight = false
    
    func makeEnemies() {
        // enemy movement
        let moveEnemies = SKAction.move(by: CGVector(dx: 0, dy: -1.1 * self.frame.height), duration: TimeInterval(self.frame.height / 70))
        let removeEnemies = SKAction.removeFromParent()
        let moveAndRemoveEnemies = SKAction.sequence([moveEnemies, removeEnemies])
        
        // adding a bounce to enemy texture
        let enemyTexture = SKTexture(imageNamed: "idle_0.png")
        let enemyTexture2 = SKTexture(imageNamed: "idle_1.png")
        let enemyTexture3 = SKTexture(imageNamed: "idle_2.png")
        let enemyTexture4 = SKTexture(imageNamed: "idle_3.png")
        let animation = SKAction.animate(with: [enemyTexture, enemyTexture2, enemyTexture3, enemyTexture4], timePerFrame: 0.2)
        let enemyBounce = SKAction.repeatForever(animation)
        let enemy = SKSpriteNode(texture: enemyTexture)
        
        // set random position for enemy nodes
        let randomNum = arc4random_uniform(UInt32(self.frame.width-100))
        let randomX = CGFloat(randomNum) - self.frame.width/2 + 50
        enemy.position = CGPoint(x: randomX, y: self.frame.maxY + 100)

        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemyTexture.size())
        enemy.physicsBody!.isDynamic = false
        enemy.physicsBody!.categoryBitMask = ColliderType.Enemy.rawValue
        enemy.physicsBody!.contactTestBitMask = ColliderType.Arrow.rawValue
        
        enemy.run(enemyBounce)
        enemy.run(moveAndRemoveEnemies)
        self.addChild(enemy)
    }
    
    func setupGame() {
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.makeEnemies), userInfo: nil, repeats: true)
        
        let bgTexture = SKTexture(imageNamed: "grass.png")
        bg = SKSpriteNode(texture: bgTexture)
        bg.size.height = self.frame.height
        bg.size.width = self.frame.width
        bg.zPosition = -1
        self.addChild(bg)
        
        let arrowTexture = SKTexture (imageNamed: "blue-arrow.png")
        arrow = SKSpriteNode(texture: arrowTexture)
        arrow.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 100)
        arrow.physicsBody = SKPhysicsBody(rectangleOf: arrowTexture.size())
        arrow.physicsBody!.isDynamic = false
        arrow.physicsBody!.categoryBitMask = ColliderType.Arrow.rawValue
        arrow.physicsBody!.contactTestBitMask = ColliderType.Ground.rawValue
        self.addChild(arrow)
        
        let bowTexture = SKTexture (imageNamed: "blue-bow.png")
        bow = SKSpriteNode(texture: bowTexture)
        bow.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 100)
        self.addChild(bow)
        
        let ground = SKNode()
        ground.position = CGPoint(x: self.frame.midX, y: self.frame.minY)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: 1))
        ground.physicsBody!.isDynamic = false
        ground.physicsBody!.categoryBitMask = ColliderType.Ground.rawValue
        ground.physicsBody!.contactTestBitMask = ColliderType.Ground.rawValue
        self.addChild(ground)
        
        powerLabel.fontName = "Helvetica"
        powerLabel.fontSize = 50
        powerLabel.text = "0"
        powerLabel.position = CGPoint(x: self.frame.maxX - 70, y: self.frame.minY + 70)
        self.addChild(powerLabel)
        
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = UIColor.green
        scoreLabel.text = "0"
        scoreLabel.position = CGPoint(x: self.frame.minX + 70, y: self.frame.minY + 70)
        self.addChild(scoreLabel)
    }
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        setupGame()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        pulling = true
        for touch in touches {
            previousPoint = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let currentPoint = touch.location(in: self)
            let distance = currentPoint.x - previousPoint.x
            previousPoint = currentPoint
            arrow.zRotation = arrow.zRotation - distance/100.0
            bow.zRotation = bow.zRotation - distance/100.0
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        pulling = false
        arrow.physicsBody!.isDynamic = true
        arrow.physicsBody!.applyImpulse(CGVector(dx: arrow.zRotation * -120, dy: CGFloat(power*3)))
        power = 0
        powerLabel.text = "0"
        inFlight = true
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameOver == false {
            
            if contact.bodyA.categoryBitMask == ColliderType.Ground.rawValue || contact.bodyB.categoryBitMask == ColliderType.Ground.rawValue {
                arrowCollision = true
            }
            
            if contact.bodyA.categoryBitMask == ColliderType.Enemy.rawValue || contact.bodyB.categoryBitMask == ColliderType.Enemy.rawValue {
                if contact.bodyA.node?.name == "enemy" {
                    contact.bodyA.node?.removeFromParent()
                } else {
                    contact.bodyB.node?.removeFromParent()
                }
                arrowCollision = true
                score += 1
                scoreLabel.text = String(score)
            }
            
            
            
            else {
                /*
                self.speed = 0
                
                gameOver = true
                
                timer.invalidate()
                
                gameOverLabel.fontName = "Helvetica"
                
                gameOverLabel.fontSize = 30
                
                gameOverLabel.text = "Game Over! Tap to play again."
                
                gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
                
                self.addChild(gameOverLabel)
 */
                
            }
            
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // increase arrow power while user holding touch
        if power < 100 {
            if pulling {
                power += 1
                powerLabel.text = String(power)
            }
        }
        
        // reset arrow when out of bounds or collided with ground
        if arrow.position.x > self.frame.maxX || arrow.position.x < self.frame.minX || arrow.position.y > self.frame.maxY || arrowCollision {
            arrow.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
            arrow.physicsBody!.isDynamic = false
            arrow.zRotation = bow.zRotation
            arrow.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 100)
            arrowCollision = false
            inFlight = false
        }
        
        // simulate arrow's angular rotation
        if inFlight {
            print(arrow.zRotation)
            let angle = atan2(arrow.physicsBody!.velocity.dy, arrow.physicsBody!.velocity.dx)-1.54
            print(angle)
            arrow.zRotation = angle
        }
    }
}
