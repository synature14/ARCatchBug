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

import UIKit
import ARKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
  var sceneView: ARSKView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let view = self.view as! ARSKView? {
      sceneView = view
      sceneView.delegate = self
      let scene = GameScene.init(size: view.bounds.size)
      scene.scaleMode = .resizeFill
      scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
      view.presentScene(scene)
      view.showsFPS = true
      view.showsNodeCount = true
      
      // Load the SKScene from 'GameScene.sks'
      if let scene = SKScene(fileNamed: "GameScene") {
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
       
        // Present the scene
        view.presentScene(scene)
      }
      
      view.ignoresSiblingOrder = true
      
      view.showsFPS = true
      view.showsNodeCount = true
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let configuration = ARWorldTrackingConfiguration()
    sceneView.session.run(configuration, options: [.resetTracking])
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }
  
  override var shouldAutorotate: Bool {
    return true
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    if UIDevice.current.userInterfaceIdiom == .phone {
      return .allButUpsideDown
    } else {
      return .all
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
}

extension GameViewController: ARSKViewDelegate {
  func session(_ session: ARSession, didFailWithError error: Error) {
    print("Session failed")
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
    print("\nSession interrupted -  The app is now in the background. ")
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    print("\nSession resumed - means that play is back on again.")
    sceneView.session.run(session.configuration!,
                          options: [.resetTracking,
                                    .removeExistingAnchors])
  }
  
  // To find out what sort of SKNode you want to attach to this anchor.
  func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
    var node: SKNode?
    if let anchor = anchor as? Anchor {
      if let type = anchor.type {
        node = SKSpriteNode(imageNamed: type.rawValue)
        node?.name = type.rawValue
      }
    }
    return node
  }
  
}
