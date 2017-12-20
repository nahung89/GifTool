//
//  VideoPlayerView.swift
//  GifTool
//
//  Created by Nah on 12/16/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import AVFoundation
import Foundation
import UIKit
import RxSwift

class VideoPlayerView: UIView {
    
    let progress: Variable<TimeInterval?> = Variable(nil)
    
    fileprivate let playLayer = VideoPlayerLayerView()
    fileprivate var player: AVPlayer?
    fileprivate let watermark = WatermarkView()
    
    fileprivate let loading: Variable<Bool> = Variable(false)
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var itemDisposeBag = DisposeBag()
    
    deinit {
        log.info("DEINIT!!!")
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playLayer.frame = bounds
        watermark.frame.origin = CGPoint(x: 0, y: frame.height - watermark.frame.height)
    }
    
    func initView() {
        (playLayer.layer as! AVPlayerLayer).videoGravity = AVLayerVideoGravity.resizeAspect
        addSubview(playLayer)
        
        playLayer.frame.size = CGSize(width: frame.width, height: 0)
        playLayer.clipsToBounds = true
        
        watermark.frame.origin = CGPoint(x: frame.width - watermark.frame.width, y: frame.height - watermark.frame.height)
        addSubview(watermark)
    }
    
    func setURL(_ url:URL, showMark: Bool) {
        clear()
        
        player = AVPlayer(url: url)
        
        guard let aPlayer = player, let playerItem = aPlayer.currentItem else {
            log.severe("AVPlayer isn't existed for fileUrl: \(url)")
            return
        }
        
        watermark.isHidden = !showMark
    
        aPlayer.volume = 1.0
        playLayer.setPlayer(aPlayer)
        loading.value = true
        
        aPlayer.rx.periodicTimeObserver(interval: CMTimeMake(1, 100)).subscribe(onNext: { [unowned self] time in
            self.progress.value = time.seconds
        }).disposed(by: itemDisposeBag)
        
        playerItem.rx.status.subscribe(onNext: {  [unowned self] status in
            if (status == .readyToPlay) {
                self.loading.value = false
            } else if (status == .failed) {
                log.severe("Can't play asset: \((self.player?.currentItem?.asset).logable)")
            } else {
                self.loading.value = true
            }
        }).disposed(by: itemDisposeBag)
        
        playerItem.rx.isPlaybackBufferEmpty.subscribe(onNext: { [unowned self, weak playerItem] _ in
            guard let playerItem = playerItem else { return }
            if playerItem.isPlaybackBufferEmpty {
                self.loading.value = true
            } else {
                self.loading.value = false
            }
        }).disposed(by: itemDisposeBag)
        
        NotificationCenter.default.rx
            .notification(NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
            .subscribe(onNext: { [weak self] _ in
                self?.restart()
            }).disposed(by: itemDisposeBag)
        
        aPlayer.play()
    }
    
    func clear() {
        itemDisposeBag = DisposeBag()
        player?.pause()
        player?.cancelPendingPrerolls()
        player = nil
        playLayer.removePlayer()
        progress.value = nil
    }
}

extension VideoPlayerView {
    
    func suspend() {
        guard let player = player else { return }
        player.pause()
    }
    
    func resume() {
        guard let player = player else { return }
        player.play()
    }
    
    func restart() {
        guard let player = player else { return }
        self.progress.value = nil
        player.seek(to: kCMTimeZero)
        player.play()
    }
}
