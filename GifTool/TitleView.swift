//
//  TitleView.swift
//  GifTool
//
//  Created by Nah on 12/21/17.
//  Copyright © 2017 glue-th. All rights reserved.
//

import Foundation
import UIKit

extension TitleView {
    static func calculateSize(text: String, videoWidth: CGFloat) -> CGSize {
        guard !text.isEmpty else { return CGSize.zero }
        
        let scale = videoWidth / Design.width
        let font = Design.font.withSize(Design.font.pointSize * scale)
        let padding = UIEdgeInsetsMake(Design.padding.top * scale,
                                       Design.padding.left * scale,
                                       Design.padding.bottom * scale,
                                       Design.padding.right * scale)
        
        let label = UILabel(frame: CGRect.zero)
        label.set(font: font, color: .white, text: text)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        let height: CGFloat = label.sizeThatFits(CGSize(width: videoWidth - padding.left - padding.right, height: CGFloat.greatestFiniteMagnitude)).height + padding.top + padding.bottom
        let heightForExport = ceil(height / 16) * 16
        
        return CGSize(width: videoWidth, height: heightForExport)
    }
}

class TitleView: UIView {
    
    struct Design {
        static let width: CGFloat = 375
        static let font: UIFont = UIFont.FontHeavyBold(24)
        static let padding = UIEdgeInsetsMake(13, 24, 13, 24)
    }
    
    private let titleLabel = UILabel()
    private let scale: CGFloat
    
    init(text: String, videoSize: CGSize) {
        scale = videoSize.width / Design.width
        let size = TitleView.calculateSize(text: text, videoWidth: videoSize.width)
        super.init(frame: CGRect(origin: .zero, size: size))
        titleLabel.text = text
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initView() {
        let padding = UIEdgeInsetsMake(Design.padding.top * scale,
                                       Design.padding.left * scale,
                                       Design.padding.bottom * scale,
                                       Design.padding.right * scale)
        
        titleLabel.frame = CGRect(x: padding.left,
                                  y: padding.top,
                                  width: frame.width - padding.left - padding.right,
                                  height: frame.height - padding.top - padding.bottom)
        
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        let designFont: UIFont = Design.font
        titleLabel.font = designFont.withSize(designFont.pointSize * scale)
        addSubview(titleLabel)
    }
}

