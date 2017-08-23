//
//  CollapsibleCollectionViewController.swift
//  ScrollJitterTest-iOS
//
//  Created by Demetri Miller on 8/18/17.
//  Copyright © 2017 Demetri Miller. All rights reserved.
//

import Foundation
import UIKit

protocol MaskableView {
    var layerMask: CALayer { get }

    func enableLayerMask(withFrame frame: CGRect)
    func disableLayerMask()
}

extension UICollectionReusableView: MaskableView {
    private static var layerMaskKey = "layerMaskKey"

    var layerMask: CALayer {
        if let mask = objc_getAssociatedObject(self, &UICollectionReusableView.layerMaskKey) as? CALayer {
            return mask
        }

        let mask = CALayer()
        mask.backgroundColor = UIColor.black.cgColor
        mask.actions = ["position" : NSNull(), "bounds" : NSNull()]
        objc_setAssociatedObject(self, &UICollectionReusableView.layerMaskKey, mask, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return mask
    }

    func enableLayerMask(withFrame frame: CGRect) {
        if layer.mask == nil {
            layer.mask = layerMask
        }

        layerMask.frame = frame
    }

    func disableLayerMask() {
        layer.mask = nil
    }
}


class CollapsibleCollectionViewController: UIViewController {
    fileprivate static let sectionHeaderNibName = "CollapsibleCollectionSectionHeaderView"
    fileprivate static let cellReuseId = "CollapsibleCollectionCell"
    fileprivate static let headerReuseId = "HeaderCell"

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewLayout: CollapsibleLayout!

    fileprivate let data = [
        ["Apple", "Banana", "Cantaloupe"],
        ["Broccoli", "Califlower", "Dragonfruit"],
        ["Cheerios", "Trix", "Lucky Charms"],
        ["Trombone", "French Horn", "Cello"]
    ]

    private var mainHeaderIndexPath: IndexPath {
        return IndexPath(item: 0, section: 0)
    }

    lazy var collapsedSections: [Bool] = {
        return self.data.map { _ in return false }
    }()


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionViewLayout.mainHeaderDockedHeight = 50

        let nib = UINib(nibName: CollapsibleCollectionViewController.sectionHeaderNibName, bundle: nil)
        collectionView.register(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CollapsibleCollectionViewController.sectionHeaderNibName)

        collectionView.addObserver(self, forKeyPath: "contentOffset", options: [.initial, .new], context: nil)
    }

    deinit {
        collectionView.removeObserver(self, forKeyPath: "contentOffset")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        applyMaskingToVisibleCells()
        applyMaskingToSupplementaryViews()
    }


    // MARK: - Scroll Management/Cell Masking
    // Apply a layer mask to any visible cell that has a rect
    // intersecting with its section header. We need to do this since the
    // section headers are transparent and content scrolls underneath them.
    fileprivate func applyMaskingToVisibleCells() {
        for cell in collectionView.visibleCells {
            guard
                let cell = cell as? CollapsibleCollectionCell,
                let cellPath = collectionView.indexPath(for: cell),
                let sectionHeaderView = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: cellPath.section))
            else {
                    continue
            }

            // If the cell's frame intersects or has a smaller maxY than its header, apply a mask. Otherwise
            // remove any layer mask from the cell.
            if cell.frame.intersects(sectionHeaderView.frame) || cell.frame.maxY < sectionHeaderView.frame.maxY {
                let originY = abs(cell.frame.minY - sectionHeaderView.frame.maxY)
                let visibleCellHeight = cell.frame.maxY - (cell.frame.minY - sectionHeaderView.frame.maxY)
                let maskFrame = CGRect(x: 0, y: originY, width: cell.bounds.size.width, height: visibleCellHeight)

                cell.enableLayerMask(withFrame: maskFrame)
            } else {
                cell.disableLayerMask()
            }
        }
    }

    private func applyMaskingToSupplementaryViews() {
        guard let mainHeaderView = collectionView.cellForItem(at: mainHeaderIndexPath) else {
            return
        }

        let visibleHeaderViews = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader)
        for headerView in visibleHeaderViews {
            // If the header frame intersects the main header, apply a mask. Otherwise
            // remove any layer mask from the cell.
            if headerView.frame.intersects(mainHeaderView.frame) {
                let originY = abs(headerView.frame.minY - mainHeaderView.frame.maxY)
                let visibleHeaderHeight = max(headerView.frame.maxY - mainHeaderView.frame.maxY, 0)
                let maskFrame = CGRect(x: 0, y: originY, width: headerView.bounds.size.width, height: visibleHeaderHeight)
                headerView.enableLayerMask(withFrame: maskFrame)
            } else {
                headerView.disableLayerMask()
            }
        }
    }

    // MARK: - Collapse/Expansion Management
    fileprivate func toggleCollapsed(section: Int) {
        let shouldCollapse = !collapsedSections[section]

        collapsedSections[section] = shouldCollapse

        let headerPath = IndexPath(item: 0, section: section + 1)
        if let headerView = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: headerPath) as? CollapsibleCollectionSectionHeaderView {
            headerView.setCollapsed(collapsed: shouldCollapse)
        }

        let itemPaths = self.data[section].enumerated().map { tuple in return IndexPath(item: tuple.offset, section: section + 1) }
        if (shouldCollapse) {
            collectionView.deleteItems(at: itemPaths)
        } else {
            collectionView.insertItems(at: itemPaths)
        }
    }
}

extension CollapsibleCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: collectionView.bounds.size.width, height: 300)
        }
        return CGSize(width: collectionView.bounds.size.width, height: 44)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return .zero
        }
        return CGSize(width: collectionView.bounds.size.width, height: 60)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1}

        let adjustedSectionIndex = section - 1
        return collapsedSections[adjustedSectionIndex] ? 0 : data[adjustedSectionIndex].count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let adjustedSection = indexPath.section - 1

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollapsibleCollectionViewController.sectionHeaderNibName, for: indexPath) as! CollapsibleCollectionSectionHeaderView
        view.label.text = "Header \(indexPath.section)"
        view.onTap = { [weak self] headerView in
            self?.toggleCollapsed(section: adjustedSection)
        }
        return view
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollapsibleCollectionViewController.headerReuseId, for: indexPath) as! HeaderCell
            return cell
        }

        let adjustedSection = indexPath.section - 1
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollapsibleCollectionViewController.cellReuseId, for: indexPath) as! CollapsibleCollectionCell
        cell.contentView.backgroundColor = .green
        cell.label.text = data[adjustedSection][indexPath.row]
        return cell
    }
}
