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
            displayError("Has no comment...")
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
            // commentView.makeColor(includeSelf: true) // ERROR
            
            videoArea.addSubview(commentView)
            commentView.animate(speed: videoComment.video.commentSpeed, delay: comment.startAt)
        }
        
        // ERROR
        // download(videoPath: videoComment.video.videoPath)
        
        let videoUrl = Bundle.main.url(forResource: "test_video", withExtension: "mp4")!
        process(videoUrl)
    }
    
    func download(videoPath: String) {
        
        guard let loadUrl = URL(string: videoPath) else {
            displayError("Invalid Url: \(videoPath)")
            return
        }
        
        guard let saveUrl = getCacheDirectory()?.appendingPathComponent(loadUrl.lastPathComponent) else {
            displayError("Can't find cache directory")
            return
        }
        
        if FileManager.default.fileExists(atPath: saveUrl.path) {
            process(saveUrl)
            return
        }
        
        log.info("Load: \(loadUrl)")
        log.info("Save: \(saveUrl)")
        
        request(loadURL: loadUrl, saveURL: saveUrl)
            .subscribe(onNext: { (url) in
                log.info("Url: \(url.logable)")
            }).disposed(by: disposeBag)
    }
    
    func process(_ cacheVideoUrl: URL) {
        guard let videoComment = videoComment else {
            displayError("VideoComment empty")
            return
        }
        
        videoMerge = VideoMerge(videoUrl: cacheVideoUrl, source: videoComment, brushImage: nil)
        
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
    
    func request(loadURL: URL, saveURL: URL) -> Observable<URL?> {
        return Observable.create { observer in
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                return (saveURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            
            let request = Alamofire.download(loadURL, to: destination)
                .downloadProgress{ progress in
                    // log.debug("Progress: \(progress) - \(progress.fractionCompleted)")
                }
                .response { response in
                    if let err = response.error {
                        log.error("Error: \(err.localizedDescription)")
                        observer.onError(err)
                    } else {
                        log.info("Completed")
                        observer.onNext(response.destinationURL)
                        observer.onCompleted()
                    }
            }
            
            request.resume()
            
            return Disposables.create {
                log.warning("Cancel")
                request.cancel()
            }
        }
    }
}

private extension GenerateViewController {
    
    func getCacheDirectory() -> URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let cacheUrl = documentDirectoryUrl.appendingPathComponent("VideoCache", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: cacheUrl.path) {
            do {
                try FileManager.default.createDirectory(at: cacheUrl, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: cacheUrl.path)
            } catch {
                log.error("Error: \(error)")
                return nil
            }
        }
        return cacheUrl
    }
}
