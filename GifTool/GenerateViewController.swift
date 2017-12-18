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
import AssetsLibrary
import Photos

var exportWidth: CGFloat = 600

class GenerateViewController: UIViewController {
    
    private let playerView = VideoPlayerView()
    @IBOutlet weak var videoArea: UIView!
    @IBOutlet weak var videoHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var exportLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var widthButton: UIButton!
    
    private(set) var videoId: String?
    
    private var videoComment: VideoComment?
    private var commentsQueue: [Comment] = []
    
    private var videoMerge: VideoMerge?
    private var request: Alamofire.DownloadRequest?
    
    private let exportProgress: Variable<Float> = Variable(0)
    
    private var playerDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let id = videoId {
            request(id: id)
        }
        widthButton.setTitle("Video Width: ~\(exportWidth)pt", for: .normal)
    }
    
    deinit {
        playerView.clear()
    }
    
    func set(video: Video) {
        navigationItem.title = video.title
        self.videoId = video.id
    }
    
    func reloadData() {
        guard let videoComment = videoComment else {
            exportLabel.text = "Error. No data"
            return
        }
        
        guard !videoComment.comments.isEmpty else {
            exportLabel.text = "Error. Has no comment..."
            return
        }
        
        if  let videoUrl = URL(string: videoComment.video.videoPath),
            let exportDirectoryUrl = createExportDirectory() {
            let exportUrl = exportDirectoryUrl.appendingPathComponent(videoUrl.lastPathComponent)
            if FileManager.default.fileExists(atPath: exportUrl.path) {
                playExportedVideo(exportUrl)
                return
            }
        }
        
        if let downloadedUrl = download(videoPath: videoComment.video.videoPath) {
            playDownloadVideo(downloadedUrl)
            return
        }
    }
    
    func download(videoPath: String) -> URL? {
        
        guard let loadUrl = URL(string: videoPath) else {
            exportLabel.text = "Error. Invalid Url: \(videoPath)"
            return nil
        }
        
        guard let saveUrl = createDownloadDirectory()?.appendingPathComponent(loadUrl.lastPathComponent) else {
            exportLabel.text = "Error. Can't find cache directory"
            return nil
        }
        
        if FileManager.default.fileExists(atPath: saveUrl.path) {
            process(saveUrl)
            return saveUrl
        }
        
        request(loadURL: loadUrl, saveURL: saveUrl)
        return nil
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
        
        guard exportWidth >= 200 && exportWidth <= 2000 else  {
            exportLabel.text = "Error. Export width need to be in range 200pt to 2000pt"
            return
        }
        
        videoMerge = VideoMerge(videoUrl: cacheVideoUrl,
                                source: videoComment,
                                cacheDirectoryUrl: exportDirectoryUrl,
                                exportWidth: exportWidth)
        
        let begin = Date()
        videoMerge?.startExportVideo(onProgress: { [weak self] (progress) in
            self?.exportLabel.text = "Exporting: \(progress)"
            self?.progressView.progress = Float(progress)
            }, onCompletion: { [weak self] (videoData, thumbData, error) in
                let totalTime = Date().timeIntervalSince(begin)
                self?.exportLabel.text = """
                Total time: \(totalTime)
                ---------
                render: \((self?.videoMerge?.exportSize).logable)pt
                video: \((videoData?.sizeString(units: [.useMB], countStyle: .file)).logable)
                thumb: \((thumbData?.sizeString(units: [.useMB], countStyle: .file)).logable)
                export: \((self?.videoMerge?.exportedUrl).logable)
                error: \(error.logable)
                """
                
                if error == nil, let url = self?.videoMerge?.exportedUrl {
                    self?.saveToCamera(url)
                    self?.playExportedVideo(url)
                }
        })
    }
}

extension GenerateViewController {
    
    @IBAction func reset() {
        guard let videoComment = videoComment else {
            exportLabel.text = "Error. No data"
            return
        }
        
        guard !videoComment.comments.isEmpty else {
            exportLabel.text = "Error. Has no comment..."
            return
        }
        
        if  let videoUrl = URL(string: videoComment.video.videoPath),
            let exportDirectoryUrl = createExportDirectory() {
            let exportUrl = exportDirectoryUrl.appendingPathComponent(videoUrl.lastPathComponent)
            try? FileManager.default.removeItem(at: exportUrl)
        }
        
        playerView.suspend()
        videoArea.removeAllSubview()
        playerDisposeBag = DisposeBag()
        _ = download(videoPath: videoComment.video.videoPath)
    }
    
    @IBAction func changeWidth() {
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.placeholder = "\(exportWidth)"
            textField.keyboardType = .numberPad
        })
        let confirmAction = UIAlertAction(title: "OK", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            guard let text = alertController.textFields?[0].text, let number = Float(text) else { return }
            exportWidth = CGFloat(number)
            self.widthButton.setTitle("Video Width: ~\(text)pt", for: .normal)
            self.reset()
        })
        alertController.addAction(confirmAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
        })
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    func saveToCamera(_ exportedUrl: URL) {
        let isVideoCompatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(exportedUrl.path)
        log.info("VideoCompatible: \(isVideoCompatible)")
        
        PHPhotoLibrary.shared().performChanges({
            _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportedUrl)
        }, completionHandler: { (success, error) in
            log.info("Save Camera Roll: \(success) - error")
        })
    }
}

private extension GenerateViewController {
    
    func playExportedVideo(_ exportUrl: URL) {
        guard let videoComment = videoComment else { return }
        
        videoArea.removeAllSubview()
        
        // Update video area
        videoHeightConstraint.constant = videoArea.frame.width * videoComment.video.size.height / videoComment.video.size.width
        view.layoutIfNeeded()
        playerView.frame = videoArea.bounds
        videoArea.addSubview(playerView)
        
        playerDisposeBag = DisposeBag()
        playerView.setURL(exportUrl, showMark: false)
    }
    
    func playDownloadVideo(_ downloadUrl: URL) {
        guard let videoComment = videoComment else { return }
        
        // Update video area
        videoHeightConstraint.constant = videoArea.frame.width * videoComment.video.size.height / videoComment.video.size.width
        videoArea.layoutIfNeeded()
        playerView.frame = videoArea.bounds
        videoArea.addSubview(playerView)
        
        playerDisposeBag = DisposeBag()
        playerView.progress.asDriver().drive(onNext: { [unowned self] (progress) in
            if let time = progress {
                guard let comment = self.dequeueComment(time) else { return }
                self.show(comment: comment)
            } else {
                self.commentsQueue = videoComment.comments
                self.videoArea.removeAllSubview()
            }
        }).disposed(by: playerDisposeBag)
        
        playerView.setURL(downloadUrl, showMark: true)
    }

    func dequeueComment(_ time: TimeInterval) -> Comment? {
        for (idx, comment) in commentsQueue.enumerated() {
            if comment.startAt > time && comment.startAt < time + 0.1 {
                commentsQueue.remove(at: idx)
                return comment
            }
        }
        return nil
    }
    
    func show(comment: Comment) {
        guard let videoComment = videoComment else { return }
        
        let commentParts = CommentPart.parse(comment.content, ListSourceController.emojis)
        
        let commentView = CommentItemView(scale: 1.0)
        commentView.setCommentParts(commentParts)
        commentView.frame.origin = CGPoint(x: videoArea.frame.width, y: CGFloat(comment.renderRow) * CommentItemView.Design.height)
        
        videoArea.addSubview(commentView)
        commentView.animate(speed: videoComment.video.commentSpeed, delay: 0)
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

