//
//  GameScene.swift
//  Enter the Dojo
//
//  Created by Roman Sheydvasser on 11/10/16.
//  Copyright © 2016 RLabs. All rights reserved.
//

import SpriteKit
import GameplayKit

let Pi = CGFloat(M_PI)
let DegreesToRadians = Pi / 180
let RadiansToDegrees = 180 / Pi

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bow = SKSpriteNode()
    var arrow = SKSpriteNode()
    var bg = SKSpriteNode()
    
    var powerLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
    var powerTextLabel = SKLabelNode()
    var scoreTextLabel = SKLabelNode()
    var power = CGFloat(0)
    var score = 0
    
    var timer = Timer()
    var originalTouch : CGPoint!
    
    enum ColliderType: UInt32 {
        case Arrow = 1
        case Enemy = 2
        case Ground = 4
    }
    
    var gameOver = false
    var pulling = false
    var arrowCollision = false
    var inFlight = false
    
    var yDiff = Float()
    var xDiff = Float()
    
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
        enemy.zPosition = -1

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
        bg.zPosition = -2
        self.addChild(bg)
        
        let arrowTexture = SKTexture (imageNamed: "blue-arrow.png")
        arrow = SKSpriteNode(texture: arrowTexture)
        arrow.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 150)
        arrow.physicsBody = SKPhysicsBody(rectangleOf: arrowTexture.size())
        arrow.physicsBody!.isDynamic = false
        arrow.physicsBody!.categoryBitMask = ColliderType.Arrow.rawValue
        arrow.physicsBody!.contactTestBitMask = ColliderType.Ground.rawValue | ColliderType.Enemy.rawValue
        arrow.physicsBody!.usesPreciseCollisionDetection = true
        arrow.name = "arrow"
        self.addChild(arrow)
        
        let bowTexture = SKTexture (imageNamed: "blue-bow.png")
        bow = SKSpriteNode(texture: bowTexture)
        bow.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 150)
        self.addChild(bow)
        
        let ground = SKNode()
        ground.position = CGPoint(x: self.frame.midX, y: self.frame.minY)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: 1))
        ground.physicsBody!.isDynamic = false
        ground.physicsBody!.categoryBitMask = ColliderType.Ground.rawValue
        ground.physicsBody!.contactTestBitMask = ColliderType.Enemy.rawValue
        ground.name = "ground"
        self.addChild(ground)

        powerTextLabel.fontName = "Helvetica"
        powerTextLabel.fontSize = 50
        powerTextLabel.text = "Power"
        powerTextLabel.position = CGPoint(x: self.frame.maxX - 90, y: self.frame.maxY - 60)
        self.addChild(powerTextLabel)
        
        powerLabel.fontName = "Helvetica"
        powerLabel.fontSize = 50
        powerLabel.text = "0"
        powerLabel.position = CGPoint(x: self.frame.maxX - 90, y: self.frame.maxY - 110)
        self.addChild(powerLabel)
        
        scoreTextLabel.fontName = "Helvetica"
        scoreTextLabel.fontSize = 50
        scoreTextLabel.text = "Score"
        scoreTextLabel.position = CGPoint(x: self.frame.minX + 90, y: self.frame.maxY - 60)
        self.addChild(scoreTextLabel)
        
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = UIColor.green
        scoreLabel.text = "0"
        scoreLabel.position = CGPoint(x: self.frame.minX + 90, y: self.frame.maxY - 110)
        self.addChild(scoreLabel)
    }
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        setupGame()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver == false {
            for touch in touches {
                originalTouch = touch.location(in: self)
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
            let currentTouch = touch.location(in: self)
            
            // calculate distance from original touch point
            xDiff = Float(originalTouch.x - currentTouch.x)
            yDiff = Float(originalTouch.y - currentTouch.y)
            let pullAmount = abs(CGFloat(hypotf(yDiff, xDiff)))
            
            // rotate bow and arrow with touch
            let touchAngle = atan2(currentTouch.y, currentTouch.x)
            arrow.zRotation = touchAngle + 90 * DegreesToRadians
            bow.zRotation = arrow.zRotation
            
            // set power based on distance from original touch point and update power indicator's color
            power = pullAmount
            powerLabel.text = String(Int(power/5))
            let colorChange = power/500
            powerLabel.fontColor = UIColor(red: 1, green: 1-colorChange, blue: 1-colorChange, alpha: 1)
        }
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inFlight == false {
            arrow.physicsBody!.isDynamic = true
            arrow.physicsBody!.applyImpulse(CGVector(dx: CGFloat(xDiff), dy: CGFloat(yDiff)))
            power = 0
            powerLabel.text = "0"
            powerLabel.fontColor = UIColor.white
            inFlight = true
        }
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
            arrow.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 150)
            arrowCollision = false
            inFlight = false
        }
        
        // simulate arrow's angular rotation
        if inFlight {
            let angle = atan2(arrow.physicsBody!.velocity.dy, arrow.physicsBody!.velocity.dx) - 90 * DegreesToRadians
            arrow.zRotation = angle
        }
    }
}
