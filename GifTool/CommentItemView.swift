//
//  ChannelCommentView.swift
//  GifTool
//
//  Created by Nah on 12/15/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import AVFoundation

class CommentItemView: UIView {
    
    struct Design {
        static let duration: TimeInterval = 5
        static let font: UIFont = UIFont.boldSystemFont(ofSize: 20)
        static let height: CGFloat = 36
    }
    
    private let scale: CGFloat
    private var textFont: UIFont = Design.font
    private var emojiHeight: CGFloat = Design.height
    
    init(scale: CGFloat) {
        self.scale = scale
        let frame = CGRect(x: 0, y: 0, w: 0, h: Design.height * scale)
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initView() {
        let designFont = Design.font
        textFont = designFont.withSize(designFont.pointSize * scale)
        emojiHeight = h * 88 / 100
    }
    
    func setCommentParts(_ parts: [CommentPart]) {
        removeAllSubview()
        
        var maxX: CGFloat = 0
        for part in parts {
            switch part {
            case let .emoji(emoji):
                let ih = emojiHeight
                let iw = ih * emoji.size.w / emoji.size.h
                let iy = (h - ih) / 2
                
                let imageView = UIImageView(frame: CGRect(x: maxX, y: iy, w: iw, h: ih))
                imageView.contentMode = .scaleAspectFill
                addSubview(imageView)
                maxX += imageView.w
                
                if ImageCache.default.imageCachedType(forKey: emoji.path).cached == true {
                    let path = ImageCache.default.cachePath(forKey: emoji.path)
                    let url = URL(fileURLWithPath: path)
                    guard
                        let data = try? Data(contentsOf: url),
                        let animation = createGIFAnimation(data: data)
                        else { return }
                    imageView.layer.add(animation, forKey: "animation")
                }
                
            case let .text(message):
                let label = UILabel(x: maxX, y: 0, w: 0, h: h)
                label.set(font: textFont, color: .white, text: message)
                label.sizeToFit()
                label.h = h
                addSubview(label)
                maxX += label.w
            }
        }
        w = maxX
    }
    
    func duration(speed: TimeInterval, width: CGFloat) -> TimeInterval {
        return speed + Double(w / width) * speed
    }
    
    func animate(speed: TimeInterval, delay: TimeInterval) {
        guard let superview = self.superview else { return }
        let duration = self.duration(speed: speed, width: superview.w)
        UIView.animate(withDuration: duration, delay: delay, options: [.curveLinear, .allowUserInteraction], animations: {
            self.x = -self.w
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

extension CommentItemView {
    
    // https://stackoverflow.com/questions/24125701/set-contents-of-calayer-to-animated-gif
    // https://stackoverflow.com/questions/39785119/how-to-add-gif-image-as-layer-on-view
    func createGIFAnimation(data: Data) -> CAKeyframeAnimation?{
        
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        // guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let frameCount = CGImageSourceGetCount(src)
        
        // Total loop time
        var time : Float = 0
        
        // Arrays
        var framesArray = [AnyObject]()
        var tempTimesArray = [NSNumber]()
        
        // Loop
        for i in 0..<frameCount {
            
            // Frame default duration
            var frameDuration : Float = 0.1;
            
            let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(src, i, nil)
            guard let framePrpoerties = cfFrameProperties as? [String:AnyObject] else {return nil}
            guard let gifProperties = framePrpoerties[kCGImagePropertyGIFDictionary as String] as? [String:AnyObject]
                else { return nil }
            
            // Use kCGImagePropertyGIFUnclampedDelayTime or kCGImagePropertyGIFDelayTime
            if let delayTimeUnclampedProp = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
                frameDuration = delayTimeUnclampedProp.floatValue
            }
            else{
                if let delayTimeProp = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                    frameDuration = delayTimeProp.floatValue
                }
            }
            
            // Make sure its not too small
            if frameDuration < 0.011 {
                log.severe("TOO SMALL!")
                frameDuration = 0.100;
            }
            
            // Add frame to array of frames
            if let frame = CGImageSourceCreateImageAtIndex(src, i, nil) {
                tempTimesArray.append(NSNumber(value: frameDuration))
                framesArray.append(frame)
            }
            
            // Compile total loop time
            time = time + frameDuration
        }
        
        var timesArray = [NSNumber]()
        var base : Float = 0
        for duration in tempTimesArray {
            timesArray.append(NSNumber(value: base))
            base += duration.floatValue / time
        }
        
        // From documentation of 'CAKeyframeAnimation':
        // the first value in the array must be 0.0 and the last value must be 1.0.
        // The array should have one more entry than appears in the values array.
        // For example, if there are two values, there should be three key times.
        timesArray.append(NSNumber(value: 1.0))
        
        // Create animation
        let animation = CAKeyframeAnimation(keyPath: "contents")
        
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = CFTimeInterval(time)
        animation.repeatCount = Float.greatestFiniteMagnitude;
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.values = framesArray
        // animation.keyTimes = timesArray
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        // animation.calculationMode = kCAAnimationDiscrete
        
        return animation;
    }
}
