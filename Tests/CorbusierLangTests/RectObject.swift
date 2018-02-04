//
//  RectObject.swift
//  CorbusierLangTests
//
//  Created by Олег on 04.02.2018.
//

import Foundation
import CoreCorbusier

class RectObject : CRBObject {
    
    fileprivate enum Anchors : String {
        case top
        case bottom
    }
    
    fileprivate enum PlaceAnchor : String {
        case bottomLeft
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
    
    func place(at point: CRBPoint, fromAnchorWith name: CRBAnchorName) {
        let anchor = PlaceAnchor(rawValue: name.rawValue)!
        let cgrect: CGRect
        switch anchor {
        case .bottomLeft:
            cgrect = CGRect(origin: CGPoint.init(x: point.x, y: point.y),
                            size: self.size)
        }
        let rect = Rect(rect: cgrect)
        self.state = .placed(rect)
    }
    
    func isAnchorSupported(anchorName: CRBAnchorName) -> Bool {
        if isUnplaced {
            return PlaceAnchor(rawValue: anchorName.rawValue) != nil
        } else {
            return Anchors(rawValue: anchorName.rawValue) != nil
        }
    }
    
}

class Rect : CRBPlacedObjectTrait {
    
    internal let rect: CGRect
    
    init(rect: CGRect) {
        self.rect = rect
    }
    
    func anchor(with name: CRBAnchorName) -> CRBAnchor? {
        guard let anch = RectObject.Anchors(rawValue: name.rawValue) else {
            return nil
        }
        switch anch {
        case .top:
            let point = CRBPoint(x: rect.minX + rect.width / 2, y: rect.maxY)
            let vector = CRBVector(dx: 0, dy: +1).alreadyNormalized()
            return CRBAnchor(point: point, normalizedVector: vector)
        case .bottom:
            let point = CRBPoint(x: rect.minX + rect.width / 2, y: rect.minY)
            let vector = CRBVector(dx: 0, dy: -1).alreadyNormalized()
            return CRBAnchor(point: point, normalizedVector: vector)
        }
    }
    
}
