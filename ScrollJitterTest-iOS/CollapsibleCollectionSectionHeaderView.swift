//
//  CollapsibleCollectionHeader.swift
//  ScrollJitterTest-iOS
//
//  Created by Demetri Miller on 8/18/17.
//  Copyright © 2017 Demetri Miller. All rights reserved.
//

import Foundation
import UIKit

class CollapsibleCollectionSectionHeaderView: UICollectionReusableView {
    @IBOutlet weak var label: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    private var tapGestureRecognizer: UITapGestureRecognizer!

    var onTap: ((CollapsibleCollectionSectionHeaderView) -> Void)?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.white.withAlphaComponent(0.10)

        label?.textColor = .white
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGestureRecognizer)
    }

    override func prepareForReuse() {
        disableLayerMask()
        super.prepareForReuse()
    }


    // MARK: - User Interaction
    private dynamic func handleTapGesture() {
        onTap?(self)
    }


    // MARK: - UI Management
    func setCollapsed(collapsed: Bool, animated: Bool = false) {
        let transform = collapsed ? CGAffineTransform(rotationAngle: CGFloat.pi / 2) : CGAffineTransform.identity
        UIView.animate(withDuration: 0.2) {
            self.imageView.transform = transform
        }
    }
}
