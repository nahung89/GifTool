//
//  WatermarkView.swift
//  GifTool
//
//  Created by Nah on 12/15/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import UIKit

class WatermarkView: UILabel {
    
    struct Design {
        static let height: CGFloat = 23
        static let font: UIFont = UIFont.systemFont(ofSize: 13)
    }
    
    private let scale: CGFloat
    
    init(scale: CGFloat = 1) {
        self.scale = scale
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: Design.height * scale))
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initView() {
        textColor = .white
        text = "VIBBIDI.com"
        textAlignment = .center
        backgroundColor = UIColor(white: 0, alpha: 0.25)
        
        let designFont: UIFont = Design.font
        if scale == 1 {
            font = designFont
        } else {
            font = designFont.withSize(designFont.pointSize * scale)
        }
        sizeToFit()
        frame.size.height = Design.height * scale
        frame.size.width = frame.width * 84 / 68
    }
}
