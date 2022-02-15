//
//  Collection View Flow.swift
//  Contract Whist Scorecard
//
//  Created by Marc Shearer on 02/06/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import UIKit

protocol CustomCollectionViewLayoutDelegate : AnyObject {
    
    func changed(_ collectionView: UICollectionView?, itemAtCenter: Int, forceScroll: Bool, animation: ViewAnimation)
}

extension CustomCollectionViewLayoutDelegate {
    
    func changed(_ collectionView: UICollectionView?, itemAtCenter: Int, forceScroll: Bool) {
        changed(collectionView, itemAtCenter: itemAtCenter, forceScroll: forceScroll, animation: .replace)
    }
}

class CustomCollectionViewLayout: UICollectionViewFlowLayout {

    private var cache: [UICollectionViewLayoutAttributes] = []
    
    @IBInspectable private var fixedFactors: Bool = true
    @IBInspectable private var alphaFactor: CGFloat = 1.0
    @IBInspectable private var scaleFactor: CGFloat = 0.98
    @IBInspectable private var direction: UICollectionView.ScrollDirection = .horizontal
    
    public weak var delegate: CustomCollectionViewLayoutDelegate!
    
    private var contentSize: CGFloat = 0.0
    private var collectionViewWidth: CGFloat = 0.0
    private var collectionViewHeight: CGFloat = 0.0
    
    private var contentOther: CGFloat {
        return (direction == .horizontal ? collectionView?.bounds.height ?? 0.0 : collectionView?.bounds.width ?? 0.0)
    }
    
    private var cellSize: CGFloat {
        return (direction == .horizontal ? self.itemSize.width : self.itemSize.height)
    }

    override internal var collectionViewContentSize: CGSize {
        if direction == .horizontal {
            return CGSize(width: self.contentSize, height: self.contentOther)
        } else {
            return CGSize(width: self.contentOther, height: self.contentSize)
        }
    }
    
    init(fixedFactors: Bool = true, alphaFactor: CGFloat = 1.0,scaleFactor: CGFloat = 0.98, direction: UICollectionView.ScrollDirection = .horizontal) {
        self.fixedFactors = fixedFactors
        self.alphaFactor = alphaFactor
        self.scaleFactor = scaleFactor
        self.direction = direction
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        cache = []
        if let collectionView = collectionView {
            let items = collectionView.numberOfItems(inSection: 0)
            
            let delegate = self.collectionView?.delegate as! UICollectionViewDelegateFlowLayout
            self.itemSize = delegate.collectionView!(collectionView, layout: self, sizeForItemAt: IndexPath(item: 0, section: 0))
            self.collectionViewWidth = collectionView.bounds.width
            self.collectionViewHeight = collectionView.bounds.height
            self.contentSize = (self.cellSize * CGFloat(items)) + 20.0
            
            for item in 0..<items {
                var frame: CGRect
                if direction == .horizontal {
                    frame = CGRect(x: CGFloat(item) * self.cellSize, y: 0, width: self.cellSize, height: self.itemSize.height)
                } else {
                    frame = CGRect(x: 0, y: CGFloat(item) * self.cellSize, width: self.itemSize.width, height: self.cellSize)
                }
                let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: 0))
                attributes.frame = frame
                cache.append(attributes)
            }
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        var layoutAttributes: [UICollectionViewLayoutAttributes] = []
        let items = cache.count
        let minPos: CGFloat = (direction == .horizontal ? rect.minX : rect.minY)
        let maxPos: CGFloat = (direction == .horizontal ? rect.maxX : rect.maxY)
        
        let minItem = max(0, Utility.round(Double(minPos / self.cellSize)))
        let maxItem = min(Utility.round(Double(maxPos / self.cellSize)), max(0,items - 1))
        if minItem < items {
            
            for item in minItem...maxItem {
                layoutAttributes.append(transformLayoutAttributes(cache[item].copy() as! UICollectionViewLayoutAttributes))
            }
            
            return layoutAttributes
            
        } else {
            return nil
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
    
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    fileprivate func transformLayoutAttributes(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        if let collectionView = self.collectionView {
        
            var alpha: CGFloat
            var scale: CGFloat

            var offsetCenter: CGFloat
            var distanceFromOffsetCenter: CGFloat
            var items: CGFloat
            if direction == .horizontal {
                offsetCenter = collectionView.contentOffset.x + (self.collectionViewWidth / 2.0)
                distanceFromOffsetCenter = abs(attributes.center.x - offsetCenter)
                items = self.collectionViewWidth / self.cellSize
            } else {
                offsetCenter = collectionView.contentOffset.y + (self.collectionViewHeight / 2.0)
                distanceFromOffsetCenter = abs(attributes.center.y - offsetCenter)
                items = self.collectionViewHeight / self.cellSize
            }
            let itemsFromCenter = (distanceFromOffsetCenter / self.cellSize)
            
            if self.fixedFactors {
                alpha = (itemsFromCenter == 0 ? 1 : alphaFactor)
                scale = (itemsFromCenter == 0 ? 1 : scaleFactor)
            } else {
                let multiplier = itemsFromCenter / (items / 2)
                alpha = 1 - (multiplier * alphaFactor)
                scale = 1 - (multiplier * scaleFactor)
            }
            
            attributes.alpha = alpha
            attributes.transform3D = CATransform3DScale(CATransform3DIdentity, scale, scale, 1)
        }
        
        return attributes
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        let size = (direction == .horizontal ? collectionViewWidth : collectionViewHeight)
        let proposedOffset = (direction == .horizontal ? proposedContentOffset.x : proposedContentOffset.y)
        
        let proposedCenter = proposedOffset + (size / 2.0)
        let itemAtCenter = Int(proposedCenter / self.cellSize)
        if let collectionView = collectionView {
            self.delegate?.changed(collectionView, itemAtCenter: itemAtCenter, forceScroll: false)
        }
        let requiredOffset = ((CGFloat(itemAtCenter) + 0.5) * self.cellSize) - (size / 2.0)
        if direction == .horizontal {
            return CGPoint(x: requiredOffset, y: proposedContentOffset.y)
        } else {
            return CGPoint(x: proposedContentOffset.x, y: requiredOffset)
        }
    }
}
