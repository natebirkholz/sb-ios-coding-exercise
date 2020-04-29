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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        recommendationImageView.image = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        activityIndicator.hidesWhenStopped = true
    }
}
