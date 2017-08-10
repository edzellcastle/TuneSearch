//
//  TrackTableViewCell.swift
//  TuneSearch
//
//  Created by David Lindsay on 5/22/17.
//  Copyright © 2017 Tapinfuse. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "Cell"
    
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
