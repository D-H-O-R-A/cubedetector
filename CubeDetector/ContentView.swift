//
//  ContentView.swift
//  CubeDetector
//
//  Created by user268572 on 12/6/24.
//

import SwiftUI
import ARKit
import RealityKit

struct ContentView: View {
    var body: some View {
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.autoenablesDefaultLighting = true
        
        // Configuração da sessão AR
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Atualizações da interface, se necessário
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            // Detecta o tamanho do objeto com base no plano detectado
            let objectSize = estimateObjectSize(from: planeAnchor)
            
            // Se o objeto estiver fora do alcance, avisa o usuário
            if isObjectOutOfBounds(objectSize: objectSize) {
                DispatchQueue.main.async {
                    print("Afaste-se um pouco para detectar corretamente.")
                }
                return
            }
            
            // Cria o cubo ajustado ao tamanho do objeto
            let cubeNode = createTransparentCube(size: objectSize)
            cubeNode.position = SCNVector3(planeAnchor.center.x, Float(objectSize.height) / 2, planeAnchor.center.z)
            
            // Adiciona o cubo ao nó da cena
            node.addChildNode(cubeNode)
            
            // Adiciona um objeto dentro do cubo
            let objectNode = createObjectNode(size: objectSize)
            cubeNode.addChildNode(objectNode)
        }
        
        func estimateObjectSize(from planeAnchor: ARPlaneAnchor) -> (width: CGFloat, height: CGFloat, length: CGFloat) {
            let width = CGFloat(planeAnchor.extent.x)
            let length = CGFloat(planeAnchor.extent.z)
            let height: CGFloat = 0.2 // Altura padrão
            
            return (width, height, length)
        }
        
        func isObjectOutOfBounds(objectSize: (width: CGFloat, height: CGFloat, length: CGFloat)) -> Bool {
            let maxDistance: CGFloat = 2.0
            let minDistance: CGFloat = 0.3
            
            let tooClose = objectSize.width < minDistance || objectSize.length < minDistance
            let tooFar = objectSize.width > maxDistance || objectSize.length > maxDistance
            
            return tooClose || tooFar
        }
        
        func createTransparentCube(size: (width: CGFloat, height: CGFloat, length: CGFloat)) -> SCNNode {
            let transparentMaterial = SCNMaterial()
            transparentMaterial.diffuse.contents = UIColor.clear
            transparentMaterial.isDoubleSided = true
            
            let boxGeometry = SCNBox(width: size.width, height: size.height, length: size.length, chamferRadius: 0)
            boxGeometry.materials = Array(repeating: transparentMaterial, count: 6)
            
            let cubeNode = SCNNode(geometry: boxGeometry)
            let edgeNode = createEdgeLines(size: size)
            cubeNode.addChildNode(edgeNode)
            
            return cubeNode
        }
        
        func createEdgeLines(size: (width: CGFloat, height: CGFloat, length: CGFloat)) -> SCNNode {
            let edgeNode = SCNNode()
            let edgeColor = UIColor.yellow
            let edgeThickness: CGFloat = 0.005
            
            let positions: [(SCNVector3, SCNVector3)] = [
                (SCNVector3(-size.width/2, 0, -size.length/2), SCNVector3(size.width/2, 0, -size.length/2)),
                (SCNVector3(-size.width/2, 0, size.length/2), SCNVector3(size.width/2, 0, size.length/2)),
                (SCNVector3(-size.width/2, 0, -size.length/2), SCNVector3(-size.width/2, size.height, -size.length/2)),
                (SCNVector3(size.width/2, 0, -size.length/2), SCNVector3(size.width/2, size.height, -size.length/2)),
                (SCNVector3(-size.width/2, size.height, -size.length/2), SCNVector3(size.width/2, size.height, -size.length/2)),
                (SCNVector3(-size.width/2, size.height, size.length/2), SCNVector3(size.width/2, size.height, size.length/2))
            ]
            
            for (start, end) in positions {
                let line = createLine(from: start, to: end, color: edgeColor, thickness: edgeThickness)
                edgeNode.addChildNode(line)
            }
            
            return edgeNode
        }
        
        func createLine(from start: SCNVector3, to end: SCNVector3, color: UIColor, thickness: CGFloat) -> SCNNode {
            let vertices = [start, end]
            let source = SCNGeometrySource(vertices: vertices)
            let indices: [UInt8] = [0, 1]
            let element = SCNGeometryElement(indices: indices, primitiveType: .line)
            
            let geometry = SCNGeometry(sources: [source], elements: [element])
            geometry.firstMaterial?.diffuse.contents = color
            
            let lineNode = SCNNode(geometry: geometry)
            return lineNode
        }
        
        func createObjectNode(size: (width: CGFloat, height: CGFloat, length: CGFloat)) -> SCNNode {
            let sphereGeometry = SCNSphere(radius: size.height / 4)
            sphereGeometry.firstMaterial?.diffuse.contents = UIColor.red
            let sphereNode = SCNNode(geometry: sphereGeometry)
            sphereNode.position = SCNVector3(0, size.height / 2, 0)
            return sphereNode
        }
    }
}


#Preview{
    ARViewContainer()
}
