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
import SwiftyJSON

let exportWidth: CGFloat = 1024
let smallExportWidth: CGFloat = 512

class GenerateViewController: UIViewController {
    
    private let playerView = VideoPlayerView()
    @IBOutlet weak var videoArea: UIView!
    @IBOutlet weak var videoHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var exportLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var widthButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    
    private(set) var videoId: String?
    
    private var videoComment: VideoComment?
    private var commentsQueue: [Comment] = []
    
    private var videoMerge: VideoMerge?
    private var smallVideoMerge: VideoMerge?
    
    private var downloadRequest: Alamofire.DownloadRequest?
    private var uploadRequest: Alamofire.UploadRequest?
    
    private let exportProgress: Variable<Float> = Variable(0)
    
    private var playerDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let id = videoId {
            request(id: id)
        }
        
        widthButton.setTitle("Video Width: ~\(exportWidth)pt", for: .normal)
        widthButton.isHidden = true
    }
    
    deinit {
        playerView.clear()
        downloadRequest?.cancel()
        uploadRequest?.cancel()
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
            let exportUrl = createExportDirectory()?.appendingPathComponent(videoUrl.lastPathComponent),
            let smallExportUrl = createSmallExportDirectory()?.appendingPathComponent(videoUrl.lastPathComponent),
            FileManager.default.fileExists(atPath: exportUrl.path),
            FileManager.default.fileExists(atPath: smallExportUrl.path) {
            playExportedVideo(exportUrl)
            return
        }
        
        if let downloadedUrl = download(videoPath: videoComment.video.videoPath) {
            process(downloadedUrl)
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
        
        guard
            let exportUrl = createExportDirectory()?.appendingPathComponent(cacheVideoUrl.lastPathComponent)
            else {
            exportLabel.text = "Error. Can't find export directory"
            return
        }
        
        
        videoMerge = VideoMerge(videoUrl: cacheVideoUrl,
                                source: videoComment,
                                exportUrl: exportUrl,
                                exportWidth: exportWidth)
        
        videoMerge?.startExportVideo(onProgress: { [weak self] (progress) in
            guard let `self` = self else { return }
            self.exportLabel.text = "Exporting Big: \(progress)"
            self.progressView.progress = Float(progress)
            }, onCompletion: { [weak self] (videoData, thumbData, error) in
                guard let `self` = self else { return }
                if case let .some(.finished(url)) = self.videoMerge?.state {
                    log.info("Exported Big: \(url)")
                    self.processSmall(cacheVideoUrl)
                }
        })
    }
    
    func processSmall(_ cacheVideoUrl: URL) {
        guard let videoComment = videoComment else {
            exportLabel.text = "Error. Data empty"
            return
        }
        
        guard let smallExportUrl = createSmallExportDirectory()?.appendingPathComponent(cacheVideoUrl.lastPathComponent)
            else {
                exportLabel.text = "Error. Can't find export directory"
                return
        }
        
        smallVideoMerge = VideoMerge(videoUrl: cacheVideoUrl,
                                     source: videoComment,
                                     exportUrl: smallExportUrl,
                                     exportWidth: smallExportWidth)
        
        smallVideoMerge?.startExportVideo(onProgress: { [weak self] (progress) in
            guard let `self` = self else { return }
            self.exportLabel.text = "Exporting Small: \(progress)"
            self.progressView.progress = Float(progress)
            }, onCompletion: { [weak self] (videoData, thumbData, error) in
                guard let `self` = self else { return }
                if case let .some(.finished(url)) = self.videoMerge?.state,
                    case let .some(.finished(smallUrl)) = self.smallVideoMerge?.state,
                    let videoId = self.videoId {
                    self.playExportedVideo(url)
                    self.upload(videoId: videoId, exportUrl: url, smallExportUrl: smallUrl)
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
            let exportUrl = createExportDirectory()?.appendingPathComponent(videoUrl.lastPathComponent) {
            try? FileManager.default.removeItem(at: exportUrl)
        }
        if  let videoUrl = URL(string: videoComment.video.videoPath),
            let smallExportUrl = createSmallExportDirectory()?.appendingPathComponent(videoUrl.lastPathComponent) {
            try? FileManager.default.removeItem(at: smallExportUrl)
        }
        
        playerView.suspend()
        videoArea.removeAllSubview()
        playerDisposeBag = DisposeBag()
        
        request(id: videoComment.video.id)
    }
    
    @IBAction func saveToCamera() {
        guard
            let videoPath = videoComment?.video.videoPath,
            let videoUrl = URL(string: videoPath),
            let exportUrl = createExportDirectory()?.appendingPathComponent(videoUrl.lastPathComponent),
            let smallExportUrl = createSmallExportDirectory()?.appendingPathComponent(videoUrl.lastPathComponent),
            FileManager.default.fileExists(atPath: exportUrl.path),
            FileManager.default.fileExists(atPath: smallExportUrl.path)
            else {
                DispatchQueue.main.async {
                    self.saveButton.setTitle("Can't save..", for: .normal)
                }
                return
        }
        
        PHPhotoLibrary.shared().performChanges({
            _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportUrl)
            _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: smallExportUrl)
        }, completionHandler: { (success, error) in
            DispatchQueue.main.async {
                self.saveButton.setTitle("Saved!", for: .normal)
            }
        })
    }
    
    @IBAction func changeWidth() {
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.placeholder = "\(exportWidth)"
            textField.keyboardType = .numberPad
        })
        let confirmAction = UIAlertAction(title: "OK", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            guard let text = alertController.textFields?[0].text, let _ = Float(text) else { return }
            // exportWidth = CGFloat(number)
            self.widthButton.setTitle("Video Width: ~\(text)pt", for: .normal)
            self.reset()
        })
        alertController.addAction(confirmAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
        })
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func upload() {
        guard
            let videoComment = videoComment,
            let videoUrl = URL(string: videoComment.video.videoPath),
            let exportUrl = createExportDirectory()?.appendingPathComponent(videoUrl.lastPathComponent),
            let smallExportUrl = createSmallExportDirectory()?.appendingPathComponent(videoUrl.lastPathComponent) else {
                return
        }
        
        upload(videoId: videoComment.video.id, exportUrl: exportUrl, smallExportUrl: smallExportUrl)
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
        
        downloadRequest?.cancel()
        
        downloadRequest = Alamofire.download(loadURL, to: destination)
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
        
        downloadRequest?.resume()
    }
    
    func upload(videoId: String, exportUrl: URL, smallExportUrl: URL) {
        let uploadUrl = "https://api4.vibbidi.com/v5.0/admin/sgifs"
        // let uploadUrl = "http://v4-api.vibbidi.com:8018/v5.0/admin/sgifs"
        uploadRequest?.cancel()
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(exportUrl, withName: "file")
                multipartFormData.append(smallExportUrl, withName: "preview")
                multipartFormData.append(videoId.data(using: String.Encoding.utf8)!, withName: "id")
        },
            to: uploadUrl,
            encodingCompletion: { [weak self] encodingResult in
                guard let `self` = self else { return }
                switch encodingResult {
                case .success(let upload, _, _):
                    self.uploadRequest = upload
                    upload.uploadProgress(queue: DispatchQueue.main, closure: { [weak self] (progress) in
                        self?.exportLabel.text = "Uploading video: \(progress.fractionCompleted)..."
                        self?.progressView.progress = Float(progress.fractionCompleted)
                    })
                    
                    upload.responseJSON { [weak self] response in
                        self?.exportLabel.text = response.description
                    }
                case .failure(let encodingError):
                    self.exportLabel.text = "Error. Uploading video: \(encodingError)..."
                    log.error(encodingError)
                }
        })
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
    
    func createSmallExportDirectory() -> URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let url = documentDirectoryUrl.appendingPathComponent("Export_Small", isDirectory: true)
        
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

