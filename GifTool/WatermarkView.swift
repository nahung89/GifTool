//
//  WatermarkView.swift
//  GifTool
//
//  Created by Nah on 12/15/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import UIKit

class WatermarkView: UIView {
    
    let label = UILabel()
    let imageView = UIImageView()
    
    struct Design {
        static let font: UIFont = UIFont.FontHardBold(11)
        static let logoHeight: CGFloat = 24
    }
    
    private let scale: CGFloat
    
    init(scale: CGFloat = 1) {
        self.scale = scale
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: CommentItemView.Design.height * scale))
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initView() {
        label.frame = CGRect(x: 0, y: 0, width: 0, height: CommentItemView.Design.height * scale)
        label.textColor = .white
        label.text = "vibbidi.com"
        label.textAlignment = .right
        
        let designFont: UIFont = Design.font
        if scale == 1 {
            label.font = designFont
        } else {
            label.font = designFont.withSize(designFont.pointSize * scale)
        }
        label.sizeToFit()
        label.frame.size.height = CommentItemView.Design.height * scale
        addSubview(label)
        
        imageView.image = #imageLiteral(resourceName: "VibbidiIcon")
        imageView.frame = CGRect(x: label.frame.maxX + 8 * scale, y: 0, width: Design.logoHeight * scale, height: Design.logoHeight * scale)
        addSubview(imageView)
        imageView.layer.cornerRadius = 5 * scale
        imageView.layer.masksToBounds = true
        
        frame.size.width = imageView.frame.maxX + 8 * scale
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame.origin.y = (frame.height - label.frame.height) / 2
        imageView.frame.origin.y = (frame.height - imageView.frame.height) / 2
    }
}
