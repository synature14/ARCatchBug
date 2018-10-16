/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import ARKit

class Anchor: ARAnchor {
  var type: NodeType?
}

class GameScene: SKScene {
  
  var sceneView: ARSKView {
    return view as! ARSKView
  }
  var target: SKSpriteNode!
  var hasBugSpray = false {
    didSet {
      let targetImageName = hasBugSpray ? "bugspraySight" : "sight"
      target.texture = SKTexture(imageNamed: targetImageName)
    }
  }
  
  var isWorldSetup = false
  let gameSize = CGSize(width: 2, height: 2)    // 2m, 2m
  
  private func setUpWorld() {
    guard let currentFrame = sceneView.session.currentFrame,
      let scene = SKScene(fileNamed: "Level1")
      else { return }
    
    for node in scene.children {
      if let node = node as? SKSpriteNode {
        // 1
        var translation = matrix_identity_float4x4
        // 2
        let positionX = node.position.x / scene.size.width
        let positionY = node.position.y / scene.size.height
        
        translation.columns.3.x = Float(positionX * gameSize.width)
        // a random value between (0 - 0.5) and (1 - 0.5)
        // It assumes the user is holding the device at least half a meter off the ground.
        translation.columns.3.y = Float(drand48() - 0.5)
        // Turning 2D into 3D, you use the y-coordinate of the 2D scene as the z-coordinate in 3D space.
        translation.columns.3.z = Float(positionY * gameSize.height)
        
        // ARKit will place the anchor at the correct position in 3D space relative to the camera.
        let transform = currentFrame.camera.transform * translation
        
        let anchor = Anchor(transform: transform)
        if let name = node.name, let type = NodeType(rawValue: name) {
          anchor.type = type
          sceneView.session.add(anchor: anchor)   // Each frame tracks this anchor and recalculates the transformation matrices of the anchors and the camera using the device’s new position and orientation.
          if anchor.type == .firebug {
            addBugSpray(to: currentFrame)
          }

        }
      }
    }

    isWorldSetup = true
  }
  
  private func addBugSpray(to currentFrame: ARFrame) {
    var translation = matrix_identity_float4x4
    translation.columns.3.x = Float(drand48()*2 - 1)
    translation.columns.3.z = -Float(drand48()*2 - 1)
    translation.columns.3.y = Float(drand48() - 0.5)
    
    let transform = currentFrame.camera.transform * translation
    let sprayAnchor = Anchor(transform: transform)
    sprayAnchor.type = .bugspray
    sceneView.session.add(anchor: sprayAnchor)
  }
  
  private func remove(bugspray anchor: ARAnchor) {
    run(Sounds.bugspray)
    sceneView.session.remove(anchor: anchor)
    hasBugSpray = true
  }
  
  override func didMove(to view: SKView) {
    target = SKSpriteNode(imageNamed: "sight")
    srand48(Int(Date.timeIntervalSinceReferenceDate)) // To seed the random number generator, Otherwise the random number will be the same every time you build
    addChild(target)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    let location = target.position
    let hitNodes = nodes(at: location)
    
    // hitNodes array and find out if any of the nodes in the array are bugs
    var hitBug: SKNode?
    for node in hitNodes {
      if node.name == NodeType.bug.rawValue ||
        (node.name == NodeType.firebug.rawValue && hasBugSpray) {
          hitBug = node
          break
      }
    }
    
    run(Sounds.fire)
    if let hitBug = hitBug, let anchor = sceneView.anchor(for: hitBug) {
      let action = SKAction.run {
        self.sceneView.session.remove(anchor: anchor)
      }
      let group = SKAction.group([Sounds.hit, action])
      let sequence = [SKAction.wait(forDuration: 0.3), group]
      hitBug.run(SKAction.sequence(sequence))
    }
    hasBugSpray = false
  }
  
  override func update(_ currentTime: TimeInterval) {
    // Called before each frame is rendered
    if !isWorldSetup {
      setUpWorld()
    }
    // 1
    guard let currentFrame = sceneView.session.currentFrame,
      let lightEstimate = currentFrame.lightEstimate else {
        return
    }
    
    // 2
    let neutralIntensity: CGFloat = 1000
    let ambientIntensity = min(lightEstimate.ambientIntensity,
                               neutralIntensity)
    let blendFactor = 1 - ambientIntensity / neutralIntensity
    
    // 3
    for node in children {
      if let bug = node as? SKSpriteNode {
        bug.color = .black
        bug.colorBlendFactor = blendFactor
      }
    }
    
    for anchor in currentFrame.anchors {
      // Xcode 버그 이슈 - ARAnchor의 서브클래스에선 lose its properties.. 따라서 anchor.type == NodeType.bugspray 이렇게 비교 못함..
      guard let node = sceneView.node(for: anchor),
        node.name == NodeType.bugspray.rawValue else {
        continue
      }
      
      // ARKit includes the framework simd, which provides a distance function. You use this to calculate the distance between the anchor and the camera.
      // 여기에선 bugspray의 위치와 카메라가 담고있은 현실세계의 위치의 차이가 distance
      let distance = simd_distance(anchor.transform.columns.3, currentFrame.camera.transform.columns.3)
      if distance < 0.8 {
        remove(bugspray: anchor)  // If the distance is less than 80 centimeters, you remove the anchor from the session. This will remove the bug spray node as well.
        break
      }
    }
    
  }
}

