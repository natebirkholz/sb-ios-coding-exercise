//
//  RecommendationTableViewCell.swift
//  Recommendations
//

import UIKit

class RecommendationTableViewCell: UITableViewCell {
    @IBOutlet weak var recommendationImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var taglineLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        recommendationImageView.image = nil
    }
}
