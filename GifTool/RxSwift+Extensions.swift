//
//  ReactiveExtensions.swift
//  VIBBIDI
//
//  Created by 安保元靖 on 2016/11/19.
//  Copyright © 2016年 glue-th. All rights reserved.
//  https://github.com/pmick/RxAVFoundation/blob/master/Source/AVPlayer%2BRx.swift
//  https://github.com/pmick/RxAVFoundation/blob/master/Source/AVPlayerItem%2BRx.swift

import Foundation
import UIKit
import AVFoundation
import RxSwift
import RxCocoa

extension Reactive where Base: AVPlayerItem {
    
    public var status: Observable<AVPlayerItemStatus> {
        return self.observe(AVPlayerItemStatus.self, #keyPath(AVPlayerItem.status))
            .map {
                if let s: AVPlayerItemStatus = $0 { return s }
                else { return AVPlayerItemStatus.unknown }
        }
    }
    
    public var loadedTimeRanges: Observable<[NSValue]> {
        return self.observe([NSValue].self, #keyPath(AVPlayerItem.loadedTimeRanges))
            .map {
                if let r: [NSValue] = $0 { return r }
                else { return [] }
        }
    }
    
    public var isPlaybackBufferEmpty: Observable<Bool> {
        return self.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
            .map {
                if let b: Bool = $0 { return b }
                else { return false }
        }
    }
    
    public var isPlaybackLikelyToKeepUp: Observable<Bool> {
        return self.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
            .map {
                if let b: Bool = $0 { return b }
                else { return false }
        }
    }
    
    public var isPlaybackBufferFull: Observable<Bool> {
        return self.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackBufferFull))
            .map {
                if let b: Bool = $0 { return b }
                else { return false }
        }
    }
}

extension Reactive where Base: AVPlayer {
    public var rate: Observable<Float> {
        // TODO: diposed when app goes from foreground -> background ?
        return self.observe(Float.self, #keyPath(AVPlayer.rate))
            .map {
                if let r: Float = $0 { return r }
                else { return 0 }
        }
    }
    
    public var status: Observable<AVPlayerStatus> {
        return self.observe(AVPlayerStatus.self, #keyPath(AVPlayer.status))
            .map {
                if let s: AVPlayerStatus = $0 { return s }
                else { return AVPlayerStatus.unknown }
        }
    }
    
    public var reasonForWaitingToPlay: Observable<String> {
        return self.observe(String.self, #keyPath(AVPlayer.reasonForWaitingToPlay))
            .map {
                if let r: String = $0 { return r }
                else { return "" }
        }
    }
    
    public var error: Observable<NSError?> {
        return self.observe(NSError.self, #keyPath(AVPlayer.error))
    }
    
    public func periodicTimeObserver(interval: CMTime) -> Observable<CMTime> {
        return Observable.create { observer in
            let t = self.base.addPeriodicTimeObserver(forInterval: interval, queue: nil) { time in
                observer.onNext(time)
            }
            
            return Disposables.create { self.base.removeTimeObserver(t) }
        }
    }
    
    public func boundaryTimeObserver(times: [CMTime]) -> Observable<Void> {
        return Observable.create { observer in
            let timeValues = times.map() { NSValue(time: $0) }
            let t = self.base.addBoundaryTimeObserver(forTimes: timeValues, queue: nil) {
                observer.onNext(())
            }
            
            return Disposables.create { self.base.removeTimeObserver(t) }
        }
    }
}

extension Reactive where Base: UIScrollView {
    
    /// Reactive wrapper for delegate method `scrollViewDidEndDragging(_:willDecelerate:)`
    public var willBeginDragging: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(UIScrollViewDelegate.scrollViewWillBeginDragging(_:))).map { _ in return }
        return ControlEvent(events: source)
    }
    
}

