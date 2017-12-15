//
//  PreviewSourceCell.swift
//  GifTool
//
//  Created by Nah on 12/15/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import UIKit

class PreviewSourceCell: UITableViewCell {
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var compiledBtn: UIButton!
    @IBOutlet weak var completedBtn: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func set(data: Video) {
        contentLabel.text =
        """
        id: \(data.id)
        title: \(data.title) - artist: \(data.artist) - cat: \(data.category)
        start: \(data.start) - end: \(data.end) - speed: \(data.commentSpeed)
        """
        
        if let isComplied = data.isComplied {
            compiledBtn.backgroundColor = isComplied ? .green : .red
        } else {
            compiledBtn.backgroundColor = UIColor.lightGray
        }
        
        completedBtn.backgroundColor = data.isCompleted ? .green : .red
    }
}
