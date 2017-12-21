//
//  VideoMerge.swift
//  VideoMerge
//
//  Created by NAH on 2/11/17.
//  Copyright © 2017 NAH. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

typealias VideoExportProgressBlock = (Float) -> Void
typealias VideoExportCompletionBlock = (Data?, Data?, Error?) -> Void

enum ExportError: Error {
    case invalidAsset, emptyVideo, noSession
}

class VideoMerge {
    
    enum State {
        case none, merging, finished(URL), failed(Error?)
    }
    
    private(set) var state: State = .none
    
    private var videoUrl: URL
    private var source: VideoComment
    private let kExportWidth: CGFloat // round width to multiply of 16
    private var overlayViews: [UIView] = []
    
    private var exportUrl: URL
    private var exportSession: AVAssetExportSession?
    
    private var progressBlock: VideoExportProgressBlock?
    private var completionBlock: VideoExportCompletionBlock?
    
    private let kDisplayWidth: CGFloat = UIScreen.main.bounds.width
    // private let kExportWidth: CGFloat = 600
    private let kNumberOfLines: CGFloat = 5
    
    var exportSize: CGSize? {
        return exportSession?.videoComposition?.renderSize
    }
    
    init(videoUrl: URL, source: VideoComment, exportUrl: URL, exportWidth: CGFloat) {
        self.videoUrl = videoUrl
        self.source = source
        self.exportUrl = exportUrl
        self.kExportWidth = exportWidth
    }
    
    deinit {
        log.info("DEINIT!!!")
    }
    
    func startExportVideo(onProgress progressBlock: VideoExportProgressBlock? = nil, onCompletion completionBlock: VideoExportCompletionBlock? = nil) {
        
        self.progressBlock = progressBlock
        self.completionBlock = completionBlock
        
        switch state {
        case .none: processExportVideo()
        case .merging: break
        case let .finished(url): finishExport(url, error: nil)
        case let .failed(error): finishExport(nil, error: error)
        }
    }
    
    func stopExportVideo() {
        exportSession?.cancelExport()
        exportSession = nil
        state = .none
        overlayViews.removeAll()
    }
}

// MARK: - Actions

extension VideoMerge {
    
    private func processExportVideo() {
        do {
            let export = try createExportSession()
            exportSession = export
            handleExportSession(export)
        } catch let error {
            state = .none
            finishExport(nil, error: error)
        }
    }
    
    private func handleExportSession(_ export: AVAssetExportSession) {
        state = .merging
        DispatchQueue.global().async { [weak self, weak export] in
            export?.exportAsynchronously() {
                DispatchQueue.main.async {
                    guard let `self` = self, let export = export else { return }
                    switch export.status {
                    case .completed, .unknown:
                        if let url = export.outputURL, FileManager.default.fileExists(atPath: url.path) {
                            self.state = .finished(url)
                            self.finishExport(url, error: nil)
                        } else {
                            self.state = .failed(export.error)
                            self.finishExport(nil, error: export.error)
                        }
                        self.exportSession = nil
                        
                    case .failed, .cancelled:
                        self.exportSession = nil
                        self.state = .failed(export.error)
                        self.finishExport(nil, error: export.error)
                        
                    case .exporting, .waiting:
                        break
                    }
                }
            }
            
            while export?.status == .waiting || export?.status == .exporting {
                DispatchQueue.main.async {
                    guard let `self` = self, let export = export else { return }
                    self.progressBlock?(export.progress)
                }
            }
        }
    }
    
    private func finishExport(_ url: URL?, error: Error?) {
        guard let url = url else {
            completionBlock?(nil, nil, error)
            return
        }
        
        do {
            let videoData = try Data(contentsOf: url)
            let imageData = try createPreviewDataFrom(videoUrl: url)
            completionBlock?(videoData, imageData, nil)
        } catch let error {
            completionBlock?(nil, nil, error)
        }
    }
}

// MARK: - Ultilities

private extension VideoMerge {
    
    private func createExportSession() throws -> AVAssetExportSession {
        // Get asset from videos
        let asset: AVAsset = AVAsset(url: videoUrl)
        
        guard CMTimeGetSeconds(asset.duration) > 0 else {
            throw ExportError.invalidAsset
        }
        
        // Create input AVMutableComposition, hold our video AVMutableCompositionTrack list.
        let inputComposition = AVMutableComposition()
        
        // Add video into input composition
        guard let videoCompositionTrack = addVideo(from: asset, to: inputComposition) else {
            throw ExportError.emptyVideo
        }
        
        // Add audio into input composition
        _ = addAudio(from: asset, to: inputComposition)
        
        // Add video layer instructions
        let outputVideoInstruction = createVideoLayerInstruction(asset: asset, videoCompositionTrack: videoCompositionTrack)
        
        // Output composition instruction
        let start = CMTimeMakeWithSeconds(0, asset.duration.timescale)
        let duration = CMTimeMakeWithSeconds(source.video.end - source.video.start, asset.duration.timescale)
        let range = CMTimeRangeMake(start, duration)
        let outputCompositionInstruction = AVMutableVideoCompositionInstruction()
        outputCompositionInstruction.timeRange = range
        outputCompositionInstruction.layerInstructions = [outputVideoInstruction]
        
        let naturalSize = videoCompositionTrack.naturalSize
        let scale: CGFloat = kExportWidth / naturalSize.width
        let exportSize = CGSize(width: ceil(naturalSize.width * scale / 16) * 16,
                                height:ceil(naturalSize.height * scale / 16) * 16)
        
        // Output video composition
        let outputComposition = AVMutableVideoComposition()
        outputComposition.instructions = [outputCompositionInstruction]
        outputComposition.frameDuration = CMTimeMake(1, Int32(videoCompositionTrack.nominalFrameRate))
        outputComposition.renderSize = exportSize
        
        // Add effects
        addEffect(to: outputComposition)
        
        // Create export session from input video & output instruction
        guard let exportSession = AVAssetExportSession(asset: inputComposition, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.noSession
        }
        
        try? FileManager.default.removeItem(at: exportUrl)
        
        exportSession.videoComposition = outputComposition
        exportSession.outputFileType = AVFileType.mp4
        exportSession.outputURL = exportUrl
        exportSession.shouldOptimizeForNetworkUse = true
        return exportSession
    }
}

// MARK: - Compose Configurations

private extension VideoMerge {
    
    func addVideo(from asset: AVAsset, to inputComposition: AVMutableComposition) -> AVMutableCompositionTrack? {
        // Important: only add track if has video type & insert succesfully, or must remove it out of composition.
        // Otherwise export session always fail with error code -11820
        guard let assetTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            return nil
        }
        
        guard let compositionTrack = inputComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            return nil
        }
        
        do {
            let start = CMTimeMakeWithSeconds(source.video.start, asset.duration.timescale)
            let duration = CMTimeMakeWithSeconds(source.video.end - source.video.start, asset.duration.timescale)
            let range = CMTimeRangeMake(start, duration)
            try compositionTrack.insertTimeRange(range, of: assetTrack, at: kCMTimeZero)
        } catch {
            inputComposition.removeTrack(compositionTrack)
            return nil
        }
        
        return compositionTrack
    }
    
    func addAudio(from asset: AVAsset, to inputComposition: AVMutableComposition) -> AVMutableCompositionTrack? {
        // Important: only add track if has audio type & insert succesfully, or must remove it out of composition.
        // Otherwise export session always fail with error code -11820
        guard let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
            return nil
        }
        
        guard let compositionTrack = inputComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            return nil
        }
        
        do {
            let start = CMTimeMakeWithSeconds(source.video.start, asset.duration.timescale)
            let duration = CMTimeMakeWithSeconds(source.video.end - source.video.start, asset.duration.timescale)
            let range = CMTimeRangeMake(start, duration)
            try compositionTrack.insertTimeRange(range, of: assetTrack, at: kCMTimeZero)
        } catch {
            inputComposition.removeTrack(compositionTrack)
            return nil
        }
        
        return compositionTrack
    }
    
    private func createVideoLayerInstruction(asset: AVAsset, videoCompositionTrack: AVCompositionTrack) -> AVMutableVideoCompositionLayerInstruction {
        let totalVideoTime = CMTimeAdd(kCMTimeZero, asset.duration)
        let naturalSize = videoCompositionTrack.naturalSize
        
        let tmpScale: CGFloat = kExportWidth / naturalSize.width
        let exportSize = CGSize(width: ceil(naturalSize.width * tmpScale / 16) * 16,
                                height:ceil(naturalSize.height * tmpScale / 16) * 16)
        
        let transform = videoCompositionTrack.preferredTransform.scaledBy(x: exportSize.width / naturalSize.width,
                                                                          y: exportSize.height / naturalSize.height)
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        instruction.setTransform(transform, at: kCMTimeZero)
        instruction.setOpacity(0.0, at: totalVideoTime)
        return instruction
    }
    
    private func addEffect(to outputComposition: AVMutableVideoComposition) {
        let videoFrame = CGRect(origin: CGPoint.zero, size: outputComposition.renderSize)
        
        // Text layer container
        let overlayLayer = CALayer()
        overlayLayer.frame = videoFrame
        overlayLayer.masksToBounds = true
        
        // let composeHeight = videoFrame.height * kDisplayWidth / videoFrame.width
        let scale: CGFloat = videoFrame.width / kDisplayWidth
        
        let watermark = WatermarkView(scale: scale)
        watermark.frame.origin = CGPoint(x: 0, y: 0)
        overlayLayer.addSublayer(watermark.layer)
        overlayViews.append(watermark) // *Very importance: To store instance, otherwise it can't render
        
        let lineHeight = (videoFrame.height - watermark.frame.height) / kNumberOfLines
        
        let texts = source.comments
        
        for index in stride(from: 0, to: texts.count, by: 1) {
            let comment: Comment = texts[index]
            
            let commentParts = CommentPart.parse(comment.content, ListSourceController.emojis)
            let commentView = CommentItemView(scale: scale)
            commentView.setCommentParts(commentParts)
            
            commentView.frame.origin.x = videoFrame.maxX
            // commentView.frame.origin.y = videoFrame.height - videoFrame.height * comment.yPosition / composeHeight - commentView.bounds.height
            commentView.frame.size.height = lineHeight
            commentView.frame.origin.y = videoFrame.height - CGFloat(comment.renderRow) * lineHeight - commentView.bounds.height
            
            let moveAnimation =  CABasicAnimation(keyPath: "position.x")
            moveAnimation.byValue = -(videoFrame.width + commentView.bounds.width)
            moveAnimation.beginTime = comment.startAt != 0 ? comment.startAt : 0.001 // ERROR that can't show comment at 0.0 ???
            moveAnimation.duration = commentView.duration(speed: source.video.commentSpeed, videoWidth: videoFrame.width)
            moveAnimation.isRemovedOnCompletion = false
            moveAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            moveAnimation.fillMode = kCAFillModeForwards
            
            commentView.layer.add(moveAnimation, forKey: "move")
            
            // Add sub layer and store view
            overlayLayer.addSublayer(commentView.layer)
            overlayViews.append(commentView) // *Very importance: Must store instance, otherwise it can't render
        }
        
        let parentLayer = CALayer()
        parentLayer.frame = videoFrame
        
        let videoLayer = CALayer()
        videoLayer.frame = videoFrame
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        outputComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
}

private extension VideoMerge {
    
    func createPreviewDataFrom(videoUrl: URL) throws -> Data? {
        let asset = AVAsset(url: videoUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero
        
        var time = asset.duration
        time.value = min(asset.duration.value, 1)
        
        let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        let image = UIImage(cgImage: imageRef)
        return UIImageJPEGRepresentation(image, 0.95)
    }
}




