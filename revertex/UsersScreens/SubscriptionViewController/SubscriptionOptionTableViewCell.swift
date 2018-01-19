//
//  SubscriptionOptionTableViewCell.swift
//  revertex
//
//  Created by Danil Mironov on 07.12.17.
//  Copyright © 2017 Danil Mironov. All rights reserved.
//

import UIKit

class SubscriptionOptionTableViewCell: UITableViewCell {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var yourPlanLabel: UILabel!
    
    var isCurrentPlan: Bool = false {
        didSet {
            yourPlanLabel.isHidden = !isCurrentPlan
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        yourPlanLabel.isHidden = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        yourPlanLabel.isHidden = true
    }
}
