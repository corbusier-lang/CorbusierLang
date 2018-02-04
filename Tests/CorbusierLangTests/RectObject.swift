//
//  RectObject.swift
//  CorbusierLangTests
//
//  Created by Олег on 04.02.2018.
//

import Foundation
import CoreCorbusier

func ~=<T : Equatable>(array: [T], value: [T]) -> Bool {
    return array == value
}

struct CGSizeSide : CRBAnchorEnvironment {
    
    let a: CRBPoint
    let b: CRBPoint
    let vector: CRBNormalizedVector
    
    var medium: CRBPoint {
        return CRBPoint.between(a, b, multiplier: 0.5)
    }
    
    var names: (CRBAnchorName, CRBAnchorName, CRBAnchorName)
    
    func anchor(with name: CRBAnchorName) -> CRBAnchor? {
        if name == names.0 {
            return CRBAnchor(point: a,
                             normalizedVector: vector)
        } else if name == names.1 {
            return CRBAnchor(point: medium,
                             normalizedVector: vector)
        } else if name == names.2 {
            return CRBAnchor(point: b,
                             normalizedVector: vector)
        }
        return nil
    }
    
}

class RectObject : CRBObject {
    
    fileprivate enum Anchors : String {
        case top
        case bottom
    }
    
    fileprivate enum PlaceAnchor : String {
        case topLeft
    }
    
    var state: CRBObjectState
    fileprivate let size: CGSize
    
    init(size: CGSize) {
        self.size = size
        self.state = .unplaced
    }
    
    init(rect: CGRect) {
        self.size = rect.size
        let rect = Rect(rect: rect)
        self.state = .placed(rect)
    }
    
    func place(at point: CRBPoint, fromAnchorWith keyPath: CRBAnchorKeyPath) {
        let cgrect: CGRect
        let path = keyPath.map({ $0.rawValue })
        switch path {
        case ["top", "left"], ["left", "top"]:
            cgrect = CGRect(origin: CGPoint.init(x: point.x, y: point.y - size.height), size: size)
        case ["top", "center"], ["top"]:
            cgrect = CGRect(origin: CGPoint.init(x: point.x + size.width / 2, y: point.y - size.height), size: size)
        case ["top", "right"], ["right", "top"]:
            cgrect = CGRect(origin: CGPoint.init(x: point.x + size.width, y: point.y - size.height), size: size)
        default:
            cgrect = .zero
        }
        self.state = .placed(Rect(rect: cgrect))
    }
    
    func isAnchorSupported(anchorName: CRBAnchorKeyPath) -> Bool {
        return Rect(rect: .zero).anchor(at: anchorName) != nil
    }
    
}

class Rect : CRBAnchorEnvironment {
    
    internal let rect: CGRect
    
    init(rect: CGRect) {
        self.rect = rect
    }
    
    func anchor(with name: CRBAnchorName) -> CRBAnchor? {
        switch name.rawValue {
        case "top":
            let side = CGSizeSide(a: CRBPoint.init(x: rect.minX, y: rect.maxY),
                                  b: CRBPoint.init(x: rect.maxX, y: rect.maxY),
                                  vector: CRBVector.init(dx: 0, dy: +1).alreadyNormalized(),
                                  names: (crbname("left"), crbname("center"), crbname("right")))
            return CRBAnchor(point: side.medium, normalizedVector: side.vector, child: side)
        case "bottom":
            let side = CGSizeSide(a: .init(x: rect.minX, y: rect.minY),
                                  b: .init(x: rect.maxX, y: rect.minY),
                                  vector: CRBVector.init(dx: 0, dy: -1).alreadyNormalized(),
                                  names: (crbname("left"), crbname("center"), crbname("right")))
            return CRBAnchor(point: side.medium, normalizedVector: side.vector, child: side)
        case "left":
            let side = CGSizeSide(a: .init(x: rect.minX, y: rect.minY),
                                  b: .init(x: rect.minX, y: rect.maxY),
                                  vector: CRBVector.init(dx: -1, dy: 0).alreadyNormalized(),
                                  names: (crbname("bottom"), crbname("center"), crbname("top")))
            return CRBAnchor(point: side.medium, normalizedVector: side.vector, child: side)
        case "right":
            let side = CGSizeSide(a: .init(x: rect.maxX, y: rect.minY),
                                  b: .init(x: rect.maxX, y: rect.maxY),
                                  vector: CRBVector.init(dx: +1, dy: 0).alreadyNormalized(),
                                  names: (crbname("bottom"), crbname("center"), crbname("top")))
            return CRBAnchor(point: side.medium, normalizedVector: side.vector, child: side)
        default:
            return nil
        }
    }
    
}
