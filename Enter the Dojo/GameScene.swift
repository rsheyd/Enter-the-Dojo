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
        // enemy movement, time should be / 70
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
        enemy.name = "enemy"
        
        // set random position for enemy nodes
        let randomNum = arc4random_uniform(UInt32(self.frame.width-100))
        let randomX = CGFloat(randomNum) - self.frame.width/2 + 50
        // y deployment value is "self.frame.maxY + 100"
        enemy.position = CGPoint(x: randomX, y: self.frame.maxY + 100)

        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemyTexture.size())
        enemy.physicsBody!.isDynamic = true
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.categoryBitMask = ColliderType.Enemy.rawValue
        enemy.physicsBody!.contactTestBitMask = ColliderType.Ground.rawValue
        
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
        arrow.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 400)
        arrow.physicsBody = SKPhysicsBody(rectangleOf: arrowTexture.size())
        arrow.physicsBody!.isDynamic = false
        arrow.physicsBody!.categoryBitMask = ColliderType.Arrow.rawValue
        arrow.physicsBody!.contactTestBitMask = ColliderType.Ground.rawValue | ColliderType.Enemy.rawValue
        arrow.physicsBody!.usesPreciseCollisionDetection = true
        arrow.name = "arrow"
        self.addChild(arrow)
        
        let bowTexture = SKTexture (imageNamed: "blue-bow.png")
        bow = SKSpriteNode(texture: bowTexture)
        bow.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 400)
        self.addChild(bow)
        
        let ground = SKNode()
        ground.position = CGPoint(x: self.frame.midX, y: self.frame.minY)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: 1))
        ground.physicsBody!.isDynamic = false
        ground.physicsBody!.categoryBitMask = ColliderType.Ground.rawValue
        ground.physicsBody!.contactTestBitMask = ColliderType.Enemy.rawValue
        ground.name = "ground"
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
        if gameOver == false {
            for touch in touches {
                previousPoint = touch.location(in: self)
            }
        }
        else {
            gameOver = false
            score = 0
            self.speed = 1
            self.removeAllChildren()
            setupGame()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let currentPoint = touch.location(in: self)
            let distance = currentPoint.x - previousPoint.x
            let pullAmount = previousPoint.y - currentPoint.y
            previousPoint = currentPoint
            arrow.zRotation = arrow.zRotation - distance/100.0
            bow.zRotation = bow.zRotation - distance/100.0
            power += Int(pullAmount)
            powerLabel.text = String(power)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        arrow.physicsBody!.isDynamic = true
        arrow.physicsBody!.applyImpulse(CGVector(dx: arrow.zRotation * -120, dy: CGFloat(power)))
        power = 0
        powerLabel.text = "0"
        inFlight = true
    }
    
    func arrowCollided(with node: SKNode) {
        if node.name == "enemy" {
            node.removeFromParent()
            arrowCollision = true
            score += 1
            scoreLabel.text = String(score)
        } else if node.name == "ground" {
            arrowCollision = true
        }
    }
    
    func enemyCollided(with node: SKNode) {
        if node.name == "ground" {
            self.speed = 0
            gameOver = true
            timer.invalidate()
            
            let gameOverLabel = SKLabelNode(text: "Game Over!")
            gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 80)
            gameOverLabel.fontSize = 70
            let finalScoreLabel = SKLabelNode(text: "Your score is \(scoreLabel.text!)")
            finalScoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            finalScoreLabel.fontSize = 70
            let tapLabel = SKLabelNode(text: "Tap to play again.")
            tapLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 80)
            tapLabel.fontSize = 70
            self.addChild(gameOverLabel)
            self.addChild(finalScoreLabel)
            self.addChild(tapLabel)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameOver == false {
            // arrow collision with ground or enemy
            if contact.bodyA.node?.name == "arrow" {
                arrowCollided(with: contact.bodyB.node!)
            } else if contact.bodyB.node?.name == "arrow" {
                arrowCollided(with: contact.bodyA.node!)
            }
            
            // enemy collision with ground
            if contact.bodyA.node?.name == "enemy" {
                enemyCollided(with: contact.bodyB.node!)
            } else if contact.bodyB.node?.name == "enemy" {
                enemyCollided(with: contact.bodyA.node!)
            }
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // reset arrow when out of bounds or collided with ground or enemy
        if arrow.position.x > self.frame.maxX || arrow.position.x < self.frame.minX || arrow.position.y > self.frame.maxY || arrowCollision {
            arrow.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
            arrow.physicsBody!.isDynamic = false
            arrow.zRotation = bow.zRotation
            arrow.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 400)
            arrowCollision = false
            inFlight = false
        }
        
        // simulate arrow's angular rotation
        if inFlight {
            let angle = atan2(arrow.physicsBody!.velocity.dy, arrow.physicsBody!.velocity.dx)-1.54
            arrow.zRotation = angle
        }
    }
}
