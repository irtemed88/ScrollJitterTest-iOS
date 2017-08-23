//
//  CollapsibleLayout.swift
//  ScrollJitterTest-iOS
//
//  Created by Demetri Miller on 8/18/17.
//  Copyright © 2017 Demetri Miller. All rights reserved.
//

import Foundation
import UIKit

class CollapsibleLayout: UICollectionViewFlowLayout {
    static let mainHeaderZIndex = 100
    static let sectionHeaderZIndex = 50

    var mainHeaderDockedHeight: CGFloat = 0 {
        didSet {
            assert(mainHeaderDockedHeight >= 0, "DockedHeight should be greater than zero. Current value: \(mainHeaderDockedHeight)")
        }
    }

    override var collectionViewContentSize: CGSize {
        let propsedContentSize = super.collectionViewContentSize
        let height = max(propsedContentSize.height, minimumContentHeight)
        return CGSize(width: propsedContentSize.width, height: height)
    }

    private var minimumContentHeight: CGFloat {
        // For expand/collapse purposes we need to have a minimum content
        // size. Otherwise we can encounter some unsightly animations during
        // removal of cells.
        // The content height is the height of the collectionView
        // plus the height of our header cell.
        var height: CGFloat = collectionView?.bounds.size.height ?? 0
        if let attributes = layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) {
            height += max(0, attributes.bounds.height - mainHeaderDockedHeight)
        }

        return height
    }


    // MARK: - Layout Overrides
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var attributesArray = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        guard let contentOffset = collectionView?.contentOffset else {
            return attributesArray
        }

        for (index, attributes) in attributesArray.enumerated() {
            if attributes.indexPath.section == 0 {
                attributesArray[index] = dockedAttributes(forMainHeaderAttributes: attributes,
                                                          contentOffset: contentOffset,
                                                          dockedHeight: mainHeaderDockedHeight)
            }
        }

        let sectionHeaderAttributesArray = attributesArray.filter { $0.representedElementKind == UICollectionElementKindSectionHeader }
        let dockedSectionAttributesArray = dockedAttributes(forSectionHeaderAttributesArray: sectionHeaderAttributesArray,
                                                            contentOffset: contentOffset,
                                                            dockedHeight: mainHeaderDockedHeight)

        for dockedAttributes in dockedSectionAttributesArray {
            if let index = attributesArray.index(where: { dockedAttributes.indexPath == $0.indexPath && dockedAttributes.representedElementKind == $0.representedElementKind }) {
                attributesArray[index] = dockedAttributes
            }
        }

        return attributesArray
    }

    // Cap the position of this item so the docked height is always visible.
    private func dockedAttributes(forMainHeaderAttributes mainHeaderAttributes: UICollectionViewLayoutAttributes, contentOffset: CGPoint, dockedHeight: CGFloat) -> UICollectionViewLayoutAttributes {
        let attributesCopy = mainHeaderAttributes.copy() as! UICollectionViewLayoutAttributes
        var frame = attributesCopy.frame
        frame.origin.y = max(frame.origin.y, contentOffset.y - frame.size.height + dockedHeight)
        attributesCopy.frame = frame
        attributesCopy.zIndex = CollapsibleLayout.mainHeaderZIndex
        return attributesCopy
    }

    // Cap the position of our headers so they dock below the docking height. We take an array of attributes
    // here since the position of one section header can affect another.
    private func dockedAttributes(forSectionHeaderAttributesArray attributesArray: [UICollectionViewLayoutAttributes], contentOffset: CGPoint, dockedHeight: CGFloat) -> [UICollectionViewLayoutAttributes] {
        // First, make copies of all the attributes objects.
        let attributesArrayCopy = attributesArray.map { $0.copy() as! UICollectionViewLayoutAttributes }

        // Now that we have the copy, apply the same docking logic to all the headers so they're below the dockedHeight.
        let dockedOriginY = contentOffset.y + dockedHeight
        var dockedAttributesArray = [UICollectionViewLayoutAttributes]()

        var prevAttributes: UICollectionViewLayoutAttributes?
        for attributes in attributesArrayCopy {
            var frame = attributes.frame
            frame.origin.y = max(frame.origin.y, dockedOriginY)
            attributes.frame = frame
            attributes.zIndex = CollapsibleLayout.sectionHeaderZIndex

            // If the current frame's origin intersects with the previous layout attributes frame,
            // we need to track it as well for the "push" behavior when sections change.
            let originInPrevAttributesFrame = prevAttributes?.frame.contains(frame.origin) ?? false
            if frame.origin.y == dockedOriginY || originInPrevAttributesFrame {
                dockedAttributesArray.append(attributes)
            }

            prevAttributes = attributes
        }

        // Sort the docked attributes by section so we can stack them on top of one another.
        dockedAttributesArray = dockedAttributesArray.sorted(by: { $0.0.indexPath.section < $0.1.indexPath.section })

        // All the sectionHeader attributes are now docked if necessary and sorted by section. Stack them
        // on top of each other to get the "push out of the way" behavior the user sees
        // when sections change.
        var prevOriginY = dockedAttributesArray.last?.frame.maxY ?? 0
        for dockedAttributes in dockedAttributesArray.reversed() {
            prevOriginY -= dockedAttributes.frame.height

            var frame = dockedAttributes.frame
            frame.origin.y = prevOriginY
            dockedAttributes.frame = frame
        }

        return dockedAttributesArray
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let mainHeaderHeight = layoutAttributesForItem(at: IndexPath(item: 0, section: 0))?.frame.height else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let headerHeightExcludingDockedPortion = mainHeaderHeight - mainHeaderDockedHeight
        var targetOffset = proposedContentOffset
        if (proposedContentOffset.y > 0) && (proposedContentOffset.y < headerHeightExcludingDockedPortion) {
            // Take into account the velocity when figuring out which direction to which we should snap.
            let midpoint = headerHeightExcludingDockedPortion / 2

            var velocityAdjustedOffsetY = targetOffset.y + (velocity.y * 100)   // Convert velocity to point/deciseconds
            if velocityAdjustedOffsetY > midpoint {
                velocityAdjustedOffsetY = headerHeightExcludingDockedPortion
            } else {
                velocityAdjustedOffsetY = 0
            }

            targetOffset.y = velocityAdjustedOffsetY
        }

        return targetOffset
    }
}
