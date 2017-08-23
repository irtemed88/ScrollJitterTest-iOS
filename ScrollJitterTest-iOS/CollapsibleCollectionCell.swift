//
//  CollapsibleCollectionCell.swift
//  ScrollJitterTest-iOS
//
//  Created by Demetri Miller on 8/18/17.
//  Copyright © 2017 Demetri Miller. All rights reserved.
//

import Foundation
import UIKit

class CollapsibleCollectionCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!

    // MARK: - Lifecycle
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        contentView.clipsToBounds = true
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        disableLayerMask()
        super.prepareForReuse()
    }
}
