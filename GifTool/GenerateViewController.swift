//
//  GenerateViewController.swift
//  GifTool
//
//  Created by Nah on 12/14/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import UIKit
import RxAlamofire
import RxSwift
import Unbox
import Kingfisher
import Alamofire
import AVKit

class GenerateViewController: UIViewController {
    
    @IBOutlet weak var videoArea: UIView!
    @IBOutlet weak var videoHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var exportLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    private(set) var videoId: String?
    
    private var videoComment: VideoComment?
    private var videoMerge: VideoMerge?
    private var request: Alamofire.DownloadRequest?
    
    private let exportProgress: Variable<Float> = Variable(0)
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let id = videoId {
            request(id: id)
        }
    }
    
    func set(video: Video) {
        navigationItem.title = video.title
        self.videoId = video.id
    }
    
    func reloadData() {
        guard let videoComment = videoComment else { return }
        
        guard !videoComment.comments.isEmpty else {
            exportLabel.text = "Error. Has no comment..."
            return
        }
        
        // Update video area
        videoHeightConstraint.constant = videoArea.frame.width * videoComment.video.size.height / videoComment.video.size.width
        videoArea.layoutIfNeeded()
        
        // Play comments
        for comment in videoComment.comments {
            let commentParts = CommentPart.parse(comment.content, ListSourceController.emojis)
            
            let commentView = CommentItemView(scale: 1.0)
            commentView.setCommentParts(commentParts)
            commentView.frame.origin = CGPoint(x: videoArea.frame.width, y: CGFloat(comment.row) * CommentItemView.Design.height)
            
            videoArea.addSubview(commentView)
            commentView.animate(speed: videoComment.video.commentSpeed, delay: comment.startAt)
        }
        
        download(videoPath: videoComment.video.videoPath)
    }
    
    func download(videoPath: String) {
        
        guard let loadUrl = URL(string: videoPath) else {
            exportLabel.text = "Error. Invalid Url: \(videoPath)"
            return
        }
        
        guard let saveUrl = createDownloadDirectory()?.appendingPathComponent(loadUrl.lastPathComponent) else {
            exportLabel.text = "Error. Can't find cache directory"
            return
        }
        
        if FileManager.default.fileExists(atPath: saveUrl.path) {
            process(saveUrl)
            return
        }
        
        request(loadURL: loadUrl, saveURL: saveUrl)
    }
    
    func process(_ cacheVideoUrl: URL) {
        guard let videoComment = videoComment else {
            exportLabel.text = "Error. Data empty"
            return
        }
        
        guard let exportDirectoryUrl = createExportDirectory() else {
            exportLabel.text = "Error. Can't find export directory"
            return
        }
        
        videoMerge = VideoMerge(videoUrl: cacheVideoUrl, source: videoComment, cacheDirectoryUrl: exportDirectoryUrl)
        
        let begin = Date()
        videoMerge?.startExportVideo(onProgress: { [weak self] (progress) in
            self?.exportLabel.text = "Exporting: \(progress)"
            self?.progressView.progress = Float(progress)
            }, onCompletion: { [weak self] (videoData, thumbData, error) in
                let totalTime = Date().timeIntervalSince(begin)
                self?.exportLabel.text = """
                Total time: \(totalTime)
                ---------
                video: \((videoData?.description).logable)
                thumb: \((thumbData?.description).logable)
                export: \((self?.videoMerge?.exportedUrl).logable)
                error: \(error.logable)
                """
                
                if error == nil, let url = self?.videoMerge?.exportedUrl {
                    let player = AVPlayerViewController()
                    player.player = AVPlayer(url: url)
                    self?.present(player, animated: true, completion: {
                        player.player?.play()
                    })
                }
        })
    }
}

extension GenerateViewController {
    
    func request(id: String) {
        let sourceUrl = "http://vtv-tool.vibbidi.com:3030/greeting/get/\(id)"
        log.info("Request: \(sourceUrl)")
        RxAlamofire.requestJSON(.get, sourceUrl)
            .timeout(timeOutTime, scheduler: RxScheduler.shared.apiBackground)
            .map{ (r, json) in
                do {
                    guard let dict = json as? UnboxableDictionary else { throw AppError(code: .unboxFail) }
                    let r: VideoComment = try unbox(dictionary: dict)
                    return r
                } catch {
                    throw AppError(code: .unboxFail)
                }
            }
            .observeOn(RxScheduler.shared.main)
            .subscribe(onNext: { [unowned self] (r: VideoComment) in
                self.videoComment = r
                self.reloadData()
                }, onError: { [unowned self] (error) in
                    self.displayError(error.localizedDescription)
            }).disposed(by: disposeBag)
    }
    
    func request(loadURL: URL, saveURL: URL) {
        log.info("Load: \(loadURL)")
        log.info("Save: \(saveURL)")
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (saveURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        request = Alamofire.download(loadURL, to: destination)
            .downloadProgress{ progress in
                DispatchQueue.main.async {
                    self.exportLabel.text = "Downloading video: \(progress.fractionCompleted)..."
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
            }
            .response { response in
                if let err = response.error {
                    DispatchQueue.main.async {
                        self.exportLabel.text = "Error. Download fail: \(err.localizedDescription)"
                        log.error("Error: \(err)")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.exportLabel.text = "Download Completed."
                        self.process(saveURL)
                    }
                }
        }
        
        request?.resume()
    }
}

private extension GenerateViewController {
    
    func createDownloadDirectory() -> URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let url = documentDirectoryUrl.appendingPathComponent("Download", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: url.path)
            } catch {
                log.error("Error: \(error)")
                return nil
            }
        }
        return url
    }
    
    func createExportDirectory() -> URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let url = documentDirectoryUrl.appendingPathComponent("Export", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: url.path)
            } catch {
                log.error("Error: \(error)")
                return nil
            }
        }
        return url
    }
}

