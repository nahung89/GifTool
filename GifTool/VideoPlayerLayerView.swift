//
//  VideoPlayerLayerView.swift
//  VIBBIDI
//
//  Created by 安保元靖 on 2016/11/16.
//  Copyright © 2016年 glue-th. All rights reserved.
//

import UIKit
import AVFoundation

final class VideoPlayerLayerView : UIView {
    
    override public class var layerClass: Swift.AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
    private var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    func player() -> AVPlayer? {
        return playerLayer.player
    }
    
    func setVideoGravity(_ videoGravity: AVLayerVideoGravity) {
        playerLayer.videoGravity = videoGravity
        playerLayer.removeAllAnimations()
    }
    
    func setPlayer(_ player: AVPlayer) {
        playerLayer.player = player
    }
    
    func removePlayer() {
        playerLayer.player = nil
    }
    
}

